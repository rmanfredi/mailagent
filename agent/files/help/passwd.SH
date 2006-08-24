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
echo "Extracting agent/files/help/passwd (with variable substitutions)"
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
# $Log: passwd.SH,v $
# Revision 3.0  1993/11/29  13:47:57  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >passwd <<'!NO!SUBS!'
NAME

	passwd -- Changes power password

SYNOPSIS

	passwd power old new

DESCRIPTION

This command changes a power password from 'old' to 'new'. Since you have to
give the old password, there is no power requirements.

EXAMPLE

	passwd list-power oldpass newpass
!NO!SUBS!
chmod 644 passwd
