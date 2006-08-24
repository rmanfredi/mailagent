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
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting agent/maildist (with variable substitutions)"
$spitshell >maildist <<!GROK!THIS!
$startperl
	eval "exec perl -S \$0 \$*"
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
# $Log: maildist.SH,v $
# Revision 3.0.1.5  1996/12/24  14:06:44  ram
# patch45: silently discard hostile addresses
# patch45: added command forwarding support
#
# Revision 3.0.1.4  1995/03/21  12:54:59  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.3  1994/10/10  10:22:47  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.2  1994/10/04  17:36:03  ram
# patch17: now uses the email config parameter to send messages to user
# patch17: extended logging to get better error/failure tracking
#
# Revision 3.0.1.1  1993/12/17  08:12:18  ram
# patch4: a regular expression got corrupted by an appliance of itself
#
# Revision 3.0  1993/11/29  13:48:23  ram
# Baseline for mailagent 3.0 netwide release.
#

\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
!GROK!THIS!

$spitshell >>maildist <<'!NO!SUBS!'

$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name

&read_config;		# First, read configuration file (in ~/.mailagent)

# take job number and command from environment
# (passed by mailagent)
$jobnum = $ENV{'jobnum'};
$fullcmd = $ENV{'fullcmd'};
$pack = $ENV{'pack'};
$path = $ENV{'path'};

&read_dist;			# Read distributions

$dest = shift;		# Who should the system be sent to
$system = shift;	# Which system
$version = shift;	# Which version it is

# A single '-' as first argument stands for return path
$dest = $path if $dest eq '-';

# A single '-' for version means "highest available" version
$version = $Version{$system} if $version eq '-' || $version eq '';

# Full program's name for H table access
$pname = $system . "|" . $version;

$maillist = "To obtain a list of what is available, send me the following mail:

	Subject: Command
	\@SH maillist $path
		^ note the l";

# Silently discard hostile addresses
unless (&addr'valid($dest)) {
	&add_log("FAILED (HOSTILE $dest)") if $loglvl > 1;
	exit 0;
}

if (!$System{$system}) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: No program called $system
X-Mailer: mailagent [version $mversion PL$patchlevel]

I don't know how to send a program called \"$system\".  Sorry.

$maillist

If $cf'name can figure out what you meant, you'll get the program anyway.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report system $system is unknown") if $loglvl;
	} else {
		&add_log("MSG system $system is unknown") if $loglvl > 6;
	}
    &add_log("FAILED (UNKNOWN SYSTEM)") if $loglvl > 1;
    exit 0;
}

if (!$Program{$pname}) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: No version $version for $system
X-Mailer: mailagent [version $mversion PL$patchlevel]

I don't know how to send version $version of $system.  Sorry.

$maillist

If $cf'name can figure out what you meant, you'll get the program anyway.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report system $system $version is unknown")
			if $loglvl;
	} else {
		&add_log("MSG system $system version $version is unknown")
			if $loglvl > 6;
	}
    &add_log("FAILED (BAD VERSION NUMBER)") if $loglvl > 1;
    exit 0;
}

# Has the user made a request for an old version (patch only) ?
if ($Patch_only{$pname}) {
	# It is required that patch only systems have a version number
	&abort("old system has no version number") if $version eq '';
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: System $system $version is obsolete
X-Mailer: mailagent [version $mversion PL$patchlevel]

I can't send you version $version of $system. Sorry.

This version appears to be an old one, and only patches are available.
The up-to-date version for $system is $Version{$system}.

$maillist

If $cf'name can figure out what you meant, he may send you the latest version.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report system $system $version is obsolete")
			if $loglvl;
	} else {
		&add_log("MSG system $system $version is obsolete") if $loglvl > 6;
	}
    &add_log("FAILED (PATCH ONLY VERSION)") if $loglvl > 1;
    exit 0;
}

# If the request is not the most recent version, warn the user.
if ($version < $Version{$system}) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: Version $version of $system is an old one
X-Mailer: mailagent [version $mversion PL$patchlevel]

You asked for version $version of $system.

This version appears to be an old one, but it is sill available, and
I am currently processing your request. However, I wanted to let you
know that the up-to-date version for $system is $Version{$system}.

$maillist

Unless you receive an error message telling you otherwise, I am sending
you version $version of $system. You may also request for the new version
right now if you wish.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report $system $version is old") if $loglvl;
	} else {
		&add_log("MSG system $system $version is old") if $loglvl > 6;
	}
}

# Create a temporary directory
$tmp = "$cf'tmpdir/dmd$$";
mkdir($tmp, 0700);

# Need to unarchive the distribution
if ($Archived{$pname}) {
	# Create a temporary directory for distribution
	$tmp_loc = "$cf'tmpdir/dmdl$$";
	mkdir($tmp_loc, 0700);
	$location =
		&unpack($Location{$pname}, $tmp_loc, $Compressed{$pname});
} else {
	$location = $Location{$pname};
}

# Go to the package root directory and check for possible forwarding...
chdir($location) || &abort("cannot chdir to $location: $!");
&check_forward;			# Returns only if command is not forwarded

# We are now in the place. Look for a MANIFEST file. If none, we will
# send *everything* held, RCS sub-directories and executable/object files
# excepted.

$manifest = '';
$tmp_list = '';

