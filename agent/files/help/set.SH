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
echo "Extracting agent/files/help/set (with variable substitutions)"
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
# $Log: set.SH,v $
# Revision 3.0.1.1  1998/03/31  14:34:47  ram
# patch59: without parameters, list all the defined variables
#
# Revision 3.0  1993/11/29  13:47:59  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >set <<'!NO!SUBS!'
NAME

	set -- Sets a command environment variable

SYNOPSIS

	set variable value

DESCRIPTION

This command sets the variable to the specified value. Flags are only
set to 'true' or 'false', although 'on', 'yes' and an empty value are
also recognized to be 'true', anything else being 'false'.

A 'set' all by itself will list all the defined variables along with
their values.

EXAMPLES

	set eof END_OF_FILE
	set trace on
	set
!NO!SUBS!
chmod 644 set
