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
echo "Extracting agent/files/help/delpower (with variable substitutions)"
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
# $Log: delpower.SH,v $
# Revision 3.0  1993/11/29  13:47:55  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >delpower <<'!NO!SUBS!'
NAME

	delpower -- Deletes a power from the system

SYNOPSIS

	delpower power password [security]

DESCRIPTION

This command deletes a power and its associated clearance list. The 'system'
power is required to delete all powers but 'root' and 'security'.

The 'security' power may only be deleted by security and the 'root' power may
only be deleted when the security password is also specified.

EXAMPLE

	delpower list list-password
!NO!SUBS!
chmod 644 delpower
