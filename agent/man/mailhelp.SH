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
echo "Extracting agent/man/mailhelp.$manext (with variable substitutions)"
$rm -f mailhelp.$manext
$spitshell >mailhelp.$manext <<!GROK!THIS!
.TH MAILHELP $manext ram
''' @(#) Manual page for mailagent's commands -- (c) ram February 1991
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
''' $Log: mailhelp.SH,v $
''' Revision 3.0.1.3  1999/07/12  13:46:52  ram
''' patch66: updated my e-mail address
'''
''' Revision 3.0.1.2  1996/12/24  14:41:59  ram
''' patch45: documented command forwarding
'''
''' Revision 3.0.1.1  1995/08/07  16:14:40  ram
''' patch37: updated my e-mail address
'''
''' Revision 3.0  1993/11/29  13:48:29  ram
''' Baseline for mailagent 3.0 netwide release.
'''
.SH NAME
maildist, mailhelp, maillist, mailpatch \- mailagent's commands
.SH SYNOPSIS
\fBmaildist\fR \fIaddress\fR \fIsystem\fR [ \fIversion\fR ]
.br
\fBmailhelp\fR [ \fIaddress\fR ]
.br
\fBmaillist\fR [ \fIaddress\fR ]
.br
\fBmailpatch\fR \fIaddress\fR \fIsystem\fR \fIversion\fR \fIpatchlist\fR
.SH DESCRIPTION
These commands are not intended to be run directly by a user. They may
appear in any mail whose subject is set to \fICommand\fR. Such a mail
will be processed by the \fImailagent\fR(1), which will extract all lines
beginning with \fI@SH\fR, followed by one of the above commands. The
mailagent first sets environment variables that will be used by every
commands.
.PP
.I Maildist
is used to mail a whole distribution to the given address. The version
number may be ommitted if the system has no version specified !!
.I Maildist
looks for the \fISpool/distribs\fR file to find where the distribution
is located. If it has been archived, the file name extension is used
to guess how the archive will be restored:
.sp
.PD 0
.TP 10
.B .cpio
archive is a \fIcpio\fR archive
.TP
.B .tar
archive is in \fItar\fR format
.TP
.B .cpio.Z
compressed \fIcpio\fR archive
.TP
.B .tar.Z
compressed \fItar\fR archive
.PD
.PP
Note that on file systems with short file names, the final \fB.Z\fR
extension could be dropped. Therefore, compressed archives must be
explicitely stated in the \fISpool/distribs\fR file.
.PP
Once the directory is found (or extracted), \fImaildist\fR looks
for a \fI.package\fR file. If one is found, then it is assumed this
distribution is under control of the dist 3.0 package, and the \fImakedist\fR
commmand is called to actually mirror the source tree (makedist being part of
dist 3.0).
.PP
Otherwise, it looks
for a \fIMANIFEST\fR file. If it finds one,
only the files listed therein will be sent. Otherwise,
all the files will be sent, excepted the binary executables and object
files, the RCS sub-directories or RCS files, the private \fIU\fR
subdirectory and the \fI.package\fR file, any \fIcore\fR file or files
in a \fIbugs\fR subdirectory.
.PP
Then, the following algorithm is used: if no RCS file is found, the
file is sent as-is. Otherwise, we look for a defined 'lastpat' symbol.
If it is found, the corresponding revision is checked-out and sent.
Otherwise, the last-revision on the default branch is exctracted,
provided that the corresponding working file is not found.
.PP
The \fImaildist\fR command will not work if the system is tagged as
an old one (with an \fIo\fR in the patches column of the \fIdistribs\fR
file). A message will be sent back to the user, explaining that only
patches are available.
.PP
.I Mailhelp
sends help to the address (if ommitted, the return path of the mail
is used). The help text is found in \fISpool/agenthelp\fR. It should
have been correctly set in the installation procedure, as explained
in the \fImailagent\fR($manext) manual page.
.PP
.I Maillist
sends the list of available distributions, with current patchlevels
if necessary. The \fISpool/distribs\fR and \fISpool/proglist\fR files
are both used to build the list.
.PP
.I Mailpatch
sends one or more patches for a maintained distribution. The directory
or the archive is found by scanning \fISpool/distribs\fR. The \fIbugs\fR
sub-directory must then hold the available patches. The patches may
be stored in compressed form (with the ending \fI.Z\fR), as
.I mailpatch
knows about them and will uncompress the patch before sending.
.PP
Patches for old systems are kept in a separate directory, either in normal
or in compressed form. If the version number of the old system is \fIx.y\fR,
then the directory must be named \fIbugs-x.y\fR and placed in the root
directory of the system, just like \fIbugs\fR is.
.PP
Whenever the user asks for an old system, \fImailpatch\fR inserts a little
note giving the latest version number for that system.
.SH NOTE
For a more accurate description of these commands (user's point of vue),
you may want to have a look at the help file or send help to yourself
using the \fImailhelp\fR command.
.SH FORWARDING
When the author of a package wishes to relinquish all maintenance duty, he
is most often stuck by the weight of the past: Configure scripts have his
e-mail address hardwired (see unit MailAuthor.U) and Command messages for
package registration and/or patch requests will continue to reach him.
.PP
The answer to that is to leave a \fI.forward\fR file at the top of the package
tree and commands will automatically forge new requests and forward them
to the address listed in the .forward file. Now the recipient
surely needs a mailagent at the other end to deal with forwarded requests!
.PP
Only plain e-mail address(es) are allowed in the .forward. The "|command"
processing hook is not supported, since it's not \fIsendmail\fR which interprets
that file but the command itself.
.PP
Forwarding applies to \fImaildist\fR, \fImailpatch\fR and \fIpackage\fR commands
only.
.SH FILES
.PD 0
.TP 20
~/.mailagent
configuration file for mailagent.
.TP
$privlib
directory holding templates and samples.
.TP
Spool/agenthelp
help file
.TP
Spool/distribs
distribution list
.TP
Spool/proglist
comments for available distributions
.TP
Spool/plsave
records patchlevel of archived distributions
.TP
Log/agentlog
mailagent's log file
.PD
.SH BUGS
The \fIproglist\fR file ought to make a distinction between different
versions of a same system.
.SH AUTHOR
Raphael Manfredi <Raphael_Manfredi@pobox.com>
.SH "SEE ALSO"
mailagent($manext), package($manext).
!GROK!THIS!
chmod 444 mailhelp.$manext
