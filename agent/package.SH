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
echo "Extracting agent/package (with variable substitutions)"
$spitshell >package <<!GROK!THIS!
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
#  Original Author: Graham Stoney, 1993
#
# $Log: package.SH,v $
# Revision 3.0.1.9  1997/01/07  18:30:34  ram
# patch52: the "no change" optimization was overzealous
#
# Revision 3.0.1.8  1996/12/26  10:46:55  ram
# patch51: added undocumented 'badaddress' request for PATBOUNCE
#
# Revision 3.0.1.7  1996/12/24  14:44:44  ram
# patch45: added command forwarding support
#
# Revision 3.0.1.6  1995/08/07  16:15:18  ram
# patch37: added support for locking on filesystems with short filenames
# patch37: forgot to define phostname, needed for NFS-secure locks
#
# Revision 3.0.1.5  1995/03/21  12:56:20  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.4  1994/10/29  17:44:27  ram
# patch20: notifications now sent to the user, not the return address
#
# Revision 3.0.1.3  1994/10/10  10:23:49  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.2  1994/10/04  17:42:11  ram
# patch17: now uses the email config parameter to send messages to user
# patch17: extended logging to get better error/failure tracking
#
# Revision 3.0.1.1  1994/09/22  14:03:44  ram
# patch12: added fuzzy address matching to avoid duplicates
# patch12: detect hostile addresses before it is too late...
# patch12: detect strange status-change requests
# patch12: now performs locking before changing the users file
# patch12: inform user about unrecognized leave-alone requests
# patch12: optimize by not re-writing users file if not needed
#
# Revision 3.0  1993/11/29  13:48:32  ram
# Baseline for mailagent 3.0 netwide release.
#
# 

\$cat = '$cat';
\$zcat = '$zcat';
\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
\$phostname = '$phostname';
\$long_filenames = '$d_flexfnam' eq 'define';
!GROK!THIS!
$spitshell >>package <<'!NO!SUBS!'

$userlist = "users";
$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name
$lockext = $long_filenames ? '.lock' : '!';	# Extension used by lock routines

&read_config;		# First, read configuration file (in ~/.mailagent)
&catch_signals;		# Protect against signals

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
$theirpl = shift;		# which patchlevel they've got
$request = shift;		# what would they like to ask for

# A single '-' as first argument stands for return path
$dest = $path if $dest eq '-';

# A single '-' for version means "highest available" version.
$version = $Version{$system} if $version eq '-';

# Convert empty pl to a dash
$theirpl = '-' if $theirpl eq '';

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
X-Mailer: mailagent [version $mversion PL$patchlevel]

I have not heard of a program called $system.  Sorry.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot mail back error") if $loglvl;
	} else {
		&add_log("MSG unknown system $system") if $loglvl > 8;
	}
	&add_log("FAILED (UNKNOWN SYSTEM)") if $loglvl > 1;
	exit 0;
}

if (!$Program{$pname}) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: No package $system version $version
X-Mailer: mailagent [version $mversion PL$patchlevel]

I don't know anything about version $version of $system.  Sorry.";
	if ($Version{$system} ne '') {
		print MAILER "

[The highest version for $system is $Version{$system}.]";
		&add_log("MSG highest version is $Version{$system}")
			if $loglvl > 8;
	} else {
		print MAILER "

[There is no version number for $system.]";
		&add_log("MSG no version number") if $loglvl > 8;
	}
	print MAILER "

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot mail back error") if $loglvl;
	} else {
		&add_log("MSG bad $system version number") if $loglvl > 8;
	}
	&add_log("FAILED (BAD SYSTEM NUMBER)") if $loglvl > 1;
	exit 0;
}

# If the request is not for the most recent version, warn the user and abort.
if ($version < $Version{$system}) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: Version $version of $system is out-of-date
X-Mailer: mailagent [version $mversion PL$patchlevel]

This short note to warn you that $system version $version is not the
lattest one available. If you have some interest in $system, I suggest
you upgrade by fetching version $Version{$system} as soon as possible.

$maillist

I did not record you as a $system user since your version is not the
one currently maintained.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot inform newer version exists") if $loglvl;
	} else {
		&add_log("MSG old version $system $version") if $loglvl > 8;
	}
	exit 0;
}

