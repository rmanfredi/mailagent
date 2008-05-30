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
echo "Extracting agent/mailpatch (with variable substitutions)"
$spitshell >mailpatch <<!GROK!THIS!
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
# $Log: mailpatch.SH,v $
# Revision 3.0.1.5  1996/12/24  14:08:29  ram
# patch45: silently discard hostile addresses
# patch45: added command forwarding support
#
# Revision 3.0.1.4  1995/03/21  12:55:16  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.3  1994/10/10  10:22:57  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.2  1994/10/04  17:38:37  ram
# patch17: suppressed usage of Bcc in messages: user is on the command line
# patch17: no longer hardwires mailpatch name but uses prog_name variable
# patch17: now uses the email config parameter to send messages to user
# patch17: extended logging to get better error/failure tracking
#
# Revision 3.0.1.1  1994/04/25  15:12:06  ram
# patch7: removed incorrect sanity check for zcat (void when portable)
#
# Revision 3.0  1993/11/29  13:48:25  ram
# Baseline for mailagent 3.0 netwide release.
#

\$cat = '$cat';
\$zcat = '$zcat';
\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
\$revision = '$REVISION';
!GROK!THIS!
$spitshell >>mailpatch <<'!NO!SUBS!'

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

$dest = shift;			# Who should the patches be sent to
$system = shift;		# Which system do patches belong
$version = shift;		# Which version it is

# A single '-' as first argument stands for return path
$dest = $path if $dest eq '-';

# A single '-' for version means "highest available" version.
$version = $Version{$system} if $version eq '-';

# Full name of system for H table access
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
X-Mailer: mailagent [version $mversion-$revision]

I don't know how to send patches for a program called $system.  Sorry.

$maillist

If $cf'name can figure out what you meant, you'll get the patches anyway.

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
Subject: No patches for $system version $version
X-Mailer: mailagent [version $mversion-$revision]

I don't know how to send patches for version $version of $system.  Sorry.";
	if ($Version{$system} ne '') {
		print MAILER "

[The highest version for $system is $Version{$system}.]";
		&add_log("MSG highest version is $Version{$system}") if $loglvl > 8;
	} else {
		print MAILER "

[There is no version number for $system.]";
		&add_log("MSG no version number") if $loglvl > 8;
	}
	print MAILER "

$maillist

If $cf'name can figure out what you meant, you'll get the patches anyway.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report no patches for $system $version")
			if $loglvl;
	} else {
		&add_log("MSG no patched for $system $version") if $loglvl > 6;
	}
    &add_log("FAILED (BAD SYSTEM NUMBER)") if $loglvl > 1;
    exit 0;
}

if (!($Maintained{$pname} || $Patches{$pname})) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: $system version $version is not maintained
X-Mailer: mailagent [version $mversion-$revision]

I can't send you patches for version $version of $system, because this code
is not maintained by $cf'name. There are no official patches available either...

$maillist

Anyway, if you discover a bug or have remarks about \"$system\", please
let me know. Better, if you know where patches for $system can be found,
well... you have my e-mail address ! :->

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report $system $version is not maintained")
			if $loglvl;
	} else {
		&add_log("MSG $system $version is not maintained") if $loglvl > 6;
	}
    &add_log("FAILED (NOT MAINTAINED)") if $loglvl > 1;
    exit 0;
}

# Create a temporary directory
$tmp = "$cf'tmpdir/dmp$$";
mkdir($tmp, 0700) || &fatal("cannot create $tmp");

# Need to unarchive the distribution
if ($Archived{$pname}) {
	# Create a temporary directory for distribution
	$tmp_loc = "$cf'tmpdir/dmpl$$";
	mkdir($tmp_loc, 0700) || &fatal("cannot create $tmp_loc");
	$Location{$pname} =
		&unpack($Location{$pname}, $tmp_loc, $Compressed{$pname});
}

# Go to the package root directory and check for possible forwarding...
chdir($Location{$pname}) || &abort("cannot chdir to $Location{$pname}: $!");
&check_forward;			# Returns only if command is not forwarded

# Go to bugs sub-directory. It is possible to ask for patches for
# old systems. Such systems are identified by having the `patches'
# field from the distrib file set to "old". In that case, patches
# are taken from a bugs-version directory. Version has to be non null.

