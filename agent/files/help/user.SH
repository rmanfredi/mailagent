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
echo "Extracting agent/files/help/user (with variable substitutions)"
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
# $Log: user.SH,v $
# Revision 3.0  1993/11/29  13:48:01  ram
# Baseline for mailagent 3.0 netwide release.
#
!GROK!THIS!
$spitshell >user <<'!NO!SUBS!'
NAME

	user -- Runs a command on behalf of another user

SYNOPSIS

	user [name [command]]

DESCRIPTION

This command may be used to execute some other commands on behalf of a user.

If a command is specified, it is immediately executed under the new identity
(which is merely an e-mail address), and that new identity only lasts for
that single command. Otherwise, the remaining commands are executed with the
new identity.

If no user name is specified, the original sender identity is restored.

All the powers are lost when the 'user' command is executed, but this is
only temporary when a command is specified on the same line.

Note that it is up to the command to make use of this "effective" user
identity, by looking at the proper environment variables.

EXAMPLES

	user root@acri.fr
	... some commands ...
	user
	user ram@acri.fr subscribe agent-users
!NO!SUBS!
chmod 644 user
