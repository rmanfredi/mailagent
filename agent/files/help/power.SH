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
echo "Extracting agent/files/help/power (with variable substitutions)"
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
# $Log: power.SH,v $
# Revision 3.0  1993/11/29  13:47:58  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >power <<'!NO!SUBS!'
NAME

	power -- Asks for a new power

SYNOPSIS

	power name password

DESCRIPTION

This command requests for a new power. You must give the proper password and
be listed in the clearance file in order to get it. Moreover, the server
processing your commands must be in trusted mode to grant you the power,
even if your credentials are otherwise perfectly valid.

Any power is granted automatically to 'root', except 'security' of course
which must be requested for separately.

It is recommended you release a power when you don't need it any longer,
to guard against mistakes.

EXAMPLE

	power list list-passwd
!NO!SUBS!
chmod 644 power
