case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
*)
	TOP=..;;
esac
revision=`awk '/^#define[ 	]*REVISION/ {print $3}' < $TOP/revision.h`
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting agent/maillist (with variable substitutions)"
$spitshell >maillist <<!GROK!THIS!
$startperl
	eval 'exec perl -S \$0 \${1+"\$@"}'
		if \$running_under_some_shell;

# $Id$
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: maillist.SH,v $
# Revision 3.0.1.6  1996/12/24  14:07:48  ram
# patch45: silently discard hostile addresses
# patch45: knows about command forwarding
#
# Revision 3.0.1.5  1995/08/07  16:12:48  ram
# patch37: forgot to define phostname, needed for NFS-secure locks
#
# Revision 3.0.1.4  1995/03/21  12:55:09  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.3  1995/02/16  14:27:01  ram
# patch32: forgot to include pl/hostname.pl for NFS-secure locks
#
# Revision 3.0.1.2  1994/10/10  10:22:54  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.1  1994/10/04  17:36:37  ram
# patch17: extended logging to get better error/failure tracking
#
# Revision 3.0  1993/11/29  13:48:24  ram
# Baseline for mailagent 3.0 netwide release.
#

\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
\$revision = '$revision';
\$phostname = '$phostname';
!GROK!THIS!

$spitshell >>maillist <<'!NO!SUBS!'

$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name

&read_config;		# First, read configuration file (in ~/.mailagent)

# take job number and command from environment
# (passed by mailagent)
$jobnum = $ENV{'jobnum'};
$fullcmd = $ENV{'fullcmd'};

$dest=shift;							# Who should the list to be sent to
$dest = $ENV{'path'} if $dest eq '';	# If dest was omitted

# A single '-' as first argument stands for return path
$dest = $ENV{'path'} if $dest eq '-';

# Silently discard hostile addresses
unless (&addr'valid($dest)) {
	&add_log("FAILED (HOSTILE $dest)") if $loglvl > 1;
	exit 0;
}

&read_dist;			# Read distributions and descriptions

open(INFO, "$cf'proglist") ||
	&fatal("cannot open description file");
@sysinfo = <INFO>;
close INFO;

&read_plsave;		# Read patchlevel description file
		
$tmp_mail = "$cf'tmpdir/xml$$";

open(XHEAD, ">$tmp_mail") || &fatal("cannot create $tmp_mail");
print XHEAD
"To: $dest
Subject: List of available distributions
X-Mailer: mailagent [version $mversion-$revision]

Here are the different packages available. If you want the whole
distribution, send me the following:

	\@SH maildist $dest system version

If you want patches, use:

	\@SH mailpatch $dest system version LIST

where LIST is a list of patches number, separated by spaces, commas,
and/or hyphens. Saying 23- means everything from 23 to the end.

Detailed instructions can be obtained by:

	\@SH mailhelp $dest


";

