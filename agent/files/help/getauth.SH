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
echo "Extracting agent/files/help/getauth (with variable substitutions)"
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
# $Log: getauth.SH,v $
# Revision 3.0  1993/11/29  13:47:56  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >getauth <<'!NO!SUBS!'
NAME

	getauth -- Gets power clearance file

SYNOPSIS

	getauth power [password]

DESCRIPTION

This command requests the power clearance file for the specified power. The
power password is optional if the power is already detained or the user has
already got the 'system' power.

To get the 'root' or 'security' clearances, you need the corresponding
power.

EXAMPLE

	getauth list-power mypasswd
!NO!SUBS!
chmod 644 getauth
