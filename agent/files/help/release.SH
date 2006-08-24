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
echo "Extracting agent/files/help/release (with variable substitutions)"
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
# $Log: release.SH,v $
# Revision 3.0.1.1  1998/03/31  14:34:06  ram
# patch59: fixed typos
#
# Revision 3.0  1993/11/29  13:47:58  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >release <<'!NO!SUBS!'
NAME

	release -- Releases power

SYNOPSIS

	release name

DESCRIPTION

This command releases the specified power.

If the 'root' power is released, other powers obtained while root or before
are kept. That way, it makes sense to ask for powers while root, when the
password for some minor power has been changed, since you do not need to
supply it. Then 'root' may be released and the work continued with the
minor power handy.

It is not recommend to run an entire session with 'root' privileges, unless
needed to bypass some restrictions like the maximum number of commands that
may be issued in a session.

EXAMPLE

	release list
!NO!SUBS!
chmod 644 release
