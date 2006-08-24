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
echo "Extracting agent/files/help/addauth (with variable substitutions)"
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
# $Log: addauth.SH,v $
# Revision 3.0  1993/11/29  13:47:54  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >addauth <<'!NO!SUBS!'
NAME

	addauth -- Adds users to power clearance file

SYNOPSIS

	addauth power [password]
	... users ...
	EOF

DESCRIPTION

This command adds the specified users to the specified power. The power
password is optional if the power is already detained or the user has
already got the 'system' power.

To alter 'root' and 'security' clearances, the corresponding power is needed.

EXAMPLE

	addauth list-power mypasswd
	ram@acri.fr
	ram@eiffel.com
	EOF
!NO!SUBS!
chmod 644 addauth
