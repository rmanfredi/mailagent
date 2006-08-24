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
echo "Extracting agent/files/help/password (with variable substitutions)"
$spitshell >/dev/null <<!GROK!THIS!
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
# $Log: password.SH,v $
# Revision 3.0  1993/11/29  13:47:57  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >password <<'!NO!SUBS!'
NAME

	password -- Sets new power password

SYNOPSIS

	password power new

DESCRIPTION

This command sets a new power password. You usually need the corresponding
power or have the 'system' power, hence showing you know the password for
that power or have greater privileges.

To change the 'root' and 'security' passwords, you need the corresponding
power.

EXAMPLE

	password list-power mypass
!NO!SUBS!
chmod 644 password