if (!($Maintained{$pname} || $Patches{$pname})) {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: $system version $version is not maintained
X-Mailer: mailagent [version $mversion PL$patchlevel]

I can't keep you up to date on changes to version $version of $system, because
this code is not maintained by $cf'name.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot mail back error") if $loglvl;
	} else {
		&add_log("MSG $system is not maintained") if $loglvl > 8;
	}
	&add_log("FAILED (NOT MAINTAINED)") if $loglvl > 1;
	exit 0;
}

# decode their request into a status letter.
# they may be asking to be left alone.
if ((($theirpl eq '-') && $request eq '') ||
	$request eq 'leavealone')		{ $leavealone = 1; $letter = 'L'; }
elsif ($request eq '')			{ $letter = 'U'; }	# just a user
elsif ($request eq 'mailpatches')	{ $letter = 'M'; }	# want patches
elsif ($request eq 'notifypatches')	{ $letter = 'N'; }	# notify only
elsif ($request eq 'badaddress')	{ $leavealone = 1; $letter = 'B'; }
else {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: I didn't understand your package command
X-Mailer: mailagent [version $mversion PL$patchlevel]

Your package command requested `$request', and I don't know what that means.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot mail back error") if $loglvl;
	} else {
		&add_log("MSG bad request $request") if $loglvl > 8;
	}
	&add_log("FAILED (BAD REQUEST)") if $loglvl > 1;
	exit 0;
}

# Go to the package root directory and check for possible forwarding...
chdir($Location{$pname}) || &abort("cannot chdir to $Location{$pname}: $!");
&check_forward;			# Returns only if command is not forwarded

open(PATCHLEVEL, "patchlevel.h") || &abort("cannot open patchlevel.h");
$maxnum = 0;
while (<PATCHLEVEL>) {
	if (/.*PATCHLEVEL[ \t]*(\d+)/) {
		$maxnum = $1;
		last;
	}
}
close PATCHLEVEL;

# if they have Configured a patchlevel which is not the latest, let them know.
if (!$leavealone && $theirpl ne '-' && $maxnum ne $theirpl) {
	$upgrade = $theirpl + 1;

	# In fact, if they've asked for patch mailing, send it directly. This
	# works because our environment, set up by mailagent, will be propagated
	# to the mailpatch command as-is.
	if ($letter eq 'M') {
		system('mailpatch', $dest, $system, $version, "$upgrade-");
		if ($? == 0) {
			&add_log("MAILED missing patches for $system $version to $dest")
				if $loglvl > 6;
		} else {
			&add_log("WARNING unable to mail patches for $system $version")
				if $loglvl > 1;
		}
	} else {
		# Send the following to $dest (address given to the package command),
		# not $path (return address) since it is legitimate for them to differ
		# and the following is not an error message but something concerning
		# the address we're recording. Likewise, the above mailpatch command
		# sends patches to $dest.
		open(MAILER, "|$cf'sendmail $cf'mailopt $dest $cf'email") || &nofork;
		print MAILER
"To: $dest
Subject: The latest patchlevel for $system version $version is $maxnum
X-Mailer: mailagent [version $mversion PL$patchlevel]

Just a quick note to let you know that the latest patchlevel for $system
version $version is $maxnum; if you are still at patchlevel $theirpl, I strongly
suggest you upgrade by applying the more recent patches.

You can fetch these automatically by sending me the following mail:

	Subject: Command
	\@SH mailpatch $dest $system $version $upgrade-
		   ^ note the c

-- $prog_name speaking for $cf'user
";
		close MAILER;
		if ($?) {
			&add_log("ERROR cannot inform $system is now $version PL$maxnum")
				if $loglvl;
		} else {
			&add_log("MSG latest version is $system $version PL$maxnum")
				if $loglvl > 8;
		}
	}
}

# Lock users file. That file should only be edited with the edusers script.
if (0 != &acs_rqst($userlist)) {
	&add_log("WARNING updating $userlist without lock") if $loglvl > 5;
}

# look for them in the userlist file
if (open(USERLIST, $userlist)) {
	while (<USERLIST>) {
		next if /^#/;
		chop if /\n$/;
		($status, $pl, $name) = split;

		# convert oldstyle user file format (dist 3.0 PL13).
		unless (defined $name) {
			$name = $pl;	# Shift left
			$pl = '-';
		}

		# have we heard from them before?
		if (&addr'match($name, $dest)) {
			if ($found++) {
				&add_log("WARNING removing duplicate for $dest ($name)")
					if $loglvl > 5;
				&add_log("NOTICE status for $dest was $oldstatus, now $status")
					if $oldstatus ne $status && $loglvl > 6;
				next;
			}

			$oldstatus = $status;	# Save status
			$oldpl = $pl;			# And patchlevel
			$status = $letter;
			$pl = $theirpl if $theirpl ne '-';
		}

		# save entry
		push(@status, $status);
		push(@pl, $pl);
		push(@name, $name);

		# in case we have to go to &send_closest
		push(@registered, $name) if $status =~ /^[MN]/;
	}
	close USERLIST;
}

# optimize a little...
if (
	$found == 1 && $oldstatus eq $letter &&
	($theirpl eq '-' || $oldpl eq $theirpl)
) {
	&add_log("NOTICE no change for $dest") if $loglvl > 6;
	close USERLIST;
	&free_file($userlist);
	exit 0;
}

# add them if they're new.
if (!$found) {
	if ($letter eq 'L') {
		&add_log("WARNING unknown $dest wants to be left alone") if $loglvl > 5;
		&free_file($userlist);
		&send_closest;
		&add_log("FAILED (UNREGISTERED $dest)") if $loglvl > 1;
		exit 0;
	} elsif ($letter eq 'B') {
		&add_log("WARNING unknown $dest bounced back") if $loglvl > 5;
		&free_file($userlist);
		&add_log("FAILED (BAD BOUNCE ADDRESS $dest)") if $loglvl > 1;
		exit 0;
	} else {
		push(@name, $dest);
		push(@status, $letter);
		push(@pl, $theirpl);
	}
}

# write the file back out.
open(USERLIST,">$userlist.new") ||
	&abort("can't create new $userlist file: $!");

for ($i = 0; $i <= $#name; $i++) {
	print USERLIST $status[$i], "\t", $pl[$i], "\t", $name[$i], "\n"
		|| &abort("error writing new $userlist file");
}
close(USERLIST) || &abort("error closing new $userlist file");

rename("$userlist.new", $userlist);
&free_file($userlist);

# Emergency exit with clean-up
sub abort {
	local($reason) = shift(@_);		# Why we are exiting
	&free_file($userlist);
	&fatal($reason);
}

# Send closest matching addresses, among @registered
sub send_closest {
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAILER
"To: $path
Subject: You were not recorded as a $system $version user
X-Mailer: mailagent [version $mversion PL$patchlevel]

I can't honour your desire to be left alone for $system version $version
updates because you were not found among the registered users.

Your command was: $fullcmd

For your information, here is the list of the closest addresses to your own
e-mail address ($dest) that are registered:

";
	local($first) = '';
	foreach $addr (@registered) {
		if (&addr'close($dest, $addr)) {
			print MAILER "\t$addr\n";
			$first = $addr if $first eq '';
		}
	}
	print MAILER <<EOM if $first ne '';

Assuming you registered using the address $first,
you may request to be left alone by sending me the following:

	Subject: Command
	\@SH package $first $system $version

This is only an example, of course. You must pick the correct address
among the listed set.

If none of the addresses listed above are correct, please don't try them.
EOM
	print MAILER <<EOM if $first eq '';
	*** None found ***

This probably means you either never registered, or you used an entirely
different e-mail address to do so.

EOM
	print MAILER <<EOM;
I suggest you re-run the Configure script from the original $system
distribution and ask to be left alone from there. If you kept the generated
config.sh and run Configure on the same machine you did the first time, that
should un-register you properly.

-- $prog_name speaking for $cf'user
EOM
	close MAILER;
	if ($?) {
		&add_log("ERROR cannot send closest addr list") if $loglvl;
	} else {
		&add_log("MSG closest addr list") if $loglvl > 6;
	}
}

# Report error while forking a sendmail process
sub nofork {
	&add_log("SYSERR fork: $!") if $loglvl;
	&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
}

!NO!SUBS!
$grep -v '^;#' pl/fatal.pl >>package
$grep -v '^;#' pl/add_log.pl >>package
$grep -v '^;#' pl/read_conf.pl >>package
$grep -v '^;#' pl/distribs.pl >>package
$grep -v '^;#' pl/secure.pl >>package
$grep -v '^;#' pl/cdir.pl >>package
$grep -v '^;#' pl/addr.pl >>package
$grep -v '^;#' pl/acs_rqst.pl >>package
$grep -v '^;#' pl/free_file.pl >>package
$grep -v '^;#' pl/checklock.pl >>package
$grep -v '^;#' pl/signals.pl >>package
$grep -v '^;#' pl/hostname.pl >>package
$grep -v '^;#' pl/forward.pl >>package
chmod 755 package
$eunicefix package
