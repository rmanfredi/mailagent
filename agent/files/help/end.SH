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
echo "Extracting agent/files/help/end (with variable substitutions)"
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
# $Log: end.SH,v $
# Revision 3.0  1993/11/29  13:47:55  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >end <<'!NO!SUBS!'
NAME

	end -- Ends a server request

SYNOPSIS

	end

DESCRIPTION

This pseudo command simply ends the processing of your request. The remaining
of your message is discarded.

Usually, a server request is also ended when a signature delimiter "--" is
reached or at the physical end of the message.

EXAMPLE

	... some commands ...
	end
	... mail message continues (ignored) ...
!NO!SUBS!
chmod 644 end
