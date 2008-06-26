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
echo "Extracting agent/edusers (with variable substitutions)"
$spitshell >edusers <<!GROK!THIS!
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
# $Log: edusers.SH,v $
# Revision 3.0.1.3  1995/08/07  16:06:24  ram
# patch37: added support for locking on filesystems with short filenames
#
# Revision 3.0.1.2  1995/03/21  12:50:11  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.1  1994/09/22  13:39:28  ram
# patch12: created
#

\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';
\$revision = '$revision';
\$defeditor = '$defeditor';
\$phostname = '$phostname';
\$long_filenames = '$d_flexfnam' eq 'define';
!GROK!THIS!
$spitshell >>edusers <<'!NO!SUBS!'

$userlist = "users";
$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name
$lockext = $long_filenames ? '.lock' : '!';	# Extension used by lock routines
*add_log = *stderr_log;			# Ensure logs will go to stderr also

$EDITOR = $ENV{'EDITOR'} || $ENV{'VISUAL'} || $defeditor;

&read_config;		# First, read configuration file (in ~/.mailagent)
&read_dist;			# Read distributions
&catch_signals;

$system = shift;		# Which system do we want
$version = shift;		# Which version it is

# If no system is specified, try locating a '.package', then source it
# to get information...
if ($system eq '') {
	die "$prog_name: you must specify a system name\n" unless &read_package;
	$system = $pkg'package;
	$version = $pkg'baserev;
}

# A single '-' or a missing version means "highest available" version.
$version = $Version{$system} if $version eq '-' || $version eq '';

# Full name of system for H table access
$pname = $system . "|" . $version;

die "$prog_name: no program called $system\n" unless $System{$system};
die "$prog_name: no package $system version $version\n"
	unless $Program{$pname};

# Go to the system directory.
chdir "$Location{$pname}" ||
	die "$prog_name: cannot go to $Location{$pname}\n";

-f $userlist || die "$prog_name: no $userlist file yet for $system $version.\n";

# Lock users file. That file should only be edited with the edusers script.
die "$prog_name: cannot lock $userlist.\n" if 0 != &acs_rqst($userlist);

system "$EDITOR $userlist";
warn "$prog_name: WARNING: edition failed...\n" if $?;
&free_file($userlist);

exit $?;

!NO!SUBS!
$grep -v '^;#' pl/fatal.pl >>edusers
$grep -v '^;#' pl/add_log.pl >>edusers
$grep -v '^;#' pl/read_conf.pl >>edusers
$grep -v '^;#' pl/distribs.pl >>edusers
$grep -v '^;#' pl/secure.pl >>edusers
$grep -v '^;#' pl/cdir.pl >>edusers
$grep -v '^;#' pl/acs_rqst.pl >>edusers
$grep -v '^;#' pl/free_file.pl >>edusers
$grep -v '^;#' pl/checklock.pl >>edusers
$grep -v '^;#' pl/signals.pl >>edusers
$grep -v '^;#' pl/package.pl >>edusers
$grep -v '^;#' pl/hostname.pl >>edusers
chmod 755 edusers
$eunicefix edusers
