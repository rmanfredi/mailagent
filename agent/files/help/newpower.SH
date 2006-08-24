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
echo "Extracting agent/files/help/newpower (with variable substitutions)"
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
# $Log: newpower.SH,v $
# Revision 3.0  1993/11/29  13:47:57  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >newpower <<'!NO!SUBS!'
NAME

	newpower -- Adds a new power to the system

SYNOPSIS

	newpower power password [alias]
	... users ...
	EOF

DESCRIPTION

This command creates a new server power and assigns a password to protect it.
If the power name is longer than 12 characters, you may specify an alias for
that power, which will be used internally by mailagent to reference it, or
leave the field blank and mailagent will generate one for you.

The 'system' power is normally required to create a new power. The 'security'
power is required to create the root power and the 'root' power is needed to
create 'security'. In order to bootstrap either power, please refer to the
mailagent manual page where this is explained in detail.

EXAMPLE

	newpower list-power mypasswd
	ram@acri.fr
	ram@eiffel.com
	EOF
!NO!SUBS!
chmod 644 newpower
