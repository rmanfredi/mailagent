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
echo "Extracting agent/man/edusers.$manext (with variable substitutions)"
$rm -f edusers.$manext
$spitshell >edusers.$manext <<!GROK!THIS!
.TH EDUSERS $manext
''' @(#) Manual page for mailagent's edusers command
'''
''' $Id$
'''
'''  Copyright (c) 1990-2006, Raphael Manfredi
'''  
'''  You may redistribute only under the terms of the Artistic License,
'''  as specified in the README file that comes with the distribution.
'''  You may reuse parts of this distribution only within the terms of
'''  that same Artistic License; a copy of which may be found at the root
'''  of the source tree for mailagent 3.0.
'''
''' $Log: edusers.SH,v $
''' Revision 3.0.1.5  1999/07/12  13:44:10  ram
''' patch66: updated my e-mail address
'''
''' Revision 3.0.1.4  1996/12/24  14:08:52  ram
''' patch45: examples are now shown in constant-width font if possible
'''
''' Revision 3.0.1.3  1995/08/07  16:13:00  ram
''' patch37: updated my e-mail address
'''
''' Revision 3.0.1.2  1994/10/04  17:39:34  ram
''' patch17: changed the .TH line to point at the command's name
'''
''' Revision 3.0.1.1  1994/09/22  13:53:06  ram
''' patch12: created
'''
''' 
.de Ex		\" Start of Example
.sp
.in +5
.ft CW
.nf
..
.de Ef		\" End of Example
.sp
.in -5
.ft R
.fi
..
.SH NAME
edusers \- edit users list created by package
.SH SYNOPSIS
\fBedusers\fR [\fIsystem\fR [\fIversion\fR]]
.SH DESCRIPTION
This command lets you safely edit the \fIusers\fR list created by the
.I package
command. It locks the file before launching the editor, hence protecting
against any concurrent update by some \fIpackage\fR command that could
arrive at the same time (by e-mail). The level of protection this locking
buys you depends on the locking policy you have configured in
your \fI~/.mailagent\fR.
.PP
If you are within a package source tree, all you need to say is
.Ex
edusers
.Ef
to edit the \fIusers\fR file for that package. In order for that particular
feature to work properly, the package must have been placed under dist control,
or at least the \fIpackinit\fR command from the dist package must have been
run.
.PP
Otherwise, you may specify
a system name, and optionally a version number if that is not enough to
disambiguate. Using '-' will get you the lattest version available.
.PP
In any case, there must be a proper setting of the \fIdistribs\fR file
to use this command. If that file is not accurate, the \fIpackage\fR
command will not be able to produce a \fIusers\fR file anyway.
.SH ENVIRONMENT
The editor is taken out of the EDITOR variable if defined, then from
the VISUAL variable, defaulting to
.I $defeditor
if none of the variables is set.
.SH FILES
.PD 0
.TP 20
~/.mailagent
configuration file for mailagent.
.TP
Spool/distribs
distribution list, same file as the one used for mailpatch.
.TP
System/.package
file created by dist's packinit command to indicate
the root of the source tree for that package.
.TP
System/users
list of users of that system.
.TP
Log/agentlog
mailagent's log file.
.PD
.SH AUTHOR
Raphael Manfredi <Raphael_Manfredi@pobox.com>
.SH "SEE ALSO"
mailagent($manext), metaconfig($manext), package($manext), packinit($manext).
!GROK!THIS!
chmod 444 edusers.$manext