if ($Patch_only{$pname}) {
	&abort("old system has no version number") if $version eq '';
	chdir "bugs-$version" ||
		&abort("cannot go to $Location{$pname}/bugs-$version: $!");
	# There is no patchlevel to look at -- compute by hand.
	for ($maxnum = 1; ; $maxnum++) {
		last unless -f "patch$maxnum" || -f "patch$maxnum.Z";
	}
	$maxnum--;		# We've gone too far
} else {
	chdir "bugs" || &abort("cannot go to $Location{$pname}/bugs: $!");
	open(PATCHLEVEL, "../patchlevel.h") ||
		&abort("cannot open patchlevel.h");
	$maxnum = 0;
	while (<PATCHLEVEL>) {
		if (/.*PATCHLEVEL[ \t]*(\d+)/) {
			$maxnum = $1;
			last;
		}
	}
	close PATCHLEVEL;
}

if (!$maxnum) {
	# If we get here, it must be for one of our systems. Indeed,
	# if we do not have any patches for a third party program, there
	# should be a "no" in the patches field of distribution file, and
	# in that case an error would have been reported before.
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: No patches yet for $system version $version
X-Mailer: mailagent [version $mversion-$revision]

There are no patches (yet) for $system version $version. Sorry.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report no patches yet for $system $version")
			if $loglvl;
	} else {
		&add_log("MSG no patches yet for $system $version") if $loglvl > 6;
	}
    &add_log("FAILED (NO PATCHES YET)") if $loglvl > 1;
	&clean_tmp;
    exit 0;
}

$patchlist = &rangeargs($maxnum, @ARGV);	# Generate patch list

if (! ($patchlist =~ /\d/)) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: Invalid patch request for $system $version
X-Mailer: mailagent [version $mversion-$revision]
";
	if ($Patches{$pname}) {
		print MAILER "
The highest patch I have for $system version $version is #$maxnum.";
	} else {
		print MAILER "
The latest patch for $system version $version is #$maxnum.";
	}
	print MAILER "
(Your command was: $fullcmd)";
	if ($Version{$system} > $version) {
		print MAILER "

Please note that the latest version for $system is $Version{$system}.

$maillist";
	}
	print MAILER "

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot report latest $system is $version PL$maxnum")
			if $loglvl;
	} else {
		&add_log("MSG latest $system is $version PL$maxnum") if $loglvl > 6;
	}
    &add_log("FAILED (INVALID PATCH LIST)") if $loglvl > 1;
	&clean_tmp;
    exit 0;
}

@numbers = split(/ /,$patchlist);

foreach $num (@numbers) {
	$patchfile = "patch" . $num;	# Base name of the patch
	if (-f $patchfile) {			# Normal patch
		$append = $cat;
		$extent = '';
	} elsif (-f "$patchfile.Z") {	# Compressed patch
		$append = $zcat;
		$extent = '.Z';
	} else {
		&add_log("ERROR no patch #$num ($system)") if $loglvl > 1;
		next;
	}
	open (TMP, ">$tmp/$patchfile");
	if ($Patches{$pname}) {
		print TMP "
This is an official patch for $system version $version, please apply it.
The highest patch I have for that version of $system is #$maxnum.";
	} else {
		print TMP "
The latest patch for $system version $version is #$maxnum.";
	}
	print TMP "

-- $prog_name speaking for $cf'user
";
	close TMP;
	system "$append <$patchfile$extent >>$tmp/$patchfile";
	if ($? && $loglvl > 1) {
		&add_log("ERROR can't uncompress patch #$num ($system)")
			if $append eq $zcat;
		&add_log("ERROR can't copy patch #$num ($system)")
			if $append eq $cat;
		next;
	}
	&add_log("copied file $patchfile into $tmp") if $loglvl > 17;
}

if ($#numbers > 0) {
	$subject = $#numbers + 1;		# Array count starts at 0
	$subject = "$system $version, $subject patches";
} else {
	$subject = "$system $version patch #$numbers[0]";
}
&sendfile($dest, $tmp, $pack, $subject);
&clean_tmp;

exit 0;		# Ok

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
$grep -v '^;#' pl/fatal.pl >>mailpatch
$grep -v '^;#' pl/add_log.pl >>mailpatch
$grep -v '^;#' pl/read_conf.pl >>mailpatch
$grep -v '^;#' pl/unpack.pl >>mailpatch
$grep -v '^;#' pl/rangeargs.pl >>mailpatch
$grep -v '^;#' pl/sendfile.pl >>mailpatch
$grep -v '^;#' pl/distribs.pl >>mailpatch
$grep -v '^;#' pl/secure.pl >>mailpatch
$grep -v '^;#' pl/cdir.pl >>mailpatch
$grep -v '^;#' pl/addr.pl >>mailpatch
$grep -v '^;#' pl/forward.pl >>mailpatch
chmod 755 mailpatch
$eunicefix mailpatch