foreach $pname (keys %Program) {
	($system, $version) = $pname =~ /^([\w-]+)\|([\w\.]+)*$/;
	$version = '---' if $version eq '0';
	$location = $Location{$pname};
	&add_log("dealing with $system $version") if $loglvl > 19;
	$forwarded = '';	# Set to forwarded addresses when .forward found...

	# Look for highest patchlevel (even if not maintained)
	$tmp = "";			# Temporary directory created

	if ($Archived{$pname}) {
		unless ($PSystem{$pname}) {
			# Archive not already listed in 'plsave'. Create a new
			# entry with a modification time of zero.
			$PSystem{$pname} = 1;
			$Patch_level{$pname} = -1;	# Not a valid patch level
			$Mtime{$pname} = 0;			# Force unpacking of archive
		}

		# We need to unarchive the directory only if archive
		# modification time is newer than the one in patchlist
		local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime, $mtime,
			$ctime,$blksize,$blocks) = stat(&expand($location));

		if ($mtime != $Mtime{$pname}) {	 # Archive was updated
			$Mtime{$pname} = $mtime;	 # Update mod time in 'plsave'
			# Create a temporary directory
			$tmp = "$cf'tmpdir/dml$$";
			mkdir($tmp, 0700) ||
				&fatal("cannot create $tmp");
			# Need to unarchive the distribution
			$location = &unpack($location, $tmp, $Compressed{$pname});
			$Patch_level{$pname} = -1;	# Force updating
		} else {
			&add_log("no changes in $system $version archive")
				if $loglvl > 15;
		}

	} else {
		# System is not archived
		$Patch_level{$pname} = -1;		# Force computation
	}

	if ($Patch_level{$pname} == -1) {
		# We still don't know wether there is a patchlevel or not...
		# Go to system directory, and look there.
		if (!chdir("$location")) {
			&add_log("ERROR cannot go to $location") if $loglvl;
			next;
		}
		if ($Patch_only{$pname}) {		# Only patches available
			if ($version eq '') {
				&add_log("ERROR old system $system has no version number")
					if $loglvl;
				next;
			}
			if (!chdir("bugs-$version")) {
				&add_log("ERROR no bugs-$version dir for $system")
					if $loglvl;
				next;
			}
			local($maxnum);
			# There is no patchlevel to look at -- compute by hand.
			for ($maxnum = 1; ; $maxnum++) {
				last unless -f "patch$maxnum" || -f "patch$maxnum.Z";
			}
			$maxnum--;		# We've gone too far
			$Patch_level{$pname} = $maxnum;
		} elsif (! -f 'patchlevel.h') {
			&add_log("no patchlevel.h for $system $version") if $loglvl > 17;
		} elsif (!open(PATCHLEVEL, "patchlevel.h")) {
			&add_log("cannot open patchlevel.h for $system $version")
				if $loglvl > 5;
		} else {
			while (<PATCHLEVEL>) {
				if (/.*PATCHLEVEL[ \t]*([\w-]+)/) {	# May have letters
					$Patch_level{$pname} = $1;
					last;
				}
			}
			close PATCHLEVEL;
			if ($Patch_level{$pname} == -1) {
				&add_log("malformed patchlevel.h for $system $version")
					if $loglvl > 5;
			}
		}
	}

	if ($Patch_level{$pname} >= 0) {
		&add_log("patchlevel is #$Patch_level{$pname} for $system $version")
			if $loglvl > 18;
	} else {
		$Patch_level{$pname} = -2;		# Signals: no patchlevel
		&add_log("no patchlevel for $system $version") if $loglvl > 18;
	}

	# If a .forward file is present, maintenance activity is now remotely
	# handled, and all command mails like mailpath and maildist will be
	# forwarded according to that file.
	if (-f '.forward') {
		$forwarded = join(", ", &forward_list);
	}
	
	&clean_dir;			 # Remove tmp directory, if necessary

	# Now look for a description of the package...
	$describe = "";
	$found = 0;
	foreach (@sysinfo) {
		next if /^\s*#/;	# Skip comments
		next if /^\s*$/;	# Skip blank lines
		next if /^\*\s+$system/ && ($found = 1);
		last if $found && /^---|^\*/;		# Reached end of description
		$describe .= "X" . $_ if $found;
	}
	$* = 1;
	$describe =~ s/^X/\t/g;		# Indent description
	$* = 0;

	print XHEAD "System: $system";
	print XHEAD " version $version" if $version !~ /---/;
	print XHEAD "\nStatus: ";
	print XHEAD $Maintained{$pname} ? "maintained" : "not maintained";
	print XHEAD " (patches only)" if $Patch_only{$pname};
	print XHEAD " (official patches available)" if $Patches{$pname};
	print XHEAD "\n";
	if ($forwarded) {
		print XHEAD $Maintained{$pname} ? "Maintained-by: " : "Contact: ";
		print XHEAD "$forwarded\n";
	}
	if ($Maintained{$pname}) {
		if ($Patch_level{$pname} > 0) {
			print XHEAD "Highest patch: #$Patch_level{$pname}\n";
		} else {
			print XHEAD "No patches yet\n";
		}
	} else {
		print XHEAD "Patch level: #$Patch_level{$pname}\n"
			if $Patch_level{$pname} > 0;
	}
	print XHEAD "\n";
	print XHEAD "$describe\n" if $describe ne '';
	print XHEAD "\n";
}
print XHEAD "-- $prog_name speaking for $cf'user\n";
close XHEAD;

open(XHEAD, "$tmp_mail") || &fatal("cannot open mail file");
open(MAILER, "|$cf'sendmail $cf'mailopt $dest") || &nofork;
while (<XHEAD>) {
	print MAILER;
}
close MAILER;
if ($?) {
	&add_log("ERROR couldn't send list to $dest") if $loglvl > 0;
} else {
	&add_log("SENT list to $dest") if $loglvl > 2;
}
close XHEAD;

&write_plsave;			# Write new patchlist file
&clean_tmp;				# Remove temporary dirs/files
exit 0;					# All OK

sub clean_dir {
	chdir $cf'home;		# Leave [to be removed directory] first
	if ($tmp ne '') {
		system '/bin/rm', '-rf', $tmp if -d "$tmp";
		&add_log("directory $tmp removed") if $loglvl > 19;
		$tmp = "";
	}
}

sub clean_tmp {
	&clean_dir;
	unlink "$tmp_mail" if -f "$tmp_mail";
}

# Report error while forking a sendmail process
sub nofork {
	&add_log("SYSERR fork: $!") if $loglvl;
	&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
}

!NO!SUBS!
$grep -v '^;#' pl/fatal.pl >>maillist
$grep -v '^;#' pl/acs_rqst.pl >>maillist
$grep -v '^;#' pl/free_file.pl >>maillist
$grep -v '^;#' pl/add_log.pl >>maillist
$grep -v '^;#' pl/read_conf.pl >>maillist
$grep -v '^;#' pl/unpack.pl >>maillist
$grep -v '^;#' pl/distribs.pl >>maillist
$grep -v '^;#' pl/checklock.pl >>maillist
$grep -v '^;#' pl/plsave.pl >>maillist
$grep -v '^;#' pl/secure.pl >>maillist
$grep -v '^;#' pl/cdir.pl >>maillist
$grep -v '^;#' pl/hostname.pl >>maillist
$grep -v '^;#' pl/addr.pl >>maillist
$grep -v '^;#' pl/forward.pl >>maillist
chmod 755 maillist
$eunicefix maillist