if (-f 'MANIFEST') {
	$manifest = "$location/MANIFEST";
} else {
	$tmp_list = "$cf'tmpdir/mdlist$$";
	open(FIND, "find . -type f -print | sort |") ||
		&abort("cannot run find");
	open(LIST, ">$tmp_list") ||
		&abort("cannot create $tmp_list");
	while (<FIND>) {
		chop;
		s|\./||;
		next if (m|^U/| && -f '.package');	# Skip units if meta-configured
		next if m|^RCS/|;			# Skip RCS files
		next if m|/RCS/|;
		next if m|,v$|;
		next if m|bugs/|;			# Skip bugs files (patches and al.)
		next if m|^\.#|;			# Skip [marked for deletion] files
		next if m|/\.#|;
		next if m|\.o$|;			# Skip object files
		next if m|core$|;			# Skip core files
		next if (-x $_ && -B $_);	# Skip binaries
		print LIST $_,"\n";			# Keep that file
	}
	close FIND;
	close LIST;
	$manifest = $tmp_list;
}

&add_log("manifest is in $manifest") if $loglvl > 19;

# If distribution is maintained by dist 3.0 (at least), there is a .package
# file in there and we can invoke makedist. Otherwise, we have to do it by
# hand...

if (-f '.package') {
	system "makedist -c $tmp -f $manifest";
	&abort("cannot run makedist -c $tmp") if $?;
} else {
	&makedist;
}

$subject = "$system";
$subject .= " $version" if $version ne '0';
$subject .= " package";
&sendfile($dest, $tmp, $pack, $subject);
&clean_tmp;

exit 0;		# Ok

# Now for each file in manifest, look if there is an
# RCS file associated with it. If so, check out either
# the 'lastpat' version or the highest version on the
# default branch, provided that the file does not exists
# in checked-out form. Otherwise, only run co if 'lastpat'
# is defined.
sub makedist {
	chdir $tmp || &abort("cannot chdir to $tmp");
	open(MANI, $manifest) || &abort("cannot open $manifest");
	while (<MANI>) {
		next if /^--/;
		s|^\s*||;						# Remove leading spaces
		($file,$foo) = split;			# Save filename, discard comments
		next if (-d "$location/$file");	# Skip directories
		next if ($file =~ /^\s*$/);		# Skip blank lines
		# Extract dirname and basename
		($dir, $base) = ('', $file)
			unless ($dir, $base) = ($file =~ m|(.*/)(.*)|);
		$logmsg = '';				# String to add to log message
		$rcsfile = 'blurfl';
		$rcsfile = "$location/$file,v" if (-f "$location/$file,v");
		$rcsfile = "$location/${dir}RCS/$base,v"
			if (-f "$location/${dir}RCS/$base,v");
		next unless -f "$location/$file" || -f "$rcsfile";	# Skip unexisting files
		&makedir($dir) unless $dir eq '';
		open(COPY, ">$file") || &abort("cannot create $file");
		if ($rcsfile ne '') {
			$rlog = `rlog $rcsfile 2>&1`;
			($revs) = ($rlog =~ /lastpat: (\d+)/);
			if (!$revs) {
				# Symbol 'lastpat' is not defined
				# If file exists, open it. Otherwise, run co
				if (-f "$location/$file") {
					$logmsg = " (lastpat undefined)";
					$origfile = "$location/$file";
					open(FILE, $origfile) ||
						&abort("cannot open $origfile");
				} else {
					$logmsg = " (co but no lastpat)";
					$origfile = $rcsfile;
					open(FILE, "co -q -p $rcsfile |") ||
						&abort("cannot run co on $rcsfile");
				}
			} else {
				# Symbol 'lastpat' is defined
				$logmsg = " (co lastpat)";
				$origfile = $rcsfile;
				open(FILE, "co -q -p -rlastpat $rcsfile |") ||
					&abort("cannot run co on $rcsfile");
			}
		} else {
			$origfile = "$location/$file";
			open(FILE, "$location/$file") ||
				&abort("cannot open $location/$file");
		}
		while (<FILE>) {
			# Use Lock[e]r, not Locker, since we might apply this on
			# ourself one day and get corrupted...
			s|Lock[e]r:.*\$|\$|;      # Remove locker mark
			(print COPY) || &abort("copy error: $!");
		}
		close(FILE) || &abort("copy error: $!");
		close COPY;
		&add_log("copied $file$logmsg") if $loglvl > 19;

		# If file is executable, change its permissions
		if (-x $origfile) {
			chmod 0755, $file;
		} else {
			chmod 0644, $file;
		}
	}
}

sub clean_tmp {
	# Do not stay in the directories we are removing...
	chdir $cf'home;
	if ($tmp ne '') {
		system '/bin/rm', '-rf', $tmp;
		&add_log("removed dir $tmp") if $loglvl > 19;
	}
	if ($Archived{$pname}) {
		system '/bin/rm', '-rf', $tmp_loc;
		&add_log("removed dir $tmp_loc") if $loglvl > 19;
	}
	unlink $tmp_list if $tmp_list ne '';
}

# Emergency exit with clean-up
sub abort {
	local($reason) = shift(@_);		# Why we are exiting
	&clean_tmp;
	&fatal($reason);
}

# Report error while forking a sendmail process
sub nofork {
	&add_log("SYSERR fork: $!") if $loglvl;
	&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
}

!NO!SUBS!
$grep -v '^;#' pl/makedir.pl >>maildist
$grep -v '^;#' pl/fatal.pl >>maildist
$grep -v '^;#' pl/add_log.pl >>maildist
$grep -v '^;#' pl/read_conf.pl >>maildist
$grep -v '^;#' pl/unpack.pl >>maildist
$grep -v '^;#' pl/sendfile.pl >>maildist
$grep -v '^;#' pl/distribs.pl >>maildist
$grep -v '^;#' pl/secure.pl >>maildist
$grep -v '^;#' pl/cdir.pl >>maildist
$grep -v '^;#' pl/addr.pl >>maildist
$grep -v '^;#' pl/forward.pl >>maildist
chmod 755 maildist
$eunicefix maildist
