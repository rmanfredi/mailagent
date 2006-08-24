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
echo "Extracting agent/files/help/remauth (with variable substitutions)"
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
# $Log: remauth.SH,v $
# Revision 3.0  1993/11/29  13:47:59  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >remauth <<'!NO!SUBS!'
NAME

	remauth -- Removes users from power clearance file

SYNOPSIS

	remauth name [password]
	... list of users ...
	EOF

DESCRIPTION

This command removes specified users from the power's clearance file. No
special power is required when the target power is already detained. Otherwise
the 'system' power is needed.

As usual, 'root' and 'security' clearances require the corresponding power to
be held or the appropriate password.

Only users matching exactly the addresses listed in the clearance file will
be removed.

EXAMPLE

	remauth list list-password
	root@acri.fr
	EOF
!NO!SUBS!
chmod 644 remauth
