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
echo "Extracting agent/man/package.$manext (with variable substitutions)"
$rm -f package.$manext
$spitshell >package.$manext <<!GROK!THIS!
.TH PACKAGE $manext
''' @(#) Manual page for mailagent's package command
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
'''  Original Author: Graham Stoney, 1993
'''
''' $Log: package.SH,v $
''' Revision 3.0.1.4  1999/07/12  13:47:00  ram
''' patch66: updated my e-mail address
'''
''' Revision 3.0.1.3  1996/12/24  14:44:21  ram
''' patch45: examples are now shown in constant-width font if possible
''' patch45: mentions command forwarding
'''
''' Revision 3.0.1.2  1995/08/07  16:14:46  ram
''' patch37: updated my e-mail address
'''
''' Revision 3.0.1.1  1994/09/22  13:59:03  ram
''' patch12: documents the edusers script and fuzzy address matching
'''
''' Revision 3.0  1993/11/29  13:48:31  ram
''' Baseline for mailagent 3.0 netwide release.
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
package \- register package user via mailagent
.SH SYNOPSIS
\fBpackage\fR \fIaddress\fR \fIsystem\fR \fIversion\fR \fIpatchlevel\fR
[ mailpatches | notifypatches ]
.SH DESCRIPTION
This command is not intended to be run directly by a user, but may
appear in any mail whose subject is set to \fICommand\fR. Such mail
will be processed by the \fImailagent\fR(1), which will extract all lines
beginning with \fI@SH\fR, which may specify this command. The
mailagent first sets environment variables that will be used by the
command.
.PP
.I Package
is used to notify the author of a package about its users.
It is normally generated automatically by the MailAuthor.U unit when the user
runs
.IR Configure .
.PP
If the
.I patchlevel
specified is not the latest for that
.I system
and
.IR version ,
mail is immediately sent suggesting that they upgrade and remindng them how to
request the latest patches.
.PP
The final parameter, if included may be set to
.I mailpatches
to specify that the user would like to have future patches mailed to them, or
.I notifypatches
to specify that a mail notification of future patches should be sent, rather
than the entire patch.
.PP
The user's
.I address
and notification request are saved in the file
.I users
in the package's directory.
.PP
.I Package
performs an approximate address match in order to avoid duplicate entries.
Whenever this elimination occurs, a warning message is issued in the logfile.
Two addresses will be said equivalent if one of them has an added machine name
or if they are really equal. Therefore, the following addresses are equivalent:
.Ex
ram@acri.fr
ram@main.acri.fr
.Ef
whereas the following two are \fInot\fR equivalent, unfortunately:
.Ex
ram@acri.acri.fr
ram@main.acri.fr
.Ef
When a user is asking to be left alone, it is important to let him know if
the request failed, because he will be annoyed when the next set of patches
is issued and he still gets them despite his previous request. Therefore, if
no approximate match occurs, a warning message is sent back, with a list
of addresses that are \fIclose\fR to his own e-mail address, but not
equivalent. Fortunately, the following addresses are considered close:
.Ex
ram@acri.fr
ram@somewhere.com
raphael@main.acri.fr
manfredi@acri.acri.fr
.Ef
because they either have the same login (important when someone changes
company) or share the same domain or sub-domain part.
.PP
In order to edit the \fIusers\fR file, the
.I edusers
script should be used. For one thing, it will let you edit the
.I users
file from
whatever package you name in the command line, but it will also properly lock
the file so that the execution of \fIpackage\fR will stall for the duration
of the manual edition (provided you have a strict locking policy defined in
your \fI~/.mailagent\fR configuration file).
.SH FORWARDING
.I Package
supports command forwarding as described in the \fImailhelp\fR($manext) page.
.SH FILES
.PD 0
.TP 20
~/.mailagent
configuration file for mailagent.
.TP
System/users
list of users of that system.
.IP
This file consists of single line records, one for each registered user.
Each record consists of three tab-separated fields.
.sp
The first field indicates
the level of updates requested by the user by a single letter as follows:
.RS
.TP
.B M
Mail future patches directly to the user when they are issued.
.TP
.B N
Notify the user of future patches.
.TP
.B U
The users chose to let the author know that they have tried the program, but
does not wish to know about future updates.
.TP
.B L
The user is no longer interested in the program and wants to be left alone.
.RE
.sp
.IP
The second field is their last notified patch level, or a dash
.RB ( - )
if it is not known.
.sp
.IP
The third field is the user's Email address.
.TP
Log/agentlog
mailagent's log file
.PD
.SH AUTHORS
Graham Stoney <greyham@research.canon.oz.au>
.br
Raphael Manfredi <Raphael_Manfredi@pobox.com> (minor enhancements)
.SH "SEE ALSO"
edusers($manext), mailagent($manext), metaconfig($manext).
!GROK!THIS!
chmod 444 package.$manext
