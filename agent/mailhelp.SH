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
echo "Extracting agent/mailhelp (with variable substitutions)"
$spitshell >mailhelp <<!GROK!THIS!
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
# $Log: mailhelp.SH,v $
# Revision 3.0.1.3  1996/12/24  14:07:01  ram
# patch45: silently discard hostile addresses
#
# Revision 3.0.1.2  1995/03/21  12:55:04  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.1  1994/10/04  17:36:31  ram
# patch17: extended logging to get better error/failure tracking
#
# Revision 3.0  1993/11/29  13:48:23  ram
# Baseline for mailagent 3.0 netwide release.
#

\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
\$revision = '$revision';
!GROK!THIS!

$spitshell >>mailhelp <<'!NO!SUBS!'

$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name

&read_config;		# First, read configuration file (in ~/.mailagent)

# take job number and command from environment
# (passed by mailagent)
$jobnum = $ENV{'jobnum'};
$fullcmd = $ENV{'fullcmd'};

$dest=shift;							# Who should the help be sent to
$dest = $ENV{'path'} if $dest eq '';	# If dest was omitted

# A single '-' as first argument stands for return path
$dest = $ENV{'path'} if $dest eq '-';

# Silently discard hostile addresses
unless (&addr'valid($dest)) {
	&add_log("FAILED (HOSTILE $dest)") if $loglvl > 1;
	exit 0;
}

open(HELP, "$cf'spool/agenthelp") || &fatal("no help file!\n");
open(MAILER, "|$cf'sendmail $cf'mailopt $dest") || &nofork;
print MAILER
"To: $dest
Subject: How to use my mail agent
X-Mailer: mailagent [version $mversion-$revision]

";
while (<HELP>) {
	# Replace some tokens by parameters
	s/=DEST=/$dest/g;
	s/=MAXSIZE=/$cf'maxsize/g;
	print MAILER;
}
print MAILER
"
-- $prog_name speaking for $cf'user
";
close MAILER;
if ($?) {
	&add_log("ERROR couldn't send help to $dest") if $loglvl > 0;
} else {
	&add_log("SENT help to $dest") if $loglvl > 2;
}
close HELP;

# Report error while forking a sendmail process
sub nofork {
	&add_log("SYSERR fork: $!") if $loglvl;
	&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
}

!NO!SUBS!
$grep -v '^;#' pl/fatal.pl >>mailhelp
$grep -v '^;#' pl/add_log.pl >>mailhelp
$grep -v '^;#' pl/read_conf.pl >>mailhelp
$grep -v '^;#' pl/secure.pl >>mailhelp
$grep -v '^;#' pl/cdir.pl >>mailhelp
$grep -v '^;#' pl/addr.pl >>mailhelp
chmod 755 mailhelp
$eunicefix mailhelp
