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
echo "Extracting agent/files/help/approve (with variable substitutions)"
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
# $Log: approve.SH,v $
# Revision 3.0  1993/11/29  13:47:54  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >approve <<'!NO!SUBS!'
NAME

	approve -- Approves command in advance by specifying a password

SYNOPSIS

	approve password command

DESCRIPTION

This command records the specified password in the environment and then
launches the command given as argument.

It is entirely up to the command to check the approve variable when it
otherwise expects a password, otherwise this command has no visible
effect.

It is not currently possible to approve a command which collects input.

EXAMPLE

	approve list-password subscribe agent-users ram@acri.fr
!NO!SUBS!
chmod 644 approve
