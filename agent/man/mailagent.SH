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
echo "Extracting agent/man/mailagent.$manext (with variable substitutions)"
$rm -f mailagent.$manext
$spitshell >mailagent.$manext <<!GROK!THIS!
.TH MAILAGENT $manext "Version $VERSION PL$PATCHLEVEL"
''' @(#) Manual page for mailagent's filter -- (c) ram February 1991
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
''' $Log: mailagent.SH,v $
''' Revision 3.0.1.26  2001/03/17 18:08:30  ram
''' patch72: documented new config vars: domain and hidenet
''' patch72: various fixes from bug reports on Debian
'''
''' Revision 3.0.1.25  2001/03/13 13:10:47  ram
''' patch71: documented SUBST/TR on header fields
'''
''' Revision 3.0.1.24  2001/01/10 16:51:38  ram
''' patch69: changed semantics of "tome"
''' patch69: updated POST to current practices
''' patch69: documented biffing macros for news article
'''
''' Revision 3.0.1.23  1999/07/12  13:46:20  ram
''' patch66: variables are now propagated back and forth through APPLY
''' patch66: updated my e-mail address
'''
''' Revision 3.0.1.22  1999/01/13  18:10:52  ram
''' patch64: added %Y macro for 4-digit year output
''' patch64: agent.wait file moved from Queue to Spool
'''
''' Revision 3.0.1.21  1998/07/28  16:59:10  ram
''' patch62: documented new "servshell" variable
'''
''' Revision 3.0.1.20  1998/03/31  14:40:01  ram
''' patch59: added "vacfixed" and "tofake" configuration parameters
''' patch59: new ON command to issue commands on certain days only
''' patch59: the SERVER "set" command can now list defined variables
''' patch59: added an example of alternate VACATION message selection
'''
''' Revision 3.0.1.19  1997/09/15  15:07:18  ram
''' patch57: new -t and -f options for BEGIN and NOP
''' patch57: all command options should now be output in bold
''' patch57: documented _CALLOUT_ working state for callout queue
'''
''' Revision 3.0.1.18  1997/02/20  11:40:44  ram
''' patch55: documents new execsafe, groupsafe and lockwarn variables
''' patch55: the C filter can now redirect output via -o
''' patch55: made it explicit that /pattern/i is legal
'''
''' Revision 3.0.1.17  1997/01/07  18:29:18  ram
''' patch52: documented new execsafe configuration variable
'''
''' Revision 3.0.1.16  1996/12/24  14:12:58  ram
''' patch45: examples are now shown in constant-width font if possible
''' patch45: big emphasis about security issues, for RUN commands & filter
''' patch45: new Relayed: pseudo header computations
''' patch45: documented the %-H biffing macro with more details
''' patch45: updated my e-mail address
'''
''' Revision 3.0.1.15  1995/09/15  13:56:30  ram
''' patch43: folder compression can now deal with various compressors
''' patch43: added locksafe, compspecs and comptag config variables
''' patch43: many typo fixes
'''
''' Revision 3.0.1.14  1995/08/31  16:27:44  ram
''' patch42: escaped various dollars to avoid shell substitution, grrr...
'''
''' Revision 3.0.1.13  1995/08/07  16:14:23  ram
''' patch37: new biffing features and configuration variables
''' patch37: new BIFF filtering command to dynamically configure biffing
'''
''' Revision 3.0.1.12  1995/03/21  12:56:05  ram
''' patch35: sample vacation message now contains a Precedence: header
'''
''' Revision 3.0.1.11  1995/02/16  14:28:45  ram
''' patch32: documents new -I switch and new fromfake config variable
''' patch32: random cleanup, mainly suppressing spurious "the" articles
'''
''' Revision 3.0.1.10  1995/01/25  15:17:42  ram
''' patch27: new option letter 't' for mailagent -s
''' patch27: new commands BEEP and PROTECT
''' patch27: new macro %a for biff messages
'''
''' Revision 3.0.1.9  1995/01/03  18:01:53  ram
''' patch24: new -u option for ANNOTATE documented
''' patch24: fixed example on the shell server command (power checking)
''' patch24: removed quotes for SERVER -d to accommodate new option parsing
''' patch24: added a -l switch to VACATION and extended its arguments
''' patch24: new section documenting Rule Environment variables
'''
''' Revision 3.0.1.8  1994/10/29  17:41:41  ram
''' patch20: documents the six new config variables for biffing
''' patch20: new section dedicated to built-in mail biffing
'''
''' Revision 3.0.1.7  1994/10/10  10:23:36  ram
''' patch19: typo fix
'''
''' Revision 3.0.1.6  1994/10/04  17:41:47  ram
''' patch17: documents new email and mboxlock config parameters
''' patch17: documents ~/agent.trace file and callout queue file name
''' patch17: new %e macro available to get user's e-mail address
''' patch17: mentions that the msgpath variable is read-only
'''
''' Revision 3.0.1.5  1994/09/22  13:57:09  ram
''' patch12: documents new config parameters callout and linkdirs
''' patch12: new filtering actions AFTER and DO
''' patch12: variable msgpath is now defined within a PERL escape
''' patch12: mention that PERL escape variables are available to new commands
'''
''' Revision 3.0.1.4  1994/07/01  14:56:20  ram
''' patch8: documents new eleven configuration variables
''' patch8: sub-section on timeouts has been expanded
''' patch8: emphasize .forward optimization danger with sendmail
''' patch8: new UMASK command
'''
''' Revision 3.0.1.3  1994/04/25  15:15:56  ram
''' patch7: documented new 'fromesc' config variable
''' patch7: forgot to insert the new -F option in the synopsis line
'''
''' Revision 3.0.1.2  1994/01/26  09:29:24  ram
''' patch5: documents new tag feature for UNIQUE and RECORD
''' patch5: documents new -F option
''' patch5: random typo fixes
'''
''' Revision 3.0.1.1  1993/12/15  09:03:44  ram
''' patch3: typo and minor fixes
'''
''' Revision 3.0  1993/11/29  13:48:27  ram
''' Baseline for mailagent 3.0 netwide release.
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
mailagent \- an automatic mail-processing tool
.SH SYNOPSIS
\fBmailagent\fR [ \fB\-dhilqtFIVU\fR ] [ \fB\-s{umaryt}\fR ]
[ \fB\-f\fI file\fR ]
[ \fB\-e\fI rule\fR ] [ \fB\-c\fI config\fR ] [ \fB\-L\fI loglevel\fR ]
[ \fB\-r\fI rulefile\fR ] [ \fB\-o\fI override\fR ] [ \fImailfile\fR ]
.SH DESCRIPTION
.I Mailagent
allows you to process your mail automatically. Given a set of \fIlex\fR-like
rules, you are able to fill mails to specific folders, forward messages to
a third person, pipe a message to a command or even post the message to a
newsgroup. It is also possible to process messages containing some
commands.
The \fImailagent\fR is not usually invoked manually but is rather called via
the \fIfilter\fR program, which is in turn invoked by \fIsendmail\fR.
That means you must have \fIsendmail\fR on your system to use this.
You also must have \fIperl\fR to run the mailagent scripts.
.PP
There is a set of options which may be used when you invoke
\fImailagent\fR yourself. Please refer to the \fBOPTIONS\fR section for
a complete description. You may use the \fB\-h\fR option to get a cryptic
usage reminder.
'''
.SS Product Overview
.PP
.I Mailagent
has actually four distinct set of features, which can be used simultaneously
or one at a time. This involves:
.IP \(bu 5
An @SH command processor, to remain compatible with the first implementation.
In this simplest usage, all the mail messages are left in your mailbox,
with special processing raised on messages whose subject is \fICommand\fR.
Please refer to the section entitled \fBUSING THE DEFAULT RULES\fR if you
wish to use this feature.
.IP \(bu
A complete mail filter, which helps you sort your mail based on various
sorting criteria and actions. Filtering is specified in a rule file and
supersedes the default \fICommand\fR mail processing (which may be turned on
again by explicitly setting up a rule for it). This should be the most
common use of \fImailagent\fR and is fully documented under the section
entitled \fBUSING THE FILTER\fR.
You may deliver mail to plain Unix-style folders but also to MMDF and MH ones.
.IP \(bu
A replacement for the \fIvacation\fR program, which will automatically
answer your mail while you are not there. You only need to supply a message
to be sent back and the frequency at which this will occur. Some simple
macro substitutions allow you to re-use some parts of the mail header into
your vacation message, for a more personalized reply. See the \fBVACATION
MODE\fR section for more details.
.IP \(bu
A generic mail server, which will let you implement a real mail server
without the hassle of the lower-level concerns like error recovery,
logging or command parsing. The full documentation can be found in the
section \fBGENERIC MAIL SERVER\fR at the end of this manual page.
.PP
It is possible to extend the mailagent filtering commands by implementing
them in \fIperl\fR and then having them automagically loaded when used. Those
extended commands will behave exactly like built in ones, as documented
in the \fBEXTENDING FILTERING COMMANDS\fR section.
'''
.SS Learning From Examples
.PP
It is quite possible that you will find this manual page too complex for you.
Unfortunately, it is not really meant to be a tutorial but rather a reference
material. If you wish, you may start by looking at the examples held in the
distribution source tree under \fIagent/examples\fR. This directory contains
two examples of rule files (look at the README file first) and are verbosely
commented.
'''
''' G e t t i n g   S t a r t e d
'''
.SH "GETTING STARTED"
.PP
First, you need to install a minimum configuration and see how it works. It
would be useless to fully install the program and then discover that it does
not work as advertised...
.PP
To start the installation, you have to set up a \fI~/.mailagent\fR file which is
the main configuration file, and choose the right \fIfilter\fR program.
'''
.SS "Choosing The Filter Program"
.PP
The distribution comes with two filter programs. One written in shell and one
in C. The shell version might be the one to use if you can receive your mail
on many different platforms where your home directory is NFS-mounted (i.e.
shared among all those platforms). The C version is safer and much faster,
but you need to install it to a fixed location.
.PP
On some platforms, \fIsendmail\fR does not correctly reset its UID when
processing mails in its own queue. In that case, you need to get a private
copy of the C filter program and make it setuid to yourself. The filter will
then correctly reset its UID if invoked with an effective UID different from
yours (it may also require the setgid bit to reset GID as well).
If this is indeed the case on your system, make sure you use the
\fIpath\fR configuration variable to set a proper PATH, as the filter will
spawn a perl process with the '-S' option, looking for a \fImailagent\fR
script.
.PP
Even if you do not need to get a setuid copy of the \fIfilter\fR program, it
is wise to set up a proper path: someone might break into your account by
putting a mailagent Trojan horse in the appropriate location. Also make sure
the mailagent program is protected against writing, as well as the directory
which holds it, or someone might substitute his own version of the script
and break security. I believe the setuid \fIfilter\fR program to be safe, but
overlooking is always possible so please report any security hole to me.
.PP
The \fIfilter\fR script can be found in the \fILib/mailagent\fR directory. It
needs some tailoring so you should copy it into your home directory and edit
it to suit your needs. Comments held in it should be
self explanatory. There is only a small section at the head of the
script which needs to be edited.  You'll have to delete shell comments
in the \fIfilter\fR script by yourself if your shell cannot deal with them.
.PP
As of version 3.0 PL44, I advise you to prefer the C version if you are
concerned about security. If you are in a position where multiple architectures
can process your \fI.forward\fR, then a shell wrapper selecting the proper
executable based on the architecture will be required.
'''
.SS "Configuring Mailagent"
.PP
If \fImailagent\fR is in your path, you may automatically configure a default
installation by running:
.Ex
	mailagent -I
.Ef
which will create a \fI~/.mailagent\fR file from an existing template,
customize some important variables for your site, and make some basic
sanity checks. Everything the command does is output on the screen for
checking purposes, and any problem found is reported.
.PP
Otherwise, you have to copy the \fImailagent.cf\fR file held in the mailagent
sub-directory \fI$privlibexp\fR (hereafter named Lib)
as a \fI.mailagent\fR in your home directory. Edit it to configure the
whole processing. In particular, you have to choose a spool directory
(hereafter named Spool) and a log directory (hereafter named Log).
.PP
Note that using the automatic installation procedure above does not
prevent you from going through the file and modifying it as you wish.
In fact, you are greatly encouraged to do this, especially for the
home directory setting, the logging level and the \fIpath\fR or \fIp_host\fR
variables. Once you are done,
rerun the \fImailagent -I\fR command to make sure everything is fine.
Still, you will have to plug in mailagent by creating a \fI~/.forward\fR
file, as explained in a few sections.
.PP
Following is a description of each of the fields you will find in
the \fI~/.mailagent\fR file, followed by a suggested
value, when applicable. Fields marked as optional may not be present in the
configuration file. Some fields have a close relationship with others, and
that is given too.
.sp
.PD 0
.TP 10
.I agemax
Period after which an entry in the database should be removed (suggested: 1y)
This field is optional, but needed if \fIautoclean\fR is on.
.TP
.I authfile
Remote sending authorizations (not implemented yet).
.TP
.I autoclean
Set to ON (case insensitively), mailagent will perform automatic cleaning
of the database entries under \fIhash\fR by removing all the items older
than \fIagemax\fR. This is an optional field, omitting it defaults to OFF.
(suggested: OFF, unless you use ONCE, UNIQUE or RECORD commands, or activate
the vacation mode.)
.TP
.I biff
Whether or not biffing is wanted when \fImailagent\fR delivers mail to
a folder. Set it to ON (case insensitively) to allow local biffing if you
are logged in. (optional, defaults to: OFF)
.TP
.I biffhead
When biffing is enabled, this variable lists which headers should be
printed out. Headers should be given in their normalized format and
be separated with commas. (optional, defaults to: From, To, Subject, Date).
.TP
.I bifflen
The maximum length of the message body that should be printed when biffing.
(optional, defaults to 560).
.TP
.I bifflines
The maximum number of lines of the message body that should be printed when
biffing. Actually, \fImailagent\fR attempts to print that amount of lines,
provided the total amount of characters printed is less than \fIbifflen\fR.
(optional, defaults to 7).
.TP
.I biffmh
When turned ON, the body of the message is compacted before biffing by
removing consecutive spaces and replacing newlines with a single space.
The message itself is not altered physically of course, only the output
on the screen is concerned.
Since this may yield to a difficult-to-read message, I suggest you also
turn on \fIbiffnice\fR when using this option. (optional, defaults to: OFF).
.TP
.I biffmsg
The path to a file describing the format biffing should use. If not set,
a default hardwired format is used. Season to taste. (suggested: ~/.biffmsg).
.TP
.I biffnice
When \fIbiffmh\fR is turned ON, this option controls whether the compacted
message should be reformatted to nicely fit into 80 columns.
(optional, defaults to OFF, suggested: ON when \fIbiffmh\fR is also ON).
.TP
.I biffnl
Controls whether "blank" body lines should be printed or not. By "blank" lines,
we mean lines not containing words. Set it to ON to print such blank lines,
to OFF if you wish to get a more compact view of the body within the limits
fixed by \fIbifflen\fR and \fIbifflines\fR. (optional, defaults to ON).
.TP
.I biffquote
Controls whether the leading attribution line introducing a trimmed
quotation should be part of the biff message or not. When turned OFF, the
attribution line is trimmed along and this is reported in the trimming
message, when \fIbifftrim\fR is ON. (optional, defaults to ON).
.TP
.I bifftrim
Controls whether trimmed lines within the biff message should be replaced
by a message stating how many of them were trimmed. Only used by the %-T
biffing macro. When turned OFF, it automatically turns off \fIbiffquote\fR
as well. (optional, defaults to ON).
.TP
.I bifftrlen
States how many lines long a leading quotation should be before performing any
trimming. Only used by the %-T biffing macro. (optional, defaults to 2).
.TP
.I callout
The name of the callout queue file where batched jobs are kept. This
parameter must be defined when using the AFTER command.
(suggested: \$spool/callout)
.TP
.I cleanlaps
Cleaning period for database entries. The value of the last clean up is saved
into the context file. This is optional, but needed if \fIautoclean\fR is on.
(suggested: 1M)
.TP
.I comfile
Name of the file containing authorized commands. Needed when PROCESS is used.
(suggested: \$spool/commands).
.TP
.I compress
Name of the file containing the list of compressed folders. See section about
folder compression. This is an optional parameter. (suggested: ~/.compress).
.TP
.I compspecs
Name of the file containing specifications for how to handle different
types of compression formats.  See section about folder compression.
This is an optional parameter. (suggested: \$spool/compressors).
.TP
.I comptag
The default compression tag when creating new folders.
If not specified, the default is 'compress'.
.TP
.I comserver
Name of the file containing authorized SERVER commands and their definition.
This is an optional parameter if you don't plan to use the generic mail server.
(suggested: \$spool/server).
.TP
.I context
File holding the mailagent context. The context saves some variables which
need to be kept over the life of the process. Needed if auto cleaning is
activated. (suggested: \$spool/context)
.TP
.I distlist
A list of all the available distributions. See the sample held in
\fILib/mailagent/distribs\fR. Needed by PROCESS only. (suggested:
\$spool/distribs)
.TP
.I domain
Your domain name, without the leading dot, as in \fIexample.com\fR.
The value is appended to the value of \fIemail\fR when that variable
does not have any '@', to construct a fully qualified e-mail address.
See also the \fIhidenet\fR variable.
(optional, defaults to the domain name determined at build time).
.TP
.I email
Your electronic mail address. If left unspecified, mailagent will try to
guess it. This address is used by mailagent when trying to send something
to the user (you!). (suggested: specify your e-mail address).
.TP
.I emergdir
Name of the directory which should be used for dumps, preferably. This is
optional. (suggested: ~/tmp/lost+mail)
.TP
.I execsafe
Whether to be strict before using \fIexec()\fR to launch a new process or
not. The value of this variable is used in place of \fIsecure\fR when checking
executable files. (defaults to OFF, suggested: ON if possible).
.TP
.I execskip
Whether to skip the \fIexec()\fR security checks alltogether. Don't turn
this ON unless you really trust all the users having access to your machine
or file server. (optional, default to OFF, suggested: OFF).
.TP
.I fromall
Whether or not \fImailagent\fR should escape all the \fIFrom\fR lines in the
message, not only those it thinks should appear dangerous (i.e. a \fIFrom\fR
after a blank line). This option only makes sense when \fIfromesc\fR is
also activated. It is ignored otherwise, and therefore is optional. By
default, it is assumed to be OFF. (suggested: OFF, until you have reasons to
believe your mail user-agent is confused in this mode: when it happens, your
user agent will split mail for no apparent reason).
.TP
.I fromesc
Whether or not \fImailagent\fR should escape potentially dangerous \fIFrom\fR
lines in mail messages. If you use MH or if your mail reader does not use
those lines to separate messages, then you may set it to OFF. (suggested: ON)
.TP
.I fromfake
Whether or not \fImailagent\fR should fake a From: line into the message
header when it is absent. Naturally, it requires a valid leading From line to
operate! (optional, defaults to ON, suggested: ON).
.TP
.I groupsafe
If turned OFF, then group-writable files will be managed as if they were
secure, from a security point of view. Leave it to ON if possible, or
you may pass by a huge security hole without your noticing (optional,
defaults to ON, suggested: ON).
.TP
.I hash
The directory used for name hashing by the built-in database used by ONCE,
UNIQUE and RECORD commands. Optional, unless you make use of those commands
or activate auto cleaning. The directory is placed in the spool area.
(suggested: \$spool/dbr).
.TP
.I helpdir
Directory where help files for SERVER commands are kept.
(suggested: \$spool/help)
.TP
.I hidenet
When set to ON, the value of the variable \fIdomain\fR is the fully qualified
name used.  When OFF, the hostname is prepended to the \fIdomain\fR.  If
the hostname is already fully qualified, then the value of \fIdomain\fR is
ignored.  Assuuming \fIdomain\fR is set to \fIexample.com\fR and the hostname
is \fIhost\fR, then the fully qualified name will be \fIhost.example.com\fR
if \fIhidenet\fR is OFF, and \fIexample.com\fR if ON.
(optional, defaults to whatever was determined at build time)
.TP
.I home
Defines where the home directory is. This must be accurate.
.TP
.I level
Log level, see below for a definition of available levels (suggested: 9).
.TP
.I linkdirs
When set to ON, carefully checks symbolic links to directories when performing
security checks on sensitive files. This will (recursively) check for each
symbolic link level that the target directory is not world writable or group
writable and that the parent directory of each target link is not world
writable. If the \fIsecure\fR option is OFF, this parameter is ignored.
(optional, defaults to: ON, suggested: ON when secure is also ON).
.TP
.I lockdekay
The delay in seconds between two locking attempts. (optional, defaults to: 2).
.TP
.I lockhold
The maximum delay in seconds for holding a lock. After that time, the lock
will be broken. (optional, defaults to: 3600).
.TP
.I lockmax
Maximum number of locking attempts before giving up. (optional,
defaults to: 20).
.TP
.I locksafe
When locking a file, \fImailagent\fR normally makes \fIlockmax\fR attempts
separated by \fIlockdelay\fR seconds, and then gives up. When facing a
delivery to a mailbox, it may make sense to continue even if no lock was
grabbed, or even if only a partial locking was done (e.g. one of the .lock or
flock()-style locking succeeded). This variable controls how safe you want
to be. Set it to OFF to let mailagent continue its mailbox delivery even
though no locking was done, to ON if you want strict locking, to PARTIAL if
you can live with partial locking. Messages not saved in a folder are
dumped to an emergency mailbox. (optional, defaults to ON).
.TP
.I lockwarn
This variable controls the time after which \fImailagent\fR should
start emiting a warning when busy trying to acquire a lock.
It is a comma separated list of values, in seconds. If two values are
given, the first is the initial time threshold, the second is the
repeat period. For instance, a value of "15,60" would cause a warning
after 15 seconds, then every 60 seconds until the lock is taken or
the locking attempt time is expired (see
.I lockmax
and
.IR lockdelay ).
If only one value is given, it is taken as being both the initial
threshold and the period.
(optional, defaults to: 20,300).
.TP
.I log
Name of the log file which will be put in Log directory. (suggested: agentlog).
.TP
.I logdir
Logging directory. (suggested: ~/var/log).
.TP
.I mailbox
The name of the system mailbox file, which by default is the value of the
\fIuser\fR configuration variable. This is an optional parameter.
.TP
.I maildrop
Location of the system mail spool directory. If none is provided, then the
mailagent will use the value determined by Configure.
.TP
.I mailopt
Options to be passed to the mailer (see \fIsendmail\fR). (optional, suggested:
-odq, when using sendmail).
.TP
.I maxcmds
Maximum number of commands that are allowed to be executed by a SERVER command
before flushing the remaining of the mail message. (suggested: 10).
.TP
.I maxerrors
Maximum number of errors for the SERVER command before flushing the remaining
of the mail message. (suggested: 10).
.TP
.I maxsize
Maximum size in bytes of files before using \fIkit\fR for sending files. This
is used by PROCESS. (suggested: 150000).
.TP
.I mboxlock
The format to be used for locking mailboxes before delivering to them. This
string goes through a small macro substitution mechanism to make it more
general. The file name derived after macro substitution is the name of the
lock that will be used, given the name of the file that is to be locked.
Available macros are:
.Ex
%D: the file directory name
%f: the file name to be locked (full path)
%F: the file base name (last path component)
%p: the current process pid number
%%: a plain % character
.Ef
Common locking formats are "%f.lock" and "%D/.%F.lock". Of course, to be able
to use this feature, mailagent must not have been configured to use
flock()-style locking only. (optional, defaults to: %f.lock).
.TP
.I mhprofile
The name of the MH profile to be used. This is needed only when attempting
to save in an MH folder. If this optional parameter is not set, the default
value \fI~/.mh_profile\fR is used.
.TP
.I mmdf
Set this to ON if you wish to be able to save mail in MMDF-style mailboxes.
(suggested: OFF, unless you use MMDF or MH).
.TP
.I mmdfbox
The value of this variable only matters when \fImmdf\fR is on. If set to ON,
then new folders will be created as MMDF ones. This variable is not used when
saving to an existing folder, since in that case the \fImailagent\fR will
automatically determine the type and save the message accordingly.
(suggested: OFF, unless you use MMDF or wish to use MH's \fImshf\fR).
.TP
.I msgprefix
Name of the file to put in directory folders, specifying the message prefix
to be used. Optional, defaults to \fI.msg_prefix\fR.
.TP
.I name
First name of the user, used by mailagent when referring to you. This sets
the value of the %U macro.
.TP
.I newcmd
Name of the file describing new filtering commands. See section \fIExtending
Filtering Commands\fR for more details. Leave this optional parameter out
unless you are a mailagent expert. (suggested: \$spool/newcmd).
.TP
.I newsopt
Options to be passed to the news posting program (see \fIsendnews\fR).
(optional, suggested: leave empty when using inews).
.TP
.I nfslock
Set it to ON to ensure NFS-secure locks. The difference is that the hostname
is used in conjunction with the PID to obtain a lock. However, mailagent
has to fork/exec to obtain that information. This is an optional parameter
which is set to OFF by default. (suggested: OFF if you deliver
mail from only one machine, even though it's via NFS).
.TP
.I passwd
File where SERVER power passwords are kept -- encrypted usually.
(suggested: \$powers/passwd).
.TP
.I path
Minimum path to be used by C filter program. To set a specific path
for a machine \fIhost\fR, set up a \fIp_host\fR variable. This will
be \fIprepended\fR to the default \fIPATH\fR variable supplied by other
programs. (suggested: /bin:/usr/bin:/usr/ucb). Note that the host name
must be specified without any domain name appended to it (e.g. for
an host name of \fIlyon.eiffel.com\fR, use variable \fIp_lyon\fR). If your
host name contains an '-' in it, you must write it as a '_', since '-' is
not a valid character for a \fIperl\fR variable name.
.TP
.I perlib
This variable may be used to change the perl search path for required files.
Directories should be separated using a ':' character, just like a shell PATH.
This path is prepended to the default perl search path. Any directory not
starting with a '/' (after ~name substitution) is taken relatively to the
mailagent private lib directory determined at configuration time.
.TP
.I plsave
Name of the file used to save the patchlevels for archived distributions.
This is only used by the commands invoked via PROCESS. (suggested:
\$spool/plsave).
.TP
.I powerdir
Directory listing user clearances for SERVER powers.
(suggested: \$powers/clearance)
.TP
.I powerlist
Name of file containing SERVER power aliases. Since power names can be
arbitrary long but some filesystems still have a 14 character limitation
on filename length, internal aliases are created and maintained by mailagent.
(suggested: \$powers/aliases).
.TP
.I powerlog
File where SERVER power requests are logged, in addition to the agentlog. Since
those are a security concern, it is a good idea to log them separately.
If not defined, log them only in agentlog. (suggested: \$logdir/powerlog).
.TP
.I powers
Directory for SERVER power administration. (suggested: \$spool/powers)
.TP
.I proglist
A small description for the available distributions. See the sample
held in \fILib/mailagent/proglist\fR. This is used by PROCESS only.
(suggested: \$spool/proglist)
.TP
.I queue
Queue directory (messages waiting to be processed). Required, of course.
(suggested: \$spool/queue)
.TP
.I queuehold
Maximum number of seconds a mail can sit in the mailagent queue before being
actually processed. During that time, \fImailagent\fR will not try to
process the message even when \fB\-q\fR is used. (optional, defaults to: 1800).
.TP
.I queuelost
Maximum number of seconds after which \fImailagent\fR should flag messages
still in its queue as being old. (optional, defaults to: 86400, i.e. a day).
.TP
.I queuewait
Time in seconds telling the C \fIfilter\fR program how long it must wait
before launching \fImailagent\fR. (optional, defaults to: 60, but can be
lowered to 0 if you don't want to wait to delay getting new messages).
.TP
.I rulecache
The name of the file used to cache the latest compiled rules. Since usually
\fImailagent\fR works mainly with one same rule file, this saves the overhead
of recompiling all the rules each time. (optional, suggested:
\$spool/rulecache).
.TP
.I rulemac
Set this to ON to enable macro substitutions in rule patterns.
(optional, defaults to: OFF).
.TP
.I rules
The name of the file holding the filtering rules (optional,
suggested: ~/.rules).
.TP
.I runmax
Timeout for RUN commands and friends. (optional, defaults to: 3600).
.TP
.I scriptcc
Flag indicating whether a copy of the SERVER session transcript should be
send to the user running mailagent. (suggested: OFF).
.TP
.I secure
When set to ON, mailagent and the C filter will perform extensive security
checks on sensitive files. This includes checks for group writability,
ownerships and protection testing on the directory where the file resides,
and checks on symbolic links to directories (mailagent only, when linkdirs
is ON too). Note that secure is assumed to be ON, whatever its real setting,
when running as super-user. (suggested: ON).
.TP
.I sendmail
The name of the program used to send mail. That program must accept the
mail message with headers on its standard input and a list of recipients
on the command line. If not specified, will use the mailer chosen at
configuration time (sendmail usually). The command line used to mail a message
will be \fIsendmail mailopt address(es)\fR.
(optional, suggested: /usr/lib/sendmail).
.TP
.I sendnews
The name of the program used to post news. That program must accept the
news article with headers on its standard input. If not specified, will use
the news posting program chosen at configuration time (inews usually).
The command line used to post an article will be \fIsendnews -h newsopt\fR.
(optional, suggested: /usr/local/bin/inews).
.TP
.I seq
File used to compute job numbers (suggested: .seq).
.TP
.I servdir
The directory name where shell and perl server commands are stored. This is
the default lookup place. Optional parameter unless SERVER is used.
(suggested: \$spool/cmds).
.TP
.I servshell
This is the name of the shell used to launch SERVER shell commands (actually
to proces the wrapper file that will ultimately exec() the command). On some
systems like HPUX 10.x, this has to be set to /usr/old/bin/sh to get the
plain old Bourne shell, because /bin/sh is a braindead POSIX shell that
closes file descriptors greater than 2 upon exec(), whereas the Bourne
shell does not. (optional, suggested: /bin/sh unless you're on HPUX 10.x,
as explained before).
.TP
.I spool
Spool directory, required (suggested: ~/var/mailagent).
.TP
.I statfile
File where statistics should be gathered. If no such file exists, no
statistics will be recorded (suggested: \$spool/mailagent.st).
.TP
.I tofake
Whether or not \fImailagent\fR should fake a To: line into the message
header when it is absent, which will be used for filtering purposes (no
physical alteration of the header occur). It uses Alternate-To: headers if
found, otherwise it assumes the message was send to the user and takes the
value from the \fIuser\fR configuration variable.
(optional, defaults to ON, suggested: ON; turn it OFF only if you want to
identify missing To: lines to detect SPAM).
.TP
.I tome
This optional variable may contain a comma separated list of alternate logins
that are also valid for the user (mail aliases). This is used in vacation
mode to check whether the mail was sent to the user or to a mailing list.
Matching is anchored on the login name, so saying "ro*" will match
both \fIroot\fR and \fIrom\fR.
.TP
.I track
Set to \fIon\fR (case insensitively), this turns on the \fB\-t\fR option
which tracks all the rule matches and the actions on standard output. This
is optional (suggested: OFF).
.TP
.I timezone
The time zone value for environment variable TZ (optional).
.TP
.I tmpdir
Directory for temporary files. Required (suggested: /tmp).
.TP
.I umask
Default umask which is reset by \fImailagent\fR before processing a message.
Assumed to be decimal unless starting with '0' (for octal) or '0x' (for
hexadecimal). The octal format is the easiest way to specify it nonetheless.
(optional, defaults to: 077).
.TP
.I user
Login name of the user who runs mailagent. This sets the value of the
%u macro.
.TP
.I vacation
A flag set to ON or OFF to switch the vacation mode accordingly.
.TP
.I vacfile
The name of the file to be sent back in vacation mode (suggested: ~/.vacation).
.TP
.I vacfixed
When ON, all changes to the vacation file (even locally) by means of the
VACATION command are forbidden. This is useful if you usually have many
customized vacation messages for different people but temporarily want to
force one unique message (optional, defaults to: OFF).
.TP
.I vacperiod
The minimum time elapsed between two vacation messages to a given address
(suggested: 1d).
.PD
'''
.SS "Available Logging Levels"
.PP
The following log levels can be used while running mailagent:
.Ex
0	No logging
1	Major problems only
2	Failed deliveries
3	Successful deliveries
4	Deferred messages
5	Successful filter actions
6	Unusual but benign incidents
7	Informative messages
8	Non-delivery filter actions
9	Mail reception
12	Debug
19	Verbose
20	Lot more verbose
.Ef
'''
.SS "Plugging Mailagent"
.PP
Once you have configured mailagent in a \fI~/.mailagent\fR (where \fI~\fR
stands for your home directory), you must tell \fIsendmail\fR how to invoke it.
This is done by setting a \fI~/.forward\fR file which looks like this (leading
and trailing double quotes are a mandatory part of it):
.Ex
"| exec /users/ram/mail/filter >>/users/ram/.bak 2>&1"
.Ef
This will pipe all your mails to the \fIfilter\fR program, redirecting all
unusual messages to \fI~/.bak\fR. A sample filter shell script may be found in
\fILib/mailagent\fR, as well as a C filter program. On some systems, it may
be necessary to move the '|' character before the leading quote, but don't
try this unless you have no other choice (i.e. only as a last resort).
.PP
It is \fIvery\fR important to redirect error messages to some file within
your home directory. For one thing, that will get you out of trouble if
strange things start to happen, but more to the point, it makes
your \fI.forward\fR file unique. Older \fIsendmail\fR program, in an heroic
attempt to "optimize" delivery, will silently remove duplicate recipients,
and if a recipient has a \fI.forward\fR, its literal content is used in place
of his e-mail address. Therefore, two local recipients with the same
filtering string will be considered as one unique recipient and only one
of them will get the message...
.PP
If your system does not allow shell redirection from within the .forward,
you can use this instead (only supported by the C filter):
.Ex
"| exec /users/ram/mail/filter -o /users/ram/.bak"
.Ef
which in effect redirects \fIstdout\fR and \fIstderr\fR to the specified file
for you, appending data at the end of the file.  If the filter runs setuid or
setgid, you will not be allowed to create the file, nor to append to it
unless the owner of the file is the \fIreal\fR uid invoking the program (for
security reasons).
.PP
Note that the \fI.forward\fR file only pipes the mail to the \fIfilter\fR
program and does not leave any copy in the mailbox. It is up to you to decide
in the rule file whether you want to trash the mail away or leave it in the
mailbox. If you do not have a rule file (i.e. you left a blank entry in your
\fI~/.mailagent\fR, or you named a non-existent file, or your file is simply
empty), don't worry: the default action is to leave the mail in the mailbox.
'''
.SS "Allowed Commands"
.PP
The allowed command file (as specified by the \fIcomfile\fR variable in
your \fI~/.mailagent\fR) contains all the recognized and allowed commands.
The file \fIcommands\fR held in directory \fILib/mailagent\fR should be
copied as-is into your Spool directory.
'''
.SS "Testing Your Installation"
.PP
Now, assuming you have set a proper \fI~/.mailagent\fR file and edited the
configuration section of the \fIfilter\fR, it is time to test your
installation. Make sure your \fI.forward\fR is world readable and that the
\fIfilter\fR has the execution bits set (there is no reason to make the
\fIfilter\fR world readable).
Set a log-level of 20 and disable vacation mode (the \fIvacation\fR entry in the
\fI~/.mailagent\fR should be OFF). Set the name of the rule file to
an empty file (or a non-existing file for that matter).
You are ready to proceed...
.PP
Send yourself a mail and give mailagent time to process your mail. The
subject of the message should be 'test' (in fact, anything but 'Command').
You may want to run a "\fItail -f logfile\fR" to see what's happening. At the
end of the processing, the logfile should contain something like the following
(names of temporaries may \-and will\- of course differ; timestamps have been
removed):
.Ex
got the right to process mail
building default rules
parsing mail
analyzing mail
in mode 'INITIAL' for ALL
selector 'All' on '<1,->', pattern '/^Subject: [Cc]ommand/'
matching '/^Subject: [Cc]ommand/' on 'All' (<1,->) was false
NOTICE no match, leaving in mailbox
XEQ (LEAVE)
starting LEAVE
starting SAVE /usr/spool/mail/ram
LEFT [qm7831] in mailbox
FILTERED [qm7831] from ram (Raphael Manfredi)
mailagent continues
mailagent exits
.Ef
.PP
If you do not get that, there is a problem somewhere. Start by looking at
the \fI~/.bak\fR file (or whatever file the \fI.forward\fR uses to redirect
output of the filter). If you see something like:
.Ex
FATAL no valid queue directory
DUMPED in ~/mbox.filter
.Ef
then it means the \fIqueue\fR parameter in your \fI~/.mailagent\fR does not
point to a valid directory. Your mail has been dumped in an emergency
mailbox.
.PP
The \fI~/.bak\fR file may also contain error messages stating that \fIperl\fR
was not found. In that case, there should be an error message in the logfile:
.Ex
ERROR mailagent failed, [qm7886] left in queue
.Ef
In that case, make sure the mail has correctly been queued in a file
\fIqm7886\fR. The queue will be processed again when another mail arrives
or when the \fImailagent\fR is invoked with \fB\-q\fR (however, to avoid
race conditions, only mails which have remained for a while will be processed).
.PP
Queuing of mail also happens when another \fImailagent\fR is running. If the
logfile says:
.Ex
denied right to process mail
.Ef
then remove the \fIperl.lock\fR file in the Spool directory. Old lock files
are automatically discarded by the \fImailagent\fR anyway (after one hour).
.PP
If none of these occurs, then maybe \fIsendmail\fR did not process your
\fI~/.forward\fR at all or the file has a syntax error.
Check your mailbox, and if your mail
is in there, your \fI.forward\fR has not been processed. Otherwise, ask your
system administrator to check \fIsendmail\fR's logfile. A correct entry would
appear as (with leading timestamps and syslog stamps removed):
.Ex
message-id=<9202041919.AA07882@york.eiffel.com>
from=ram, size=395, class=0, received from local
to="| /york/ram/mail/filter >>/york/ram/.bak 2>&1", delay=00:00:05, stat=Sent
.Ef
.PP
If you still cannot find why the mail was not correctly processed, you should
make sure you normally receive mail by removing (or renaming) your
\fI~/.forward\fR and sending yourself another test mail. Also make sure your
home directory is world readable and "executable".
.PP
If you are using the C filter, make sure it is running on the right platform.
There may be a low-level routing of all your mail to a \fImailhost\fR machine,
responsible for the final delivery, and the filter program will run on that
machine, which may be a different platform than the one you compiled filter on.
Also make sure your home directory is mounted on that machine, or the mail
transport agent will be unable to locate your \fI.forward\fR file, less process
it.
.PP
This kind of centralized mail delivery is good only when a few people have
mail processing hooks (i.e. \fI.forward\fR files piping mail to a program);
otherwise it's better to route mail to each user's workstation or machine,
for local processing, to avoid an excessive workload on the \fImailhost\fR
machine, especially if it is a dedicated NFS server. If you are a system
administrator installing \fImailagent\fR and expect many people to use it,
keep this in mind.
'''
''' O p t i o n s
'''
.SH OPTIONS
There is a limited set of options which may be used when calling the
mailagent directly. Only one special option at a time may be specified.
Invoking mailagent as \fImailqueue\fR is equivalent to using the
\fB\-l\fR option.
.TP 15
.B \-c\fI file\fR
Specify an alternate configuration file (~ substitution occurs). The default
is \fI~/.mailagent\fR.
.TP
.B \-d
The mailagent parses the rule file, compiles the rules and dumps them on the
standard output. This option is mainly used to check the syntax of the
rule file and make sure the rules are what the user really thinks they are.
.TP
\fB\-e\fI rule\fR
This option lets you specify some rules on the command line, which will
override those specified via the ~/.mailagent, if any. There may be as many
\fB\-e\fR as necessary, all the rules being concatenated together as one
happy array, which is then parsed the same way a rule file is. If only \fBone\fR
rule is given and there is no action specified between {...} braces, then
the whole line is enclosed between braces. Hence saying \fI-e 'SAVE foo'\fR
will be understood as \fI-e '{SAVE foo}'\fR, which will always match and
be executed. Using the \fB\-d\fR option in conjunction with this one is a
convenient way to debug a set of rules.
.TP
\fB\-f\fI mailfile\fR
Using \fImailfile\fR as a UNIX-style mailbox (i.e. one where each mail is
preceded by a special From line stating the sender and the date the message
was issued), extract all its messages into the queue and process them as if
they were freshly arrived from the mail delivery subsystem.
.TP
.B \-F
Force processing on already seen messages. Usually, \fImailagent\fR enters
the special \fI_SEEN_\fR mode when it detects an \fIX-Filter:\fR line issued
by itself, but this option will have it continue as usual (although vacation
messages are disabled). Use this option when post-processing mail already
filtered. Also look at the
.B \-U
switch if you are using the RECORD or UNIQUE actions in some rules.
.TP
.B \-h
Print out a usage message on the standard error and exit.
.TP
.B \-i
Interactive mode, directs mailagent to print a copy of all the log messages
on \fIstderr\fR.
.TP
.B \-I
Install a \fI~/.mailagent\fR file from template, or merge new configuration
variables into an existing file; then perform sanity checks and create
mandatory files or directories. This option may be viewed as an help
into setting up \fImailagent\fR's environment. In any case, the
created/merged \fI~/.mailagent\fR file should be manually verified before
letting \fImailagent\fR deal with your mail by hooking it
into \fI~/.forward\fR.
.TP
.B \-l
List the mailagent queue. Recently queued mails which are waited for by the
\fIfilter\fR are \fIskipped\fR for about half an hour, to avoid race conditions.
This may be configured via the \fIqueuehold\fR variable. Really old messages
(more than \fIqueuelost\fR seconds old) are flagged with a '#' character.
Messages out of the queue (\fIqueue\fR variable) are flagged with a '*', whilst
old messages out of the queue are signaled by an '@'. Locked messages have
a '*' appended to their status.
.TP
.B \-L\fI level\fR
Override the log level specified in the configuration file.
.TP
.B \-o\fI override\fR
This option lets you override a specific configuration option. The option must
be followed by a valid configuration line, which will be parsed after the
configuration file itself. For instance, the \fI\-L 4\fR option is completely
equivalent to \fI\-o 'level: 4'\fR. Note that any white space must be protected
against shell interpretation by using the appropriate quoting mechanism. There
may be as many \fB\-o\fR options on the command line as necessary.
.TP
.B \-q
Force processing of mailagent's queue. Only the mails not tagged as
\fIskipped\fR by the \fB\-l\fR option will be processed.
.TP
.B \-r\fI file\fR
Specify an alternate rule file.
.TP
.B \-s {umaryt}
Build a summary of all the statistics gathered so far. The output can be
controlled by appending one or more letters from the set {umaryt}. Using
\fB\-summary\fR is a convenient way to get the whole history of the filter
actions. The \fBu\fR modifier will print only used rules. The \fBm\fR will
merge all the statistics at the end while \fBa\fR reports the mode the
filter was in when the command was executed. The \fBr\fR asks for rule-based
statistics and the \fBy\fR is pretty useless and is here only to get a nice
mnemonic option. Note that specifying an option more than once has no effect
whatsoever on the option itself (i.e. you may put three \fBUu\fR and only
one \fBm\fR, but you'll still get the summary!). The \fBt\fR letter may be
followed by digits specifying how many rule file versions relative to the
topmost (most recent) rule file we should extract from the statistics, that
amount defaulting to 1: using \fB-surat\fR will print a complete statistics
report for the last version of your rules, while \fB-surt12a\fR would do the
same for the last twelve versions of those same rules.
.TP
.B \-t
Put mailagent in a special tracking mode where all the rule matches and
executed actions are printed on the standard output. This is mostly useful
for debugging a rule file. See also the \fItrack\fR parameter in the
configuration file.
.TP
.B \-V
Print version number and exit.
.TP
.B \-U
Prevent the UNIQUE and RECORD commands from rejecting an already processed
Message-ID the first time they are run on a given message.
This is useful when processing messages that have been dropped in the
.I emergdir
directory due to some abnormal (but transient) condition and you wish to
reprocess the message. Also see the
.B \-F
switch if you are re-processing messages.
.PP
If you invoke mailagent without options and without any arguments, the
program waits for a mail on its standard input. If an argument is provided, it
is the name of a file holding one mail to be processed. This is the normal
calling procedure from the filter, the argument being the location of the
queued mail.
'''
''' D e f a u l t   R u l e s
'''
.SH "USING THE DEFAULT RULES"
If you do not want to use the filtering feature of mailagent, then the
default built-in rules will be used. Those are really simple: all the mails
are left in your mailbox and mails with a line "Subject: Command" anywhere in
the message will be processed. Commands are looked for on lines starting with
"@SH". The remaining of the line is then given to a shell for execution.
.PP
Available commands are read from a file (entry \fIcomfile\fR in your
configuration file), one command name per line. Only those listed there will
be executed, others will produce an error message. The mailagent traps
the exit status and will send an error report if a command fails (provided
that the command does not issue a message by itself, in which case it
should return a zero exit status).
.PP
If you do not want to use the default rules, you may skip the remaining of this
section.
'''
.SS "Configuring Help"
.PP
The help text mailagent will send to people must be copied from
\fILib/mailagent/agenthelp\fR into your own spool directory, as specified in your
\fI~/.mailagent\fR. Two macros may be used:
.TP 10
.I =DEST=
This will be expanded to the sender's address (the one who sent you
the mail currently processed by mailagent).
.TP
.I =MAXSIZE=
This stands for the maximum size set before \fIkit\fR is used to send
files back (parameter \fImaxsize\fR in your \fI~/.mailagent\fR file\fR).
.PP
You may use the default help file or design one that will give even more
details to the poor user.
'''
.SS "Distribution Files"
.PP
The two files \fIproglist\fR and \fIdistribs\fR held in \fILib/mailagent\fR
describe the distributions your mailagent will be able to distribute.
The samples given show the expected syntax. In order to clarify things,
here is what the format should be:
.PP
File \fIproglist\fR contains a small description for programs. The name
of the program appears after a single star. It is followed by lines in
free format. An optional three-dashes line separates each program's
description. Note that a leading tab will be added to each line
of description.
.PP
The \fIdistribs\fR file holds lines of the following form:
.Ex
\fIprogname version path archived compressed patches\fR
.Ef
where:
.TP 10
.I progname
is the program name (the same as the one mentioned in \fIproglist\fR).
.TP
.I version
is the current version number. If none, a three-dashed line may be used.
.TP
.I path
is the path where the distribution is stored. The ~ will be expanded into
your home directory. Note that if the distribution is stored in archived
form, the path name is the one of the archive without the ending
extension (which may be \fI.cpio.Z\fR or \fI.tar.Z\fR).
.TP
.I archived
is either \fIy\fR or \fIn\fR depending on whether the distribution is
archived or not.
.TP
.I compressed
is either \fIy\fR or \fIn\fR depending on whether the distribution is
compressed or not. This could be guessed from the extension's name, but
we must think of file systems with short names.
.TP
.I patches
is \fIy\fR or \fIn\fR depending on whether the distribution is
maintained or not by you. If you put a \fIp\fR, this means official
patches are available, although you do not maintain the distribution.
Finally, an \fIo\fR means that this is an old version, where only patches
are available, but maildist will not work. In that case, assuming the
version number is \fI1.0\fR, old patches are expected in a \fIbugs-1.0\fR
directory.
.PP
You may include comments in both files: all lines starting with a leading
# will be ignored.
'''
.SS "Testing Your Mail Agent"
.PP
It is now time to make sure your mailagent works. Send yourself the following
mail:
.Ex
Subject: Command
@SH mailhelp
.Ef
You should receive back a mail from yourself with the subject set to:
"How to use my mailagent". If you don't, check the file \fI~/.bak\fR
(or whatever file you set in your \fI.forward\fR). If it is empty, look
at the log file. If the log file is not empty, then perhaps the mail
has been queued. Check the \fIsendmail\fR queue. Also make sure that
you removed the '#' comments in the \fIfilter\fR script. On some systems,
they cause some trouble. If you are using the C filter, maybe your sendmail
is broken and you need to make your own setuid copy (or perl might complain
that you have a kernel bug, etc...).
.PP
If you have done everything right but it still does not work properly,
increase log level to 20 and resend your command mail. Then check the
log file. The diagnosis should be easier.
.PP
Once this works, you should check your \fIdistribs\fR and \fIproglist\fR
files by sending yourself the following mail:
.Ex
Subject: Command
@SH maillist
.Ef
If the list you have in return is incorrect, then your distribution files
are wrongly written. If you do not get the list, there is a problem with
your mailagent's configuration. Retry with a log level set to 20 and look
at the issued log messages in your Log directory. Make sure that the file
listed in the \fIplsave\fR entry of your \fI~/.mailagent\fR is correctly
updated after a \fImaillist\fR has been run.
'''
''' F i l t e r i n g   R u l e s
'''
.SH "USING THE FILTER"
The \fImailagent\fR can also be used as a filter: mail is parsed and some
actions are taken based on simple \fIlex\fR-like rules. Actions range from
a simple saving in a folder, a forwarding to another person, or even spawning
of a shell command. Before going further, here is a small example of a valid
rule file:
.Ex
From: root { FORWARD postmaster };
To: gue@eiffel.fr { POST mail.gue };
Subject: /metaconfig/ { SAVE dist };
.Ef
There are three distinct rules. Rules are applied in sequence, until one
matches (so the order is important). Any mail coming from \fIroot\fR will be
forwarded to user \fIpostmaster\fR. A mail addressed to \fIgue@eiffel.fr\fR is
a mail coming from a mailing list. The mail is posted on a local newsgroup
\fImail.gue\fR. Mails whose subject contains the word "metaconfig" will be
saved in a folder \fIdist\fR for delayed reading and will not appear in the
main mailbox. If no rule matched, the mail is left in the mailbox.
'''
.SS "Rule File Syntax"
.PP
Here is a non-formal description of the rule file. Parsing of the file is done
lexically, hence the choice of non-ambiguous tokens like '{' or ';' which are
easily parsed. This introduces some limitations which are silently applied:
for instance, no '{' may be used as part of an address.
.PP
Comments are introduced by a leading '#' , which must be on the left margin.
Unlike shell comments, a '#' which is not left justified will not be understood
as a comment. However, spaces or tabs are allowed in front of '#'.
.PP
All the statements in the rule file must end with a ';'. There are mainly
four parts in each line. A list of comma separated modes, between '<' and '>',
which give the set of modes in which the rule applies. The special mode
ALL will match everything. The filter begins in the mode INITIAL. Omitting the
mode defaults to "<ALL>". It is possible to guard a rule against some
specific mode by negating it, which is done by prefixing the mode with '!'.
Negated modes take precedence other plain modes, meaning "<!ALL>" will never
be matched, ever, and that "<MODE, !MODE>" is equivalent to "<!MODE>".
.PP
Then comes a list of selectors. Those selectors must be space separated and end
with ':'. They represent the names of header fields which must be looked at
by the forthcoming pattern. An empty selector list defaults to "Subject:".
Special selectors "All:", "Body:" and "Head:" apply to the whole message,
its body or its header. A commonly used selector list is "To Cc:" which tests
the recipient fields of the header. If the selector name is preceded by an
exclamation mark '!', then the logical value of the test for that selector is
negated.
.PP
The list of selectors may end with an optional range specification, given as
\fI<min, max>\fR, before the final ':' character marking the end of the
selector list. The minimum or the maximum may be given as '-', in which case
it is replaced with the minimal or maximal possible value. Indices for
selection begin at 1 (not 0), for instance: \fI<3, 7>\fR. If no range selection
is given, then the default \fI<1, ->\fR is used. Ranges normally select lines
within the matching buffer, unless the selector is expecting a list in which
case it operates on the list items. For instance, \fIBody <3, 5>:\fR would
select lines #3 to #5 (included) from the mail body, whereas \fITo Cc <1,3>:\fR
would focus on the first three addresses on each To: or Cc: header lines.
Negative values refer to that many lines or addresses back from the end, i.e.
\fICc <-2,->:\fR selects the last two addresses on the Cc: line.
A single number such as \fI<2>\fR is understood as \fI<2, 2>\fR, i.e. it
select only one item in the list, \fI<->\fR meaning everything (and being
therefore redundant).
.PP
The selector is then followed by a pattern within '/' or by a single name.
In order to ease the writing of the rules, the semantic of a single name varies
depending on the selector used. For the special selectors "From:", "To:", "Cc:",
"Sender:", their associated "Resent-" fields, "Reply-To:", "Envelope:"
and "Apparently-To:", a single name is understood as a match on the \fIlogin
name\fR of the address. Note that if no "To:" field is present in the header,
one will be forged from the "Apparently-To:" for the purpose of filtering only
(i.e. no physical modification on the header is done). If the login name of
the address is a full name of the form First.Last, only the last name is
kept, and is lower-cased. If only a single name is given, only shell
metacharacters * and ? are allowed, as well as intervals [].
.PP
If the pattern is preceded by a single exclamation mark '!', then the
matching status is negated (i.e. it will succeed if the pattern is not found).
If a single word
is used for non-special selectors, the same rules apply but the pattern is
anchored at the beginning and the end for an exact match. With a pattern
starting with '/', any regular expression understood by \fIperl\fR may be
used and your pattern will not be modified in any way. The other special
selector "Newsgroups:" works as "To:", excepted that newsgroups names are
expected and a match is attempted on every item in the list. Every pattern
match on a single name for an address-type field (i.e. "Newsgroups:" excluded),
are made in case-insensitive mode. Otherwise, you can force a case-insensitive
match by appending a trailing \fIi\fR option, as in \fI/pattern/i\fR.
.PP
There is also a little magic involved when matching on an address field. Namely,
if the pattern is not a single word and is \fIanchored at the beginning\fR,
then only the address part of the field will be kept. For instance, if we
have a From: field whose value is \fIRaphael Manfredi <ram@eiffel.com>\fR, then
the pattern \fI/Raphael/\fR would match, but not \fI/^Raphael/\fR. Instead,
\fI/^ram@.*$/\fR would match, but this is more easily done with a single word
pattern \fIram\fR, for it only focuses on the login name of the address and
would also match if the address was written as \fIeiffel.com!ram\fR.  A single
address in Internet form, as in \fIram@eiffel.com\fR is implicitely matching
on the address part of the field, and you must not escape the '.' as you
would have to in a regular expression.
.PP
This may sound a little complex, but this design is meant to make things
easier for the user. Here are some other examples:
.Ex
# Match \fIram@eiffel.com\fR as well as \fIram@educ.emse.fr\fR.
From: ram

# Match \fIroot@eiffel.com\fR, \fIram\fR but not \fIribbon@eiffel.com\fR
From: r[oa]*

# Match \fIgue@eiffel.fr\fR but not \fIalgue@eiffel.fr\fR
To Cc: gue@eiffel.fr

# This will match \fIgue@eiffel.fr\fR as well as \fIalgue@eiffel.com\fR
To Cc: /gue@eiffel/

# Match \fIcomp.lang.perl\fR but not \fIcomp.lang.perl.poetry\fR (?)
Newsgroups: comp.lang.perl

# Accept anything but messages coming from \fIroot\fR
From: !root
.Ef
When attempting a match on "To:", "Cc:" or "Apparently-To:", a
list of addresses separated by a comma is expected, whereas only one
address is expected after "From:". If you omit the pattern, it will be
understood as * (recall that a single word uses shell meta-characters), which
will match anything.
.PP
Then comes the action to be taken when a match occurs. There are only a
limited set of valid actions which will be described soon in detail. The
action is enclosed in curly braces '{' and '}' and actions are separated or
terminated (depending on your taste) by a ';'. Action names are spelled in
upper-case for readability, but case is irrelevant. If you want to put a ';'
within the rule, it must be escaped by preceding it with a backslash.
A double backslash is translated into a single one, and any other escape
sequence involving the backslash character is ignored (i.e. \\\\n would
be kept verbatim).
.PP
Note that a rule should
be ended by a single ';' after the last '}'. It is possible to omit this
final ';', but that single token is the re-synchronizing point for error
recovery. One could argue however that there should be no syntax error, and
thus the ';' ought to be safely omitted. Whenever in doubt, check your rule
file with the \fB\-d\fR option.
.PP
Here is a prototypical rule (using \fIperl\fR regular expressions; please refer
to the subsection \fBRegular Expressions\fR for more information):
.Ex
<ROOT> From: /^\\\\w+@eiffel.com$/ { SAVE eiffel };
.Ef
That rule will only be taken into account when the filter is in the mode ROOT
(recall that the processing starts in mode INITIAL; use BEGIN to change the
mode, as in \fIlex\fR). So in mode ROOT, anything which comes from a user
located in the \fIeiffel.com\fR site is saved in folder \fIeiffel\fR for
deferred reading. The mail will not appear in the mailbox.
.PP
It is possible to have more than one selection for a rule. Identical selectors
are logically \fIor\fR'ed while different ones are \fIand\fR'ed. The selections
are comma separated. For instance,
.Ex
From: root, To: ram, From: ram, Subject: /\\\\btest\\\\b/ { DELETE };
.Ef
will delete a mail from \fIroot\fR or \fIram\fR if it is sent to \fIram\fR
and has the word \fItest\fR in its subject. It is also possible to write the
previous rule as:
.Ex
From: root, ram, To: ram, Subject: /\\\\btest\\\\b/ { DELETE };
.Ef
because if no selector is given, the previous one is used (with the first
selector being "Subject:" by default).
.PP
Anywhere in the rule file, it is possible to define some variables. The list
of recognized variables is given later. For now, let's say that \fImaildir\fR
is the default folder directory. This variable is used by the SAVE command
when the argument is not an absolute path. Setting
.Ex
maildir = ~/mail;
.Ef
will direct the filter to use \fI~/mail\fR as the folder directory (default is
\fI~/Mail\fR). Note the ~ substitution and the final ';'. It is not possible
(currently) to modify the environment by setting PATH for instance.
.PP
Finally, there is a special construct to load patterns from a file. A pattern
enclosed in double quotes means that the patterns to be applied should be
taken from the specified file. The file is expected to be in the directory
\fImailfilter\fR if it is not an absolute path (~ substitution occurs). If
the variable is not set \fImaildir\fR will be used. If by chance (!)
\fImaildir\fR is not set either, the home directory is used. The file should
contain one pattern per line, shell comments (#) being allowed at the beginning
of each line.
.PP
An action may be followed by other rules. Hence the following is perfectly
valid:
.Ex
From:
	ram		{ SAVE ram }
	/plc/i		{ SAVE plc }
	root		{ SAVE ~/admin }
	/xyz/		{ DELETE }
	"users"		{ LEAVE }
	;
.Ef
Note the use of the file inclusion: all the users listed in file \fIusers\fR
will have their mail left in the system mailbox. The usual rules apply for
these loaded patterns.
'''
.SS "Selector Combination"
.PP
A single rule may have a various set of selectors. For instance, in the
following rule:
.Ex
From: ram, To Cc: root, !Subject: /test/, From: raphael
.Ef
we have the following set { From, To Cc, !Subject }. The first two selectors
are called \fIdirect\fR selectors, !Subject: is called a \fInegated\fR selector.
The To Cc: selector is a \fIgroup\fR selector decomposing into two \fIdirect\fR
selectors, while From: is an \fIatomic\fR selector. Finally, From: is also
a selector with \fImultiple\fR occurrences. The \fIvalue\fR of a selector is
its matching status logical value.
.PP
Let \fID\fR be the set of direct selectors and \fIN\fR the set of
negated selectors, which form a partition of \fIR\fR, the set of all the
selectors in the rule. That is to say, \fIR\fR is the union of \fID\fR
and \fIN\fR, and \fID\fR intersected with \fIN\fR is the empty set
(trivial proof: a selector is either direct or negated). If either \fID\fR
or \fIN\fR is empty, then it's not a partition but in that case we have
either \fID\fR = \fIR\fR or else \fIN\fR = \fIR\fR.
.PP
Let's define the logical value of a set \fIS\fR as being the logical
value the filter would return if those rules were actually written.
Then the logical value of \fID\fR is the logical value of each of its item
with the AND logical operator distributed among them, i.e. the logical
value of { a, b, c } is the value of (a AND b AND c). Let's write it
AND(\fID\fR). The logical value of each of the items is the logical value of
the selector itself if it is not multiple, or it is the logical value of
all the occurrences of the multiple selector within the rule, with the
logical OR operation distributed among them. That is to say, in the
above example, the value of From is true iff the From: fields contains
\fIram\fR OR \fIraphael\fR.  Let's write that OR[From].
.PP
To be sound, we have to apply De Morgan's Law on \fIN\fR, hence the following
rules: the logical value of \fIN\fR is OR(\fIN\fR) and given a negated selector
\fIs\fR, its logical value is AND[\fIs\fR]. And finally, the logical value of
\fIR\fR is that of \fID\fR AND \fIN\fR, with by convention having the logical
value of the empty set be \fItrue\fR.
.PP
For those who do not know De Morgan's Law, here it is: given two logical
propositions \fIp\fR and \fIq\fR, then the following identities occur:
.Ex
NOT (p AND q) <=> (NOT p) OR (NOT q)
NOT (p OR q) <=> (NOT p) AND (NOT q)
.Ef
While we are in the logic of the propositions,
note also that OR and AND are mutually distributive, that is to say, given
three logical propositions \fIp\fR, \fIq\fR and \fIr\fR, we have:
.Ex
p AND (q OR r) <=> (p AND q) OR (p AND r)
p OR (q AND r) <=> (p OR q) AND (p OR r)
.Ef
To be complete, OR and AND are associative with themselves and commutative.
And the \fIB\fR set { 0, 1 } equipped with the set of operations (NOT, OR, AND)
is an \fIalgebra\fR (a Boolean one). I will spare you the definition of an
algebra, which really has nothing to do in this manual page (which is for a
mail agent, in case you don't remember :-).
.PP
The attentive reader will certainly have noted that I have not specified
the logical value of a group selector. Well, given a group selector \fIG\fR,
we decompose it into a \fIDG\fR and \fING\fR partition, \fIDG\fR being the
subset of (atomic) direct selectors of \fIG\fR and \fING\fR being the subset of
(atomic) negated selectors.  Then the logical value of \fIDG\fR is
OR(\fIDG\fR) and the logical value of \fING\fR is AND(\fING\fR);
the global logical value of \fIG\fR being that of \fIDG\fR OR \fING\fR.
In case either \fIDG\fR or \fING\fR is empty, then we don't have a partition,
but by convention the value of the empty set is \fIfalse\fR, and one of the
sets is equal to \fIG\fR.
Note that within a group selector, the rules are exactly the dual of the
rules within \fIR\fR.
.PP
Now the only rule which is not \fIlogical\fR is whether a group selector
belongs to \fID\fR or \fIN\fR. I've chosen, for analogy reasons, to make the
group selector belong to \fID\fR if it does not start by '!' and to \fIN\fR
otherwise. That is, !To Cc: belongs to \fIN\fR whilst Cc !To: belongs to
\fID\fR. Apart from that, order within the group selector is irrelevant:
To Cc: is equivalent to Cc To:, so the behavior in the quotient set is sound.
.PP
Here are some examples:
.Ex
# Match anything: (not from ram OR not from root) is always true.
From: !ram, !root

# Match anything but reject mails coming from ram OR root
!From: ram, root

# Reject mails whose headers matching /^Re.*/ contain the word test
!^Re.*: /\\\\btest\\\\b/

# Keep mails whose subject contains \fItest\fR AND \fIhost\fR
!Subject: !/test/, !/host/

# Matches if \fIram\fR is listed in the \fITo\fR OR the \fICc\fR line
To Cc: ram
.Ef
'''
.SS "Minimal Header"
.PP
A minimal set of selectors are guaranteed to be set, regardless of the
actual header of the message. This is for the purpose of filtering only,
no physical alteration is performed.
.sp
.PD 0
.TP 10
.I Envelope:
This is the address found in the mail envelope, i.e. the address where the
mail seems to originate from. This can be different from the \fIFrom:\fR
address field if the mail originates from a \fItrusted\fR user, in sendmail's
terminology. If you don't know what that is, simply ignore it.
.TP
.I From:
User who wrote the mail. If this line is missing, uses the address found in
the first From line.
.TP
.I To:
The main recipient(s) of the message. If this line is missing but a set of
\fIApparently-To:\fR lines is found, then those addresses are used instead. If
no such line exists, then assume the mail was directed to the user (which
seems a reasonable assumption :-).
.TP
.I Sender:
User who sent the mail. This may differ from the \fIFrom:\fR line. If no
such field exists, then the address in the first From line is used (mail
envelope).
.TP
.I Relayed:
This computed header is a comma-separated list of all the hosts where
the message was relayed, in the proper transmission order. Each item in
this list can be a machine name such as \fImail.hp.com\fR or an IP address
such as \fI[15.125.38.12]\fR. The list is derived from the \fIReceived:\fR
lines present in the message.
.TP
.I Reply-To:
Where any reply should be sent. If no \fIReply-To:\fR field is present, then
the \fIReturn-Path\fR is used (with <> stripped out), or the \fIFrom:\fR
line is parsed to extract the e-mail address of the author.
.PD
'''
.SS "Variables"
.PP
The mailagent supports user-defined variables, which are globals. They are
set via the ASSIGN command and referred to with the %# macro. Assuming we
set a variable \fIhost\fR, then %#\fIhost\fR would be replaced by the actual
value of the variable. This enables some variable propagation across the rules.
.PP
For example, let's say the user receives cron outputs from various machines
and wishes to save them on a per-machine basis, differentiating between
daily outputs and weekly ones. Here is a solution:
.Ex
Subject: /output for host (\\\\w+)/	{ ASSIGN host '%1'; REJECT };
Subject: /^Daily output/	{ SAVE %#host/daily.%D };
Subject: /^Weekly output/	{ SAVE %#host/weekly.%m-%d };
.Ef
Besides variable interpolation via the %# escape, it is also possible to
perform substitutions and translations on the content of a variable (or a
back-reference, i.e. a number between 1 and 99). The two commands SUBST and
TR will respectively perform in-place substitutions and translations. In that
case however, the name of the variable must be preceded by a single #. This
differentiates the back-reference \fI1\fR from the variable \fI#1\fR, although
\fI1\fR is a funny name for a variable. The need for # also prevents the
common mistake of writing %#, as mailagent will loudly complain if the
first parameter of SUBST or TR is not a digit between 1 and 99 or does not
start with a #.
.PP
Here are some actions to canonicalize the host name into lower case and
strip down the domain name, if any:
.Ex
{ TR #host /A-Z/a-z/; SUBST #host /^([^.]*)\\\\..*/\$1/ };
.Ef
Those actions are directly translated into their \fIperl\fR equivalent, and
any error in the specification of the regular expression will be reported.
.PP
If the variable name begins with a colon ':', then the variable is made
persistent. That is to say it will keep its value across different mailagent
invocations. The variable is simply stored (with the leading ':' removed) in
mailagent's database and is thus subject to the aging policy set up in
the ~/.mailagent.
.PP
Within PERL commands or mail hooks using perl (see the MAIL HOOKS section),
you can manipulate those (so-called) external variables via a set of
interface functions located in the \fIextern\fR package (i.e. you must
prefix each of the function name with its package name, \fIset\fR becoming
\fIextern'set\fR). The following three interface functions are provided:
.PD
.TP 10
val(name)
Return the value of the variable \fIname\fR (the leading ':' is not part of the
name, in any of these three interface functions).
.TP
set(name, value)
Set the external variable \fIname\fR to hold \fIvalue\fR. No interpretation
is done by the function on the actual content of the \fIvalue\fR you are
providing.
.TP
age(name)
Returns the age of the variable, i.e. the elapsed time in seconds since the
last modification made by \fIset\fR.
.PP
There is currently no way for erasing a variable from the database. But if
you do not use the variable any more, it will be removed when its age
becomes greater than the maximum age specified by the \fIagemax\fR configuration
variable.
'''
.SS "Regular Expressions"
.PP
All the regular expressions follow the V8 syntax, as in \fIperl\fR, with all
the \fIperl\fR extensions. If a bracketing construct (...) is used inside a
rule, then the %\fIdigit\fR macro matches the \fIdigit\fR's substring held
inside the bracket. All those back-references are memorized on a per-rule basis,
numbered from left to right. However, great care must be taken when using
a back-reference in multiply present selectors, as all the matches will be
performed up-to the first match, and back-references are computed on the fly
while doing pattern matching.
.PP
For instance:
.Ex
To: /(.*)/, Subject: /Output from (\\\\w+)/ { ASSIGN to '%1'; SAVE %2 };
.Ef
will save the To: field in variable 'to' and save the mail in a folder derived
from the host name specified in the subject. However, if we say:
.Ex
Subject: /host (\\\\w+)/, /from (\\\\w+)/ { ASSIGN match '%1' };
.Ef
then there will be only one back-reference set, and it will come from the first
pattern matching if it succeeds, or from the second. Should the second or
the first pattern have no bracketing construct and still match, then the
back-reference would not be recorded at all, which means the following is
probably not what you want:
.Ex
Subject: /from/, /host (\\\\w+)/, To: /(.*)/ { SAVE %1; REJECT };
.Ef
as if the /from/ pattern matches then /host (\\\\w+)/ will not be checked
(identical selectors are \fIor\fR'ed and that is optimized), then %1 would refer
to the To: field whereas if /host (\\\\w+)/ matches, then %1 will be the host
name.
.PP
However, this behavior can be used to selectively store a news article
which has been mailed to you in a folder whose name is the newsgroup name
in dot form. Assuming we want to give priority to comp.lang.perl, we
could say:
.Ex
Newsgroups:
	/(comp.lang.perl)/,
	/(comp.mail.mh)/,
	/(comp.compilers)/,
	/([^,]*)/		{ SAVE %1 };
.Ef
An article cross-posted to both comp.lang.perl and comp.mail.mh would
be saved in a comp.lang.perl folder, since this is what would match first.
The last rules takes care of other articles: the folder used being
whatever newsgroup appears first.
.PP
There is also a special macro %&, which lists (it's a comma separated list)
all the selectors specified via a regular expression which indeed matched.
For instance:
.Ex
Re.*: /york/		{ ASSIGN which '%&' };
.Ef
would assign to \fIwhich\fR the list of all the fields matching the /Re.*/
pattern which contained 'york', be it a Received: field or a Resent-From:
field (as both match the selector specification). Assuming both those fields
contained the word \fIyork\fR, the value of %& would be 'Received,Resent-From;'
(the fields are alphabetically sorted).
.PP
Should you have more than one such specified selector within a single rule,
then it might be worth knowing that all the set of matching selectors are
recorded within %&, each set terminated with a ';'. If a negated selector is
used, then %& will record all the fields which did not contain the pattern,
assuming the selection succeeded (otherwise nothing is recorded).
'''
.SS "Available Actions"
.PP
The following actions are available as filtering commands. Case is irrelevant
although the recommended style is to spell them upper-cased. As explained
later, most of the actions record their exit status in a special variable
which may be tested via the \fB\-t\fR and \fB\-f\fR options of ABORT, REJECT
and RESTART. For every command returning such an exit status, the failure
or success conditions are given at the end of each description. If nothing is
specified, then the command does not return a meaningful status.
.TP 10
ABORT [\fB\-tf\fR] [\fImode\fR]
Abort application of filtering rules immediately. See REJECT for the meaning
of the optional parameters. (Does not modify existing status)
.TP
AFTER [\fB\-sanc\fR] \fI(time) action\fR
Records a callback for after the specified \fItime\fR, where \fIaction\fR will
be performed. By default, a mailagent filtering action is assumed (\fB\-a\fR
option), on the current mail message. A shell command (\fB\-c\fR) may be
given instead, receiving the current mail message as standard input. Finally,
a plain shell command may be run (with no input) using the \fB\-s\fR option.
The option \fB-n\fR may be used when the current mail message does not need
to be kept for input. For instance:
.Ex
AFTER \fB\-an\fR (1 day) DO ~/process:proc'run(%u)
.Ef
would call \fIproc'run\fR defined in the \fI~/process\fR file in one day
from now, without giving any input (the action here does not require any).
.sp
When running mailagent commands, the initial working mode is set to
_CALLOUT_. This may matter if you call APPLY for instance. If the recorded
time is less or equal than the current time (which is \fInow\fR), the callback
will occur when mailagent is done with the messages in its queue, before
exiting. This allows for the following cute trick, found out by Randal Schwartz:
.Ex
AFTER (now)		# fork a copy I can mangle
	STRIP Reply-To \\\\; RESYNC \\\\;
	ANNOTATE -du Reply-To %2 \\\\; RESYNC \\\\;
	NOTIFY message %r \\\\; DELETE \\\\;
	;
.Ef
Note that the command is not called \fIAT\fR because the call will only
be performed at the next mailagent invocation after the specified time has
elapsed. Dates are specified using the same format as in SELECT.
(Fails if the action cannot be recorded in the callout queue).
.TP
ANNOTATE [\fB\-du\fR] \fIfield value\fR
Annotate message by adding \fIfield\fR into the mail header, with the
supplied \fIvalue\fR. This is like the MH command \fIanno\fR, but the
annotation is performed at the end of the header, whereas MH does it at the
top. Normally, an extra \fIfield\fR is added, with the current date as
field value.
.sp
This can be suppressed by using the \fB\-d\fR option. If
\fIvalue\fR is omitted, only the date field is generated (hence it is an
error to use the \fB\-d\fR option without supplying a \fIvalue\fR). As with
all the commands which alter the header, a RESYNC is necessary for the filter
part to actually see the new header.
.sp
The \fB\-u\fR option means "unique", and prevents ANNOTATE from executing
if the specified \fIfield\fR is already present in the header. Don't forget
to RESYNC between successive ANNOTATE commands using this option if
the \fIfield\fR refers to a previous ANNOTATE target.
(Fails when no annotation takes place)
.TP
APPLY \fIrulefile\fR
Get the rules held in \fIrulefile\fR and apply them to the current message.
The filter will begin in whatever mode you were when using this command,
but no feed back will occur, i.e. any mode changing will be lost when
returning from the command.
.sp
Variables (see the %# macro) are propagated back and forth through APPLY,
meaning you see variables set by the caller, and you may change their
values or create new variables for the caller to later use.
.sp
If mail is saved during the application of
the rules, then the corresponding flag is set in the main filter (the one
that started the APPLY command). You may nest them, of course.
(Fails if mail is not saved by the rules held in \fIrulefile\fR)
.TP
ASSIGN \fIvar value\fR
Assign the value to the user-defined variable \fIvar\fR, which may further be
accessed as \fI%#var\fR for macro substitution or \fI#var\fR in the TR and
SUBST commands in place of the variable name. Note that there is no leading
\fI#\fR in front of the variable name. The \fIvalue\fR you provide is first
ran through \fIperl\fR to see if it contains some arithmetic operations. If the
evaluation is successful, the resulting value is used instead. If an error
occurs in this evaluation process, then the literal value provided is used.
To avoid the evaluation, you may enclose the whole value in simple quotes. Those
will be trimmed before the assignment takes place. If you actually want simple
quotes in the first AND last position, you have to double each of them.
(Does not modify existing status)
.TP
BACK \fIcommand\fR
Execute \fIcommand\fR and take its output as new actions to be performed on
the mail (hence performing something analogous to \fI\`command\`\fR in shell).
If there is no output, nothing is done. BACK commands can be nested, although
this may lead to surprises this manpage will not disclose (but I assure you
it will be funny, assuming we have the same sense of humor... :-). Note that
both the standard output and the standard error from the command are used.
.sp
If the command fails, the output is mailed back to the user and no action is
performed. Furthermore, normal feedback does not occur here: any output from
the command is taken as filter actions, which means the semantics of PASS,
for instance, is changed: we do not take a body back but commands.
(The execution status is that of the \fIcommand\fR)
.TP
BEEP [\fB\-l\fR] \fIcount\fR
This command may be used to tune the amount of beeps emitted when biffing on
the terminal, for each \fI%a\fR expansion. By default, that amount is set to 1.
Using the \fB\-l\fR option alters the beep count locally for the rule.
Otherwise, the default amount is changed.
.sp
Note that this simply expands %a into the suitable amount of Ctrl-G characters.
Your terminal must be allowed to issue consecutive bells for this to work.
Very often, terminals are configured so that the first bell received disables
further beeps for some period, to avoid cascades of bells.
If you use \fIxterm\fR for instance, you should use:
.Ex
xterm -xrm "XTerm*BellSuppressTime: 0"
.Ef
to enable consecutive bells. Otherwise, \fIxterm\fR will swallow them during
200 ms, hence making the BEEP command ineffective, apparently.
(Does not modify existing status)
.TP
BEGIN [\fB\-ft\fR] \fIstate\fR
Enter a new state. An explicit REJECT or RESTART is necessary to abort the
processing of the current rule. The processing begins in state INITIAL.
If the \fB\-f\fR (resp. \fB\-t\fR) flag is specified, then the state change
only occurs if the last command status indicated a failure (resp. a success).
(Does not modify existing status)
.TP
BIFF [\fB\-l\fR] \fIon|off|path\fR
Allow or disallow biffing dynamically. When biffing is turned on via the
configuration file or via this command, a message is printed on some of
the terminals where the user is logged when mail is received,
as explained under the section \fBMAIL BIFFING\fR.
.sp
Instead of \fIon\fR or \fIoff\fR, you can specify a file name (~ substitution
allowed) being the new path to be used for the biffing format template.
.sp
If you use the \fB\-l\fR option, changes are made locally, for the duration of
the rule only. If you REJECT to go to some other rule, your changes will be
lost. The global value of the altered parameters is changed on the first local
usage and restored when a new rule is entered.
(Does not alter execution status)
.TP
BOUNCE \fIaddress(es)\fR
Bounce the message to the specified address(es) and acts as if a save had
been done. The only difference with FORWARD is that no Resent-like lines are
added to the header. If an address is specified in double quotes, it is taken
as the name of a file to be loaded to get addresses (one address per line, shell
comments (#) allowed). The file name resolving is the same as the one used
for pattern loading.
(Fails if mail cannot be resent)
.TP
DO \fIroutine\fR [\fI(arg1, arg2, ... , argn)\fR]
Calls the perl \fIroutine\fR, with the supplied arguments if any. This is a
very low level hook into \fImailagent's\fR internal. The routine can be
specified by itself (\fIpackage'name\fR, \fIpackage\fR being \fImain\fR by
default), or identified by a leading \fItag\fR, followed by a ':', then the
routine name as before. The \fItag\fR can be a path to a file where the routine
is defined, or a command name (for user-defined commands which are loaded
dynamically). For instance
.Ex
DO UNKIT:newcmd'unkit('true')
.Ef
would lookup
the user-defined \fIUNKIT\fR command, load the file where it is defined (in the
\fInewcmd\fR package), then call the routine with \fI'true'\fR as argument.
The \fIpackage\fR specified determines where the loading is done, so be sure
it is consistent with the definition in the file where the routine is defined.
(Fails if the routine cannot be located and executed)
.TP
DELETE
Delete the current message. Actually, this does not do anything, it just marks
the mail as saved. If no further action involving saving is done, then the
mail will never show up in the mailbox.
(Never fails)
.TP
FEED \fIprogram\fR
Feed the whole message to a program and get the output back as the new
message. The header structure used by the rules is not updated: an explicit
RESYNC is necessary. Hence the program appears as a filter for the whole
message.
(Returns the status of \fIprogram\fR)
.TP
FORWARD \fIaddress(es)\fR
Forward mail to the specified address(es). This acts as if a save had been
done, in order to avoid the DELETE. Usually when you forward a mail, you do not
wish to keep it. The command adds Resent-like lines in the header. As for
BOUNCE, file inclusion is possible (i.e. use an address \fI"forward_list"\fR
to forward a mail to all the users listed in the file \fIforward_list\fR).
(Fails if mail cannot be resent)
.TP
GIVE \fIprogram\fR
Give the body of the message to the specified program by feeding its standard
input. Any output is mailed to the user who runs the \fImailagent\fR.
(Returns the status of \fIprogram\fR)
.TP
KEEP \fIheader_fields_list\fR
Keeps only the corresponding lines in the header of the mail. For instance,
a "KEEP From To Cc Subject" will keep only the principal fields from the
mail message. This is suitable for archiving mailing lists messages.
You may add a ':' after each header field name if you wish, but that is not
strictly necessary. Headers may be specified using shell-style regular
expressions, and file inclusion is allowed to get headers from a file.
(Does not modify existing status)
.TP
LEAVE
Leave incoming mail in the system mailbox. This is the default action if no
rule matched or if no saving occurred.
(Fails if mail cannot be saved)
.TP
MACRO [\fB\-rdp\fR] \fIname\fR [= (\fIvalue\fR, \fItype\fR)]
Lets you specify user-defined macros, of the form %-(\fIname\fR). See the
paragraph on user-defined macros for explanation about the available types
(SCALAR, EXPR, CONST, FN, PROG, PROGC).
A perl interface to the underlying user macros is available for your perl
commands. The \fB\-r\fR option is used to replace an existing macro (instead of
pushing a new instance on the stack), the \fB\-d\fR is to delete all the
instances of a named macro (in that case it takes only the first argument),
and \fB\-p\fR pops the last instance of the macro from the stack and reverts
to the previous definition, if any (otherwise, it acts as \fB\-d\fR).
If you wish to define a simple SCALAR macro, you may omit the \fI= (value,
type)\fR part and simply continue with the macro value.
(Does not modify existing status)
.TP
MESSAGE \fIfile\fR
Send message \fIfile\fR back to the sender of the message (as derived from the
header of the message). The text of the message is run through the macro
substitution mechanism (described later on).
(Fails if message cannot be sent)
.TP
NOP [\fB\-ft\fR]
No operation. If this seems a bit odd, think of it in terms of a ONCE command.
(Does not alter existing status unless \fB\-f\fR or \fB\-t\fR is used, in
which case it forces a \fIfalse\fR \-\-failure\-\- or \fItrue\fR success status)
.TP
NOTIFY \fIfile\fR \fIaddress(es)\fR
Send a notification message \fIfile\fR to a given address list. The text of the
message is run through the macro substitution mechanism (described later on).
As with FORWARD, file inclusion for address specification is possible.
(Fails if message cannot be sent)
.TP
ON \fI(day list) command\fR
Execute the specified filter command only on the specified day list. That list
is a space-separated list of days, specified using the English names. Only the
first three characters are taken into account, case-insensitively. Therefore,
the shortest valid day specifications
are \fIMon, Tue, Wed, Thu, Fri, Sat\fR and \fISun\fR.
.sp
This command can be used in conjunction with SELECT to do time-based selective
bouncing of messages to, for instance, your home address:
.Ex
ON (Mon Tue Wed Thu) SELECT (18:30 .. 23:00) BOUNCE me@home.net;
ON (Fri) SELECT (18:30 .. 23:59) BOUNCE me@home.net;
ON (Sat Sun) BOUNCE me@home.net;
.Ef
That would bounce messages only on week-ends and during the week, after
18:30, and until 23:00 (assuming that's bed time, other messages will be
seen at work the next day). Note that on Fridays, we go as far as 23:59.
(Propagates status from \fIcommand\fR. If the command is not executed, always
return success)
.TP
ONCE \fI(name, tag, period) command\fR
Execute the specified filter command once per \fIperiod\fR. The \fIname\fR and
\fItag\fR fields are used to record timestamps of the last ONCE command.
More on this later. (Propagates status from \fIcommand\fR. If the command is
not executed, always return success)
.TP
PASS \fIprogram\fR
Feed the body of the message to the specified program and get a new body
back from the output of the program.
(Returns the status of \fIprogram\fR)
.TP
PERL \fIscript\fR [\fIarguments\fR]
Escape to a perl \fIscript\fR to perform some actions on the message. This
is fully described further in the manpage, and is very different from a
\fIRUN perl script\fR command. (Returns failure if the script did not compile
or returned a non-zero status).
.TP
PIPE \fIprogram\fR
Pipe the whole message to the specified program, but do not get anything
back. Any output is mailed to the user who runs the \fImailagent\fR.
(Returns the status of \fIprogram\fR)
.TP
POST [\fB\-lb\fR] \fInewsgroup(s)\fR
Post the message to the specified newsgroup(s) after having cleaned-up the
header: mail-related fields like Received: or In-Reply-To: are removed, a
valid From: line is generated, the original To: and Cc: are renamed
with an X- prefix, the References: line is updated/generated if necessary
based on existing In-Reply-To, and NNTP-specific fields are stripped so
that the server can add its own.
.sp
Running POST successfully acts as a saving.
.sp
If the first name is \fB\-l\fR as in "POST -l comp.mail.mh",
then a "Distribution: local" header is added to force a local delivery.
Otherwise, the default \fIinews\fR distribution will be used (world,
usually).
.sp
When the \fB-b\fR switch is given, a successful POST will result
in biffing being activated (see section \fBMAIL BIFFING\fR) for
the resulting news article.
.sp
If more than one newsgroup is specified, they should be space
separated. It is possible to get a newsgroup list via file inclusion.
(Fails if message cannot be posted)
.TP
PROCESS
Run the mailagent processing which looks for @SH commands and executes
them. This was described before in the section dealing with default rules.
The action associated by default to a mail having [Cc]ommand as its
subject is PROCESS.
(Always returns success)
.TP
PROTECT [\fB\-lu\fR] \fImode\fR
Sets the default protection mode that should be set on created folders
(or created files when saving into an MH folder or a directory). By default,
permissions are governed by the UMASK command, but this lets you override
the default. The specified \fImode\fR should be preceded by a \fB0\fR as
in \fI0644\fR to give the familiar octal permissions. Otherwise, it is
interpreted as a decimal number, so beware!
.sp
The \fB\-l\fR option may be used to specify a mode locally for one rule.
Otherwise, the protection mode is set globally. The \fB\-u\fR option unsets
the global (or local when combined with \fB-l\fR) mode, reverting to the
default behaviour where only the umask is taken into account by the system.
.sp
Note that when saving into an MH folder, the PROTECT command takes precedence
over the \fIMsg-Protect\fR field from your ~/.mh_profile file.
(Does not alter execution status)
.TP
PURIFY \fIprogram\fR
Feed the header into a program and get new header back. No RESYNC is done.
This may be used to indeed purify the header by removing all the verbose
stuff added by so many mail transport agents (X-400 like lines for instance).
(Returns the status of \fIprogram\fR)
.TP
QUEUE
Queue mail again. A successful queuing counts as if mail had been saved.
Mail queued that way will not be processed during the next 30 minutes. Note
that unless mailagent is invoked on a regular basis by \fIcron\fR, the
mail will remain in the queue until another mail arrives.
(Fails when mail cannot be queued)
.TP
RECORD [\fB\-acr\fR] [\fImode\fR] [\fI(tag-list)\fR]
Record message in the history and enters mode _SEEN_ if the message was
already present there. If the message is recorded for the first time, processing
continues normally. Otherwise a REJECT is performed. This behavior may be
somewhat modified by using some options. See UNIQUE for a complete description
of the options and arguments. Naturally, when a \fImode\fR is specified, that
overrides the default _SEEN_.
.sp
When a \fItag-list\fR (comma-separated list of names) is specified, the message
is only recorded and checked against all those tags, but only them. Not
specifying any tag list means any occurrence, whether it is tagged or not.
See paragraph \fBUsing Tags in Record and Unique\fR for more information.
(Returns a failure status if mail was already recorded)
.TP
REJECT [\fB\-tf\fR] [\fImode\fR]
Abort execution of current action, and continue matching. If \fB\-t\fR is
specified, the reject will occur only if the previous action was successfully
completed (return status of true), whilst \fB\-f\fR would cause the reject only
when a failure occurred. If a \fImode\fR is specified, we enter that mode before
rejection. REJECT resets the matching flag, which means that if no further
match occurs, the default action will apply.
(Does not alter execution status)
.TP
REQUIRE \fIfile\fR [\fIpackage\fR]
Behaves like the perl \fIrequire\fR operator by loading a perl file into
memory. By default, the file is read in the \fInewcmd\fR package, but you
may specify whatever package you wish to load it in. This command will only
perform the loading once per (file, package) tuple. Unlike its perl
equivalent, the file "value" is not important, i.e. it does not have to end
with a statement returning a true value.
(Fails if file cannot be loaded)
.TP
RESTART [\fB\-tf\fR] [\fImode\fR]
Abort execution of current action and restart the matching process from the
beginning. To avoid loops, each rule may be walked through once in a given
mode. See REJECT for the meaning of the optional parameters. RESTART resets
the matching flag, which means that the default action will apply, should
no further match occur.
(Does not alter execution status)
.TP
RESYNC
Re-synchronize header used for matching with the header of the mail. This is
probably useful only when a FEED command was run.
(Does not alter execution status)
.TP
RUN \fIprogram\fR
Run the specified program and mail any output to the user who runs the
\fImailagent\fR.
(Returns the status of \fIprogram\fR)
.TP
SAVE \fIfolder\fR
Save message in the specified folder. If folder name starts with a '+', it is
handled as an MH-style folder and \fIrcvstore\fR is emulated to deliver the
message into that folder. If folder is a directory, message is delivered in
a single file within that directory. See the \fBFOLDERS\fR section.
(Fails if message cannot be saved)
.TP
SELECT (\fIstart .. end\fR) \fIcommand\fR
Execute the \fIcommand\fR only within the time selection period specified.
Dates can be specified in a wide range of formats. The output of the
\fIdate\fR(1) command is an example of a valid specification. If the date,
the year or the month is missing, then the current one is substituted in place
of it. The following dates are valid specifications: '10:04:25', 'now'
,'April 1 1992', 'Dec 25', 'July 14 1789, 07:40' (err... it's valid according
to the grammar, but it's before the Epoch so it does not mean anything). Other
fancy dates like 'last month - 5 minutes' or '3 weeks ago' are also enabled.
(Isn't that great to have a \fBreal\fR parser? The filtering rules could have
been more elaborated if only I had known about this Berkeley \fIyacc\fR
producing a \fIperl\fR parser...).
(Returns the status of \fIcommand\fR, if run, otherwise returns true).
.TP
SERVER [\fB\-t\fR] [\fB\-d \fIdisabled commands\fR]
Activate server processing. The body of the message is interpreted as a list
of commands to execute. See section \fBGENERIC MAIL SERVER\fR for more
information about the server itself. The \fB\-t\fR option turns the server
into \fItrusted mode\fR, where \fIpowers\fR may be gained. The \fB\-d\fR
option must be followed by a list of disabled commands, separated by commas
with no intervening spaces between them.
.TP
SPLIT [\fB\-adeiw\fR] \fIfolder\fR
Split a mail in digest format into the specified folder (same naming
conventions as in SAVE). If no folder is
specified, each digest item is queued and will be analyzed as a single mail
by itself. The \fB\-d\fR option deletes the digest header. The \fB\-i\fR
option means split is done in-place and the original mail is discarded. All the
options may be used simultaneously provided they are stuck together at the
beginning (option parsing being really rudimentary).
.sp
If the mail is not in digest format and a folder is specified, then it is saved
in that folder. Otherwise, the SPLIT action fails and nothing occurs (the
filter continues its processing though). The SPLIT command will correctly
burst RFC-934 digest messages and will try to do its best otherwise. If the
digest was not RFC-934 compliant and there is a chance SPLIT might have
produced something incorrect, then the original message is also saved
if \fB\-i\fR, otherwise it is not tagged as saved (so that the default LEAVE
command may apply). The \fB\-w\fR (watch) requests special care and will detect
every non RFC-934 digest, even when the non-compliance is otherwise harmless;
furthermore, any trailing garbage longer that 100 bytes will be saved as a
digest item by itself.
.sp
The \fB\-a\fR option annotates every digest item with an X-Digest-To: header
line, which is the concatenation of the To: and Cc: fields of the original
digest message. This may be used for instance to burst the digest into the
queue and then re-process each of its items according to this added field.
Finally, the \fB\-e\fR option will discard the digest
header only if its body is empty (i.e. the moderator did not include any
leading comment).
(Returns success if mail was in digest format and correctly split without any
error)
.TP
STORE \fIfolder\fR
Save message in the specified folder and leave a copy in the system mailbox.
The \fIfolder\fR parameter follows the same naming conventions as in SAVE.
(Fails if message cannot be saved either in the \fIfolder\fR or in the mailbox)
.TP
STRIP \fIheader_fields_list\fR
Remove the corresponding lines in the header of the mail. For instance,
a "STRIP Newsgroups Apparently-To" will remove the appropriate lines to wipe
out any Newsgroups: or Apparently-To: header. You may add a ':' after each
header field name if you wish, but that is not strictly necessary. Headers
may be specified via shell-style regular expressions or via "file" inclusion.
(Does not alter execution status)
.TP
SUBST \fIvar/header expression\fR
Substitutes the expression on the specified user-defined variable (name
starting with a #) or back-reference (digit), or header field (optionally
ending with ':').  For instance
.Ex
SUBST #foo /w/y/g
.Ef
would substitute in user-defined variable \fIfoo\fR all the \fIw\fR by \fIy\fR.
See also ASSIGN and TR.

For substitutions on header fields, like:
.Ex
SUBST Subject: /\\\\[foo\\\\\]\\\\s+//;
.Ef
matching header lines will be reformatted when the substitution is successful,
which likely means original continuations will not be preserved.  The target
of the substitution is the whole header, with continuations normalized to
one space.  You are therefore guaranteed to be independent from the actual
header formatting in the original.

Do not forget to issue a RESYNC after a header field SUBST, since some
routines (like POST) probe into the parsed header hash table to generate
the saved message.

(Fails if error in \fIexpression\fR)
.TP
TR \fIvar/header translation\fR
Perform the translation on the specified variable, back-reference or header
field. For instance
.Ex
TR 1 /A-Z/a-z/
.Ef
would canonicalize content of reference 1 into
lowercase.
Successfully transliterated headers are reformatted, even when their overall
size is not changed.
See also ASSIGN and SUBST.  (Fails if error in \fItranslation\fR)
.TP
UMASK [\fB\-l\fR] \fImode\fR
Changes the process's umask to the specified \fImode\fR, which can be decimal,
octal (if preceded by '0') or hexadecimal (starting with '0x'). The octal
notation is the clearest way to specify the umask anyway. Aren't rumors saying
that octal was invented for that purpose only? ;-)
Use the \fB\-l\fR option to change the umask for the duration of the current
action rule only. Note that the default umask specified in your config file
is used to reset \fImailagent\fR's umask at the start of each mail processing.
(Does not alter execution status)
.TP
UNIQUE [\fB\-acr\fR] [\fImode\fR] [\fI(tag-list)\fR]
Record message in the history and tag message as saved if it was
already present there. If the message is recorded for the first time, processing
continues normally. Otherwise a REJECT is performed. If \fB\-r\fR was used,
a RESTART is used instead whilst \fB\-a\fR would run an ABORT.
For instance, to remove duplicate messages from mailing lists, run a
UNIQUE \fB\-a\fR before saving the mail.
The \fB\-c\fR option may be used alone to
actually prevent the command from disturbing the execution flow, and to later
use the return status to see what happened:
UNIQUE returns a failure status if the message was already recorded.
If an optional \fImode\fR argument is given, then the automaton will enter that
mode if the mail was previously in the database.
See also RECORD, and the paragraph entitled \fBUsing Tags in Record and
Unique\fR for more information about the \fItag-list\fR.
(Fails if mail was already recorded)
.TP
VACATION [\fB\-l\fR] \fIon|off|path\fR [\fIperiod\fR]
Allow or disallow a vacation message. When vacation mode is turned on via the
configuration file, a message is sent whenever the user receives a mail
meeting some requirements, as explained under the section \fBVACATION MODE\fR.
One of the conditions is that the vacation flag modified by this command be
true. This makes it easy to disallow vacation messages, ever, to a group
of people for instance.
.sp
Instead of \fIon\fR or \fIoff\fR, you can specify a file name (~ substitution
allowed) being the new path to be used for locating the vacation file.
Optionally, you may specify a last parameter, which will be taken as the
period to apply when sending the vacation message.
Changes to the vacation message \fIpath\fR are forbidden when the
configuration variable \fIvacfixed\fR is set to ON.
.sp
If you use the \fB\-l\fR option, changes are made locally, for the duration of
the rule only. If you REJECT to go to some other rule, your changes will be
lost. The global value of the altered parameters is changed on the first local
usage and restored when a new rule is entered.
(Does not alter execution status)
.TP
WRITE \fIfolder\fR
Write the message in the specified folder, removing any pre-existing folder
with the same name. Hence, successive WRITE commands will overwrite the
previous one. This is useful to store output of system commands ran by
\fIcron\fR. Don't try to use it with an MH folder or a directory folder or
it will behave like SAVE.
(Fails if message cannot be written)
'''
.SS "Execution Status"
.PP
Almost all the actions modify a variable which keeps track of the execution
status (analogous to the \$? variable in the shell).
This variable can be tested via the \fB\-t\fR or \fB\-f\fR option of
the REJECT command for instance. To give but a single example, the SAVE
action would return \fIfailed\fR if it could not save the mail in the specified
folder. If that SAVE command was followed by a "REJECT -f FAILED", then the
execution of the current rule would stop and the automaton would continue to
analyze the mail in the FAILED mode.
.PP
Some of the actions however do not modify this last execution status. Typically,
those are actions which make decisions based on that status, or simply actions
which may never fail. Those special actions are: ABORT, ASSIGN, BEGIN, KEEP,
MACRO, NOP, REJECT, RESTART, RESYNC, STRIP and VACATION.
.PP
It is unfortunate that ONCE or SELECT commands cannot make the difference
between a non-execution and a successful execution of the specified command.
There may be a change in the way this scheme works, but it should remain
backward compatible.
'''
.SS "Perl Escape"
.PP
By using the PERL command, you have the ability to perform filtering and other
sophisticated actions directly in \fIperl\fR. This is really different from
what you could do by feeding your mail to a perl script. First of all, no
extra process is created: the script is loaded directly into mailagent and
compiled in a special package called \fImailhook\fR. Secondly, you have a
perl interface to all the filtering commands: each filtering action is
associated to a perl function (spelled lower-cased). Finally, some pre-defined
variables are set for you by mailagent.
.PP
Before we go any further, please note that as there is no extra process created,
you \fBmust not\fR call the perl \fIexit\fR function. Use \fI&exit\fR instead,
so that the exit may be trapped. \fI&exit\fR takes one argument, the exit code.
If you use 0, this is understood as a success, any other value meaning failure
(i.e. the PERL command will return a failure status). Using the perl \fIexit\fR
function directly would kill \fImailagent\fR and would probably incur some
mail looses.
.PP
The scripts used should remain simple. In particular, you should avoid the use
of the \fIpackage\fR directive or define functions with a package name other
than \fImailhook\fR (i.e. the package where your script is loaded). Failure
to do so may raise some name clashes with \fImailagent\fR's own routines.
In particular, avoid the \fImain\fR package. Note that since the compilation
environment is set-up to \fImailhook\fR, not specifying package names in your
variables and subroutine is fine (in fact, it's meant to work that way).
.PP
Your script is free to do whatever it wants to the mail. Most of the time
however, you end up using the \fImailagent\fR primitives to save the mail
or forward it (but you are free to redesign your own and call them instead,
of course). The interface is simple: each function takes but one argument,
a string, which is the arguments to the command, if any. For instance, in
a perl escape script, you would express:
.Ex
{ SAVE list; FORWARD "users"; FEED ~/bin/newmail -tty; REJECT }
.Ef
with:
.Ex
&save('list');
&forward('"users"');
&feed('~/bin/newmail -tty');
&reject;
.Ef
The rule is simple: each command is replaced by a function call, with the
remaining parameters enclosed in a string, if any. Alternatively, you may
specify parameters as a list: all the arguments you provide are joined
into a big happy string, using a space character as separator. The macro
substitution mechanism is then ran on this resulting argument string.
.PP
Each function returns a boolean
success status of the command (i.e. 1 means success). For those functions which
usually do not modify the filter's last execution status variable, a success is
always returned. This makes it possible to (intuitively) write:
.Ex
&exit(0) if &save('uucp');
&bounce('root') || &save('emergency');
.Ef
and get the expected result. The mail will be saved in the emergency folder
only when saving in uucp folder failed and the mail could not be bounced to
root.
.PP
It is important to understand that these commands have \fIexactly\fR the
same effect on the filtering process when they are run from a perl escape
script or from within the rule file as regular actions.
A \fI&reject\fR call will simply abandon the execution of the current perl
script and the filter automaton will regain control and attempt a new match.
But \fIperl\fR brings you much more power, in particular system calls,
control structures like \fBif\fR and \fBfor\fR, raw regular expressions, etc...
.PP
The special \fIperl\fR @INC array (which controls the search path for
\fIrequire\fR) is slightly modified by prepending mailagent's own private
library path. This leaves the door open for future mailagent library perl
scripts which may be required by the perl script. Furthermore,
the following special variables are set-up by perl before invoking your
script:
.sp
.PD 0
.TP 15
.I @ARGV
The arguments of the script, which were given by the PERL command. This array
is set up the exact same way you would expect it to be set up if you invoked
the command directly from the shell, excepted that
.I @ARGV[0]
is the name of the script (since you cannot use perl's \fI\$0\fR to get
at it; that would give you mailagent's name).
.TP
.I \$address
The address part of the From: line.
.TP
.I \$cc
The raw content of the Cc: line.
.TP
.I @cc
The list of addresses on the Cc: line, with comments suppressed.
.TP
.I \$envelope
The mail envelope, as computed using the first From line of the message.
.TP
.I \$friendly
The comment part of the From: line, if any.
.TP
.I \$from
The content of the From: line, with address and comment part.
.TP
.I %header
This table, indexed by field name, returns the raw content on the
corresponding header line. See below.
.TP
.I \$msgpath
The full path name of the folder (or message within an MH folder) where
the last saving operation has occurred. This is intended to be used if
you wish to construct your own mail reception notification.
.TP
.I \$length
The message length, in bytes.
.TP
.I \$lines
The number of lines in the message.
.TP
.I \$login
The login name of the address on the From: line.
.TP
.I \$precedence
The content of the Precedence: line, if any at all.
.TP
.I @relayed
The list of host names (possibly raw IP addresses if no DNS mapping) listed
in the (computed) Relayed: header line.
.TP
.I \$reply_to
The e-mail address where a reply should be sent to, with comment suppressed.
.TP
.I \$sender
The sender of the message (may have a comment), derived in the same way the
Sender: line is computed by mailagent.
.TP
.I \$subject
The subject of the message.
.TP
.I \$to
The raw content of the To: line.
.TP
.I @to
The list of addresses on the To: line, with comments suppressed.
.PD
.PP
The associative array \fI%header\fR gives you access to all the fields in
the header of the message. For instance, \fI\$to\fR is really the value of
\fI\$header{'To'}\fR. The key is specified using a normalized case, i.e.
the first letter of each word is uppercased, the remaining being lowercased.
This is independent of the actual physical representation in the message
itself.
.PP
The pseudo keys \fIHead\fR, \fIBody\fR and \fIAll\fR respectively gives you
access to the raw header of the message, the body and the whole message.
The \fI%header\fR array is really a reference to the \fImailagent\fR's internal
data structure, so modifying the values will influence the filtering process.
For instance, the SAVE command writes the \fIHead\fR, the \fIX-Filter:\fR line,
the end of header (a single newline) and then the \fIBody\fR (this is an
example only, not a documented feature :-).
.PP
Note that the \fI\$msgpath\fR variable holds only a snapshot of the folder path
at the time where the PERL escape
was called. If you perform your own savings in perl, then you need to
look at the \fI\$main'folder_saved\fR variable instead to get the up-to-date
folder path value.
.PP
As a final note, resist the temptation of reading the internals of the
mailagent and directly calling the routines you need. If it is not documented
in the manual page, it may be changed without notice by any further patch.
(And this does not say that documented features may not change also... It's
just more unlikely, and patches would clearly state that, of course.)
'''
.SS "Program Environment"
.PP
All the programs started by mailagent via RUN and friends inherit the
following environment variables: HOME, USER and NAME, respectively set from
the configuration parameters \fIhome\fR, \fIuser\fR and \fIname\fR. If the
mailagent is invoked by the \fIfilter\fR, then the PATH is also set according
to the configuration file (if you are using the C filter) or to whatever you
set PATH (if you are using the shell filter).
.PP
All the programs are executed from within the \fIhome\fR directory. This
includes scripts started via the PERL command and mail hooks. The latter will
be described in detail further down.
'''
.SS "File inclusion"
.PP
Some commands like FORWARD or KEEP allow you to specify a file name between
double quotes to actually load parameters from this file. Unless a full path
is given, the following method is used to locate the file: first in the location
pointed to by the \fImailfilter\fR variable if set, otherwise in \fImaildir\fR
and finally in the home directory. Note that this is not a search path in the
sense that if \fImailfilter\fR is defined and the file is not there, an error
will be reported.
.PP
The file should list each parameter (be it an address, a header or a pattern)
on a line by itself. Shell-style comments (#) are allowed within that file and
leading white spaces are trimmed (but not trailing spaces).
'''
.SS "Macros Substitutions"
.PP
All the commands go through a macro substitution mechanism before being
executed. The following macros are available:
.sp
.PD 0
.TP 10
%%
A real percent sign
.TP
%A
The internet address extracted out of the \fIFrom:\fR field (\fIa.b.c\fR
in \fIu@a.b.c\fR), converted to lower-case.
.TP
%C
CPU name on which mailagent runs. That is a fully qualified hostname
with the domain name, e.g. \fIlyon.eiffel.com\fR.
.TP
%D
Day of the week (0-6)
.TP
%H
Host name (name of the machine on which the \fImailagent\fR runs), without
any domain name. Always in lower-case, regardless of the machine name.
.TP
%I
The internet domain name extracted out of the \fIFrom:\fR field (\fIb.c\fR
in \fIu@a.b.c\fR), converted to lower-case.
.TP
%L
Length of the body part, in bytes
.TP
%N
Full name of the sender (login name if none)
.TP
%O
The organization name extracted out of the \fIFrom:\fR field (\fIb\fR in
\fIu@a.b.c\fR), converted to lower-case.
.TP
%R
Subject of the original message with leading Re: suppressed
.TP
%S
Re: subject of original message
.TP
%T
Time of the last modification on mailed file (commands MESSAGE and NOTIFY)
.TP
%U
Full name of the user
.TP
%Y
Full year, with four digits (so-called \fIyyyy format\fR)
.TP
%_
A white space (useful to put white spaces in single patterns)
.TP
%&
List of selectors which incurred match (among those specified via a regular
expression such as 'X-*: /foo/i'. If we find the \fIfoo\fR substring in the
X-Mailer: header line, then %& will be set to this value). Values in the list
are comma separated.
.TP
%~
A null character, wiped out from the resulting string.
.TP
%\fIdigit\fR
Value of the corresponding back reference from the last match.
.TP
%#\fIvar\fR
Value of user-defined variable \fIvar\fR
.TP
%=\fIvar\fR
Value of the mailagent configuration variable \fIvar\fR as specified in the
\fI~/.mailagent\fR file.
.TP
%d
Day of the month (01-31)
.TP
%e
The user's e-mail address (yours!).
.TP
%f
Contents of the "From:" line, something like %N <%r> or %r (%N) depending
on how the mailer is configured.
.TP
%h
Hour of the day (00-23)
.TP
%i
Message ID, if available (otherwise, this is a null string)
.TP
%l
Number of lines in the message
.TP
%m
Month of the year (01-12)
.TP
%n
Lower-case login name of sender
.TP
%o
Organization (where \fImailagent\fR runs)
.TP
%r
Return address of message
.TP
%s
Subject of original message
.TP
%t
Current hour and minute (in HH:MM format)
.TP
%u
Login name of the user
.TP
%y
Year (last two digits)
.TP
%[To]
Value of the header field (here To:)
.PD
'''
.SS "User-defined Macros"
.PP
The mailagent lets you define your own macros in two ways: at the filter
level via the MACRO command, or at the perl level in your own commands or
perl actions.
.PP
Once defined, a user macro (say \fIfoo\fR) can be substituted by using
\fI%-(foo)\fR. In the case of a single-letter macro, that can be optimized
into \fI%-f\fR for instance, i.e. the parenthesis can be omitted.
.PP
There are six types of macros:
.sp
.TP 10
SCALAR
A scalar value is given, e.g: \fIred\fR. The macro's value is the literal
scalar value, no further interpretation is performed on the data.
.TP
EXPR
A perl expression will be \fIeval\fRed to get the value, e.g: \fI\$red\fR.
Note that the evaluation will be performed within the \fIusrmac\fR package,
so if you are referring to a variable in another package, it would be wise
to specify it, as in \fI\$foo'bar\fR.
.TP
CONST
It's really the same as EXPR, but the value is known to be a constant. So the
first time a substitution is made, the expression will be evaluated, and then
its result is cached.
.TP
FN
A perl function name (without the leading &), such as \fImain'do_this\fR.
The function will be called with a single parameter: the name of the
macro itself. That leaves the door open for further user-defined conventions
by forcing evaluation through one single perl function.
.TP
PROG
A program to run to get the actual value. Only trailing newline is chopped,
others are preserved. The program is forked each time. In the argument list
given to the program, %n is expanded as the macro name we are trying to
evaluate. If you specify that in the filtering rules, don't forget to
escape the first %.
.TP
PROGC
Same as PROG really, but the program is forked only once and the value
is cached for later perusal.
.PD
.PP
At the perl level, four functions let you manipulate and define your
macros (all part of the \fIusrmac\fR package):
.sp
.TP 10
.I new(name, value, type)
Replace or create a %-(name) macro. For instance:
.Ex
new('foo', "\$mailhook'header{'X-Foo'}", 'EXPR');
.Ef
would create a new macro \fIfoo\fR that would expand into the value of
an hypothetical \fIX-Foo\fR header.
.TP
.I delete(name)
Delete all values recorded for the macro.
.TP
.I push(name, value, type)
Stack a new macro, creating it if necessary.
.TP
.I pop(name)
Remove last macro definition on the stack.
.PD
.PP
One macro stack is allocated for each macro, so that some kind of crude
dynamic scoping may be implemented. Creating a macro via \fIpush\fR is
like taking a local variable in perl, while creating one by \fInew\fR is
simply assigning to a variable. Likely, \fIpop\fR is like exiting a
block with a local variable definition and \fIdelete\fR frees \fIall\fR
the macro bearing that name, i.e. it deletes the whole stack.
.PP
At the filter level, the MACRO command has three options. By default,
the command defines a new macro by using \fIpush\fR, and the other
options each let you access one of the other interface functions.
Note that macro definitions persist across APPLY commands.
'''
.SS "User-defined Logging"
.PP
Most of the time when writing a new mailagent filtering command or an
perl hook, you will have a need for specific logging, either to report
a problem or to keep track of what you are performing.
.PP
Normally, logs are appended into the \fIagentlog\fR file by calling
\fI&main'add_log(string)\fR (see subsection \fBGeneral Purpose Routines\fR).
For plain mailagent actions, this is fine.
.PP
But mailagent lets you define alternate logging files, referred to by name.
This generic logging interface is defined in the \fIusrlog\fR package:
.sp
.TP 10
.I new(name, file, flag)
Records a new log file known as \fIname\fR and done in \fIfile\fR. If the
pathname given for this file is not absolute, it is rooted under the
\fIlogdir\fR directory. If \fIflag\fR is set to true, any logging done to
this file will also be copied to the default system-wide logfile. Nothing is
done if a logfile with the same name has already been defined.
.TP
.I delete(name)
Deletes the logfile known as \fIname\fR. Further logging done to that file
is redirected to the default logfile.
.TP
.I main'usr_log(name, string)
Adds an entry to the logfile \fIname\fR. The default logfile is known as
\fIdefault\fR and cannot be redefined nor deleted. Note that this function
is available from the \fImain\fR package. Calling it with \fIname\fR set to
the string \fI'default'\fR is mostly equivalent to calling directly
\fImain'add_log\fR with the notable exception that the \fB\-i\fR mailagent
option will not be honored in that case. This may or may not be useful to you.
.PP
If you call \fI&main'usr_log\fR with a non-existent logfile name, logging
is redirected to the default system-wide logfile defined in your
\fI~/.mailagent\fR.
'''
.SS "Dynamically Loading New Code"
.PP
In you perl routines (user-defined commands, perl hooks, etc...), you may
feel the need to dynamically load some new code into mailagent. You have
direct access to the internal routine used by mailagent to implement the
REQUIRE command or load your new filtering commands for example.
.PP
Using the so-called \fIdynload\fR interface buys you some extra features:
.IP \(bu 5
The mailagent public library path is automatically prepended to the @INC
array, which lets you define your own system-wide or private perl library
files (the private library path is defined by the \fIperlib\fR configuration
variable, the public library path was defined at installation time).
.IP \(bu
Like perl's \fIrequire\fR, mailagent keeps track of which files were loaded
into which packages and will not reload the same file in the same package
twice.
.IP \(bu
It is possible to make sure that a specific function be defined in the
loaded file, with an error reported if this is not the case.
.IP \(bu
You benefit from the default logging done by \fIdynload\fR when some error
occurs.
.PP
In order to do all this, you call:
.Ex
\fI&dynload'load(package, file, function)\fR
.Ef
specifying the package into which you wish to load the file, and optionally
the name of a function that must be defined once the file has been loaded
(leave this field to \fIundef\fR if you do not have such a constraint).
The routine returns \fIundef\fR if the file cannot be loaded
(non-existent file, most probably), \fB0\fR if the file was loaded but
contained a syntax error or did not define the specified function, and \fB1\fR
for success.
'''
.SS "Using Once Commands"
.PP
The ONCE constructs lets you specify a given command to be run once every
period (day, week...). The command is identified by a \fIname\fR and a
\fItag\fR, the combination of the two being unique. Why not just a single
identifier? Well, that would be fine, but assume you want to send a message
in reply to someone once every week. You could use the e-mail address of the
person as the command identifier. But what if you also want to send another
message to the same address, this time once a month?
.PP
Here is a prototypical usage of a ONCE, which acts like the vacation program,
excepted that it sends a reply only once a day for a given address:
.Ex
{ ONCE (%r, message, 1d) MESSAGE ~/.message };
.Ef
This relies on the macro substitution mechanism to send only once a day the
message held in \fI~/.message\fR. Do not use the tag \fIvacation\fR, unless
you know what you are doing: this is the tag used internally by mailagent
in vacation mode. Recall that no selector nor pattern is understood as
"Subject: *", hence the rule is always executed because that pattern always
matches.
.PP
The timestamps associated with each commands are kept in files under the Hash
directory. The name is used as a hashing key to compute the name of the file
(the two first letters are used). Inside the file, timestamps are sorted by
name, then by tag. Of course, you could say (inverting tag and name):
.Ex
{ ONCE (message, %r, 1d) MESSAGE ~/.message };
.Ef
but that would be likely to be less efficient, as the first hashing would be
done on a fixed word, hence all the timestamps would be located in the file
\fIHash/m/e\fR (where \fIHash\fR is the name of your hashing directory, which
is the \fIhash\fR parameter in the configuration file).
'''
.SS "Using Tags in Record and Unique"
.PP
Both the RECORD and UNIQUE commands let you specify a comma-separated tag list
between '(' and ')'. For each tag present in the list, there is a separate
entry in the database associated with the message ID. When the message is
recorded for at least one of the tags, the command "fails". Not specifying
any tags means looking for any occurrence of that message ID, whether it is
tagged or not.
.PP
This is very useful when receiving mail cross-posted to distinct mailing lists
and you want to save one instance of the message in each folder, but still
guard against duplicates. You may say:
.Ex
To Cc: unix-wizards	{
	UNIQUE (wizards);
	SAVE wizards;
	REJECT;
};
To Cc: majordomo-users	{
	UNIQUE (majordomo);
	SAVE majordomo;
	REJECT;
};
.Ef
and only one instance of the message will end up in each folder. When you
have folders with conflicting interests, you might use a tag list, instead
of a single tag. For instance, assuming you wish to keep a single copy for
messages cross-posted to both \fIdist-users\fR and \fIagent-users\fR, but
have a separate copy if also cross-posted to \fImajordomo-users\fR, then say:
.Ex
To Cc: majordomo-users	{
	UNIQUE (majordomo);
	SAVE majordomo;
	REJECT;
};
To Cc: dist-users {
	UNIQUE (dist, agent);
	SAVE dist-users;
	REJECT;
};
To Cc: agent-users {
	UNIQUE (dist, agent);
	SAVE dist-users;
	REJECT;
};
.Ef
If you have some rule using UNIQUE without any
tags, it will match when at least one instance of the message has been
recorded, no matter what tag (if any at all) was used in the first place.
'''
.SS "Specifying A Period"
.PP
The period parameter of the ONCE commands or the \fIvacperiod\fR parameter
of your configuration file has the following format: a number followed by a
modifier. The modifier is an atomic period like a day or a week, the number
is the number of atomic periods the final period should be equal to. The
available modifiers are:
.sp
.PD 0
.TP 10
m
minute
.TP
h
hour (60 minutes)
.TP
d
day (24 hours)
.TP
w
week (7 days)
.TP
M
month (30 days)
.TP
y
year (365 days)
.PD
.PP
All the periods are converted internally in seconds, although you do not
really care... Examples of valid periods range from "1m" to "136y" on a 32 bits
machine (why ?).
'''
.SS "Timeouts"
.PP
In order to avoid having a \fImailagent\fR waiting for a command forever, a
maximum execution time of one hour is allowed by default.
Past that amount of time, the
child is sent a SIGTERM signal. If it does not die within the next 30 seconds,
a SIGKILL is sent. Output from the program, if any so far, is mailed back to
the user.
This default behaviour may be altered by setting a proper \fIrunmax\fR variable
in your configuration file to allow more time for the command to complete.
.PP
There is also a \fIfilter\fR queue timeout. In order to moderate system load,
the C \fIfilter\fR program waits 60 seconds by default (or whatever
.I queuewait
was set to in the config file) before launching \fImailagent\fR. To avoid
conflicts, messages queued by the first filter (which will then sleep for
.I queuewait
seconds) are not processed by \fImailagent\fR's \fB\-q\fR option until they
are at least
.I queuehold
seconds old. Another queue-related parameter is
.I queuelost,
the amount of seconds after which \fImailagent\fR will flag messages as "lost"
when listing the queue.
.PP
Finally, the locking timeout policy may also be configured. By default, a
lock is broken when it is one hour old (configured by the
.I lockhold
variable) and \fImailagent\fR will only make
.I lockmax
attempts, spaced by
.I lockdelay
seconds to acquire the lock. It will then proceed whether or not it got that
lock. If you want a secure locking policy, make sure
.I lockmax
times
.I lockdelay
is greater than \fIlockhold\fR, that parameter being "large" enough.
'''
.SS "Avoiding Loops"
.PP
The \fImailagent\fR leaves an "X-Filter:" header on each filtered message,
which in turn is used to detect loops. If a message already filtered is
to be processed, the \fImailagent\fR enters a special state _SEEN_. This
state is special in the sense it is built-in, it is not matched by ALL, and
some actions are not made available, namely: BACK, BOUNCE, FEED, FORWARD, GIVE,
NOTIFY, PASS, PIPE, POST, PURIFY, QUEUE and RUN. Also note that although the
ONCE and SELECT constructs are enabled, they will not let you execute
disallowed commands.
.PP
The _SEEN_ mode makes it easy to deal with mails which loop because of an
alias loop you have no control on. If no action is found in the _SEEN_ mode,
the mail is left in the mailbox, as usual. Moreover, if no saving is done,
a LEAVE is executed. This is the normal behavior.
'''
.SS "Message Files"
.PP
The text of the message to be sent back (for MESSAGE or NOTIFY) is read from
a file and passed through the macro substitution mechanism. The special macro
\fI%T\fR is set to the date of last modification made on that file. The format
is \fImonth/day\fR, and the year is added before the month only if it differs
from the current year.
.PP
At the head of the message, you may put header lines. Those lines will
overwrite the default supplied lines. That may be useful to change the default
subject or add some additional fields like the name of your organization.
The end of your header is given by the first blank line encountered.
If the top of the message you wish to send looks like a mail header, you may
protect it by adding a blank line at the very top of the file. This dummy line
will be removed from the message and the whole file will be sent as a body
part.
.PP
Here is an example of a vacation file. We add a carbon copy as well as the
name of our organization in the header:
.Ex
Cc: ram
Organization: %o
Precedence: bulk

[Last revision made on %T]

Dear %N:

I've received your mail regarding "%R".
It will be read as soon as I come back from vacation.

Sincerely,
--
%U <%u@%C>
.Ef
.SH "VACATION MODE"
.PP
When it's time to take some vacation, it is possible to set up mailagent
in vacation mode. Every \fIvacperiod\fR, the message \fIvacfile\fR will be
sent back to the user (with macros substitutions) if the user is explicitly
listed in the \fITo\fR or \fICc\fR field and if the sender is not a special
user (\fIroot\fR, \fIuucp\fR, \fInews\fR, \fIdaemon\fR, \fIpostmaster\fR,
\fInewsmaster\fR, \fIusenet\fR, \fIMailer-Daemon\fR, \fIMailer-Agent\fR or
\fInobody\fR).
Matches are done in a case insensitive manner, so \fIMAILER-DAEMON\fR will also
be recognized as a special user.
Furthermore, any message tagged with a \fIPrecedence:\fR field set to
\fIbulk\fR, \fIlist\fR
or \fIjunk\fR will not trigger a vacation message. This built-in
behavior can of course be overloaded by suitable rules (by testing and
issuing the vacation message yourself via MESSAGE).
.PP
Internally, mailagent uses a ONCE
command tagged \fI(%r, vacation, \$vacperiod)\fR. This implies you must not
use the \fIvacation\fR tag in your own ONCE commands, unless you know what
you are doing.
.PP
Besides, the vacation message is sent only if no "VACATION off" commands were
issued, or if another "VACATION on" overwrote the previous one. Note that
whether a rule matched or not is irrelevant to the algorithm. By default, of
course, the vacation message is allowed when the \fIvacation\fR configuration
parameter is set to \fIon\fR.
.PP
If you are not pleased by the fact that a vacation message is sent to people
who addressed you a carbon copy only, then you may write at the top of your
rule file:
.Ex
Cc: ram  { VACATION off; REJECT };
.Ef
Of course, you have to substitute your own login name in place of \fIram\fR.
You cannot use the same scheme to allow vacation messages to special
users like \fIroot\fR, because the test for "specialness" occurs after the
vacation mode flag. This is construed as a feature as it prevents stupid
mistakes, like using \fIr*\fR instead of \fIram\fR in the previous rule.
.PP
You may also want to setup a different vacation message, meant only for people
in your organization given the sensitive nature of the information revealed ;-).
A simple way of doing that is:
.Ex
From: /^\\\\w+\$/, /^\\\\w+@\\\\w+\$/, /^[\\\\w.-]+@.*\\\\.hp\\\\.com\$/i
	{ VACATION ~/.hp_vacation 1w; REJECT HP };
.Ef
Assuming the domain of my organization is \fI.hp.com\fR and that messages
not bearing any domain are local messages, the above rule sets up the
file \fI~/.hp_vacation\fR, sent once a week, for all HP employees.
.PP
The VACATION command will not let you change the message path (but will
allow frequency changes anyway) when the \fIvacfixed\fR configuration
variable is set to ON. This is meant to be used in emergency situations,
when only one vacation message will fit. For instance, when you are on
a sick leave, a simple trigger message to your mailagent from home could
change your \fI~/.mailagent\fR configuration to force the \fI~/.i_am_sick\fR
message, regardless of what the various rules have to say. Actually, this
is precisely why this feature was added, amazing... :-)
.SH VARIABLES
The following variables are paid attention to: they may come from the
environment or be set in the rule file:
.TP 10
.I mailfilter
indicates where loaded patterns are to be looked for, if the name of the
file is not fully qualified. If it is not set, \fImaildir\fR will be used
instead. If \fImaildir\fR is not set either, the home directory is used.
.TP
.I maildir
is the location of your mail folders. Any relative path is understood as
starting from \fImaildir\fR. If it is not set, \fI~/Mail\fR is used.
.PP
Those variables remain active while in the scope of the rule file.
Should an alternate rule file be used (via rules hook or the APPLY command),
the current values are propagated to the new rule set unless overridden in
the alternate rule file. In any case, the previous value is restored when
control is transferred back to the previous set of rules. That is, those
variables are dynamically instead of statically scoped.
.SH "AUTOMATIC ACKNOWLEDGMENTS"
Anywhere in the mail, there can be an @RR left-justified line which will
send back an acknowledgment to the sender of the mail. The @RR may optionally
be followed by an address, in which case the acknowledgment will be sent
to that address instead.
In fact (but let's keep that a secret), this is a way for me to be able to
see who runs my mailagent program and who doesn't...
.PP
The \fIsendmail\fR program usually implements such a feature via a
Return-Receipt-To: header line, which sends the whole header back upon
successful delivery. However, this is not implemented on all mail transport
agents, and @RR is a good alternative :-).
.SH "NOTA BENE"
Throughout this manual page, I have always written header fields with the first
letter of each word uppercased, as in \fIReturn-Receipt-To\fR. But RFC-822 does
not impose this spelling convention, and a mailer could legally rewrite the
previous field as \fIreturn-receipt-to\fR (and in fact so does \fIsendmail\fR
in its own private mail queue files).
.PP
However, you must always specify the headers in what could be called a
\fInormalized\fR case (for headers anyway). The mailagent will correctly
recognize \fIcc:\fR, \fICC:\fR or \fICc:\fR in a mail message and will allow
you to select those fields via the normalized \fICc:\fR selector. In fact, it
operates the normalization for you, and a \fIcc:\fR selector would not be
recognized as such. Of course, no physical alteration is ever made on the
header itself.
.PP
This is also true for headers specified in the STRIP or KEEP command. If you
write \fISTRIP Cc\fR, it will correctly remove any \fIcc:\fR line. Likewise,
if you use regular expressions to specify a selector, \fIRe.*:\fR would match
both original \fIreceived:\fR and \fIReturn-path:\fR fields, internally known
through their normalized representation.
.SH "MAIL HOOKS"
The mail hooks allow mailagent to transparently invoke some scripts or
perform further processing on the message. Those hooks are activated via
the SAVE, STORE or LEAVE commands. Namely, saving in a folder whose executable
bit is set will raise a special processing. By default, the folder is taken
as a program where the mail should be piped to. If the "folder" program
returns a zero status, then the message is considered \fIsaved\fR by the
mailagent. Otherwise, all the processing attached to failed save commands is
started (including emergency saving attempts). Executable folders provide a
transparent way (from the rule file point of view) to deal with special
kind of messages.
.PP
In fact, five different types of hooks are available. The first one is the
plain executable folder we have just spoken about. But in fact, here is what
really happens when a saving command detects an executable folder: the
mailagent scans the first line of the
folder (in fact, the first 128 bytes) and looks for something starting with
#: and followed by a single word, describing a special kind of hook. This is
similar in the way the kernel deals with the #! hook in executable programs.
If no #: is found or #: is followed by some garbage, then \fImailagent\fR
decides
it is a simple program and feeds the mail message to this program. End of the
story.
.PP
But if the #: token is followed (spaces allowed, case is irrelevant) by one of
the following words, then special actions are taken:
.PD
.TP 10
.I rules
The file holds a set of mailagent rules which are to be applied. A new mailagent
process is created to actually deal with those and the exit status is
propagated back to the original mailagent.
.TP
.I audit
This is similar in spirit to what Martin Streicher's audit.pl package does,
hence the name of this hook. The special variables which are set up by the
PERL filter commands are initialized and the script is loaded in the special
\fImailhook\fR package name space, which also gives you an interface to the
mailagent's own routines.
You may safely use the \fIexit\fR function here, since
an extra \fIfork\fR is done. This is the only difference between an \fIaudit\fR
and a \fIperl\fR hook.
.TP
.I deliver
Same thing as for the \fIaudit\fR hook, but the standard output of your script
is monitored by \fImailagent\fR and understood as mailagent filtering commands.
Upon successful return, a mailagent process will be invoked to actually execute
those commands on the message. Again, this is similar in spirit to Chip
Salzenberg's \fIdeliver\fR package and gave the name of this hook.
.TP
.I perl
This hook is the same as \fIaudit\fR but it is executed without forking a
new mailagent, and
you have the perl interface to mailagent's filtering commands. There is
no difference with the PERL command, because it is implemented that way, by
calling a mailagent and forcing the PERL command to be executed. This is
similar in spirit to Larry Wall's famous \fIperl\fR language and it is
responsible for the name of this hook :-).
.PP
As mentioned earlier in this manual page, the hook is invoked from with the
\fIhome\fR directory specified in your ~/.mailagent (which may differ from
your real home directory, as far as \fImailagent\fR or \fImailhook\fR are
concerned).
.PP
For those hooks which are finally ran by perl, the special @INC array has
mailagent's own private library path prepended to it, so that \fIrequire\fR
first looks in this place.
'''
''' F o l d e r s
'''
.SH "FOLDERS"
A folder is a file or a directory which can be the target of a delivery by the
mailagent, that is to say the argument of SAVE-like commands.
'''
.SS "Folder Format"
.PP
By default, mails are written into folders according to the standard UNIX-style
mailbox format: each mail starts with a leading \fIFrom\fR line bearing the
sender's address and the date. However, by setting the \fImmdf\fR parameter
from the \fI~/.mailagent\fR to ON, the \fImailagent\fR will be able to save
messages in MMDF format: each message is sandwiched between two lines of four
Ctrl-A characters (ASCII code 1) and the leading \fIFrom\fR line is removed.
.PP
When MMDF mode is activated, each folder will be scanned to see if it is a
UNIX-style or MMDF-style mailbox and the message will be saved accordingly.
When saving to a new folder, the default is to create a UNIX-style mailbox,
unless the \fImmdfbox\fR configuration variable was set to ON, in which case
the MMDF format prevails.
.PP
Note that the MMDF format is also the standard for MH packed folders, so by
enabling the MMDF mode, you can actually deliver directly to those packed
folders. The MH command \fIinc\fR is able to incorporate mail from either
form anyway, i.e. it does not matter whether the folder is in UNIX format
(also called UUCP-style) or in MMDF format.
.PP
MH-style folders are also supported. It is mainly a directory in which messages
are stored in individual files. To save directly into an MH folder, simply
prefix the folder name with '+', just as you would do with MH commands.
The unseen sequences specified in your MH profile (the \fImhprofile\fR
parameter in your \fI~/.mailagent\fR, default is \fI~/.mh_profile\fR)
will be correctly updated, as \fIrcvstore\fR would.
.PP
When the target folder is a directory, mailagent attempts the delivery in
an individual numbered file. If a prefix file is present
(config parameter \fImsgprefix\fR, default is \fI.msg_prefix\fR), its first
line is used to specify the base name of the message, then a number is
appended to give the name of the message file to use. That is, if there is
no such file, the folder will look like an MH one, without any MH sequence
file though.
'''
.SS "Folder Compression"
.PP
If you have one or more of the widely available file compression
utilities such as \fIcompress\fR or \fIgzip\fR in your PATH (as set up
by \fI~/.mailagent\fR), then you may wish to use folder compression to
save some disk space, especially when you are away for some time and
do not want to see your mail fill-up the filesystem.
.PP
To achieve folder compression, you have to set up a file, referred to by the
\fIcompress\fR configuration variable. This file must list folder names, one
per line, with blank lines ignored and shell-style (#) comments allowed. You
may use shell-style patterns to specify the folders, and the match will be
attempted on the full pathname of the folder (~ substitution occurs). If you
do not specify a pattern starting with a leading '/' character, then the match
will be attempted on the basename of the folder (i.e. the last component of
the folder path). If you want to compress all your folders, then simply put
a single '*' inside this file.
.PP
Mailagent uses the filename extension to determine what compression
scheme is used for a particular folder.  The file referred to by the
\fIcompspecs\fR configuration variable (default is \$spool/compressors)
is used to define the commands that mailagent will use to perform the
compress, uncompress, and cat operations for a particular extension.
.PP
The \fIcompressors\fR file holds lines of the following form:
.Ex
\fItag extension compression_prog uncompress_prog cat_prog\fR
.Ef
where:
.TP 10
.I tag
is the logical name for the compression scheme.  This is typically the
same as the name of the program used to provide the compression, but
could be different for some unforeseen reason.  This must be unique
across all records in the file.
.TP
.I extension
is the extension to recognize as belonging to the specified tag.  This
must be unique across all records in the file.
.TP
.I compression_prog
is the name of the command to run to compress a folder.  The program
must replace the uncompressed file with the compressed one with the
extension appended to the filename (like \fIcompress\fR or \fIgzip\fR).
.TP
.I uncompression_prog
is the name of the command to run to uncompress a folder.  The program
must replace the compressed file with the uncompressed one without the
extension (like \fIuncompress\fR or \fIgunzip\fR).
.TP
.I cat_prog
is the name of the command to output the uncompressed contents of a
compressed folder to stdout (like \fIzcat\fR or \fIgzcat\fR).
.PP
The fields are separated by \fBTABS\fR to allow for the use of space
characters in the command fields.
.PP
If the file referred to by the \fIcompspecs\fR configuration variable
cannot be accessed for whatever reason, a default entry is hard-wired
into mailagent (knows about both \fIcompress\fR and \fIgzip\fR programs):
.Ex
compress <TAB> .Z <TAB> compress <TAB> uncompress <TAB> zcat
gzip <TAB> .gz <TAB> gzip <TAB> gunzip <TAB> gunzip -c
.Ef
.PP
If you wish to add more compressors, you can copy the default \fIcompressors\fR
file from mailagent's private library directory and setup a correct entry
for your alternate compressor. Keep in mind that the trailing extension needs
to be unique amongst all the listed programs, since that extension is used
to determine the type of compression performed on the folder.
.PP
If the folder is created without any existing compressed form around, a
default compressor is selected for you, as defined by the \fIcomptag\fR
configuration variable. That refers to the tag name of the \fIcompspecs\fR
file, i.e. the first word on the line (usually the name of the compression
program, but not necessarily).
.PP
When attempting delivery, mailagent will check the folder name against
the list of patterns in the compress file. If there is a match, the folder is
flagged as compressed. Then mailagent attempts decompression if there
is already a compressed form (ie. the file has a recognized filename extension)
and if no uncompressed form is present.
Delivery is then made to the uncompressed folder. However, re-compression is not
done immediately, since it is still possible to get messages to that folder in
a single batch delivery. Should disk space become so tight that decompression
of other folders is impossible, mailagent will re-compress the folders
it has already uncompressed. Otherwise, it waits until the last moment.
.PP
If for some reason there is a compressed folder which cannot be decompressed,
mailagent will deliver the mail to the plain folder. Further delivery
to that folder will be faced with both a compressed and a plain version of the
folder, and that will get you a warning in the log file, but delivery will be
made automatically to the plain file.
.PP
On newly created folders the \fIcomptag\fR configuration variable is
referenced to determine the compression type to use for the folder.
'''
''' M a i l   B i f f i n g
'''
.SH MAIL BIFFING
If you are receiving and processing mail on your own machine, then you have
access to local mail biffing where \fImailagent\fR can warn you about new
messages and tell you about where they have been saved, printing a small
subset of the header and the first few lines of the body.
.PP
To use biffing, all you need is the setting of the few biff parameters in
your \fI~/.mailagent\fR and make sure \fIbiff\fR is set to ON. Actually,
this is the only parameter you need to set to get minimal default biffing
behaviour. Don't forget to run the shell command "\fIbiff y\fR" on the
terminals where you want to get notification (you may do that on several ttys,
one for each virtual display for instance).
.PP
Upon mail reception and saving on a folder
or posting to a newsgroup,
\fImailagent\fR locates all the
ttys where you are logged on, then selects those where biffing was requested,
finally emitting a message and making a beeping sound (if your terminal
supports this and you are using the standard format--see below).
.SS "Customizing Biffing Output"
.PP
Should the default format not suit your needs, you may customize the
biffing message freely, setting the \fIbiffmsg\fR parameter to point to
the file where the format is stored. Standard macros substitutions will be
performed on your message, the following macro set superseding and completing
the standard set:
.sp
.PD 0
.TP 10
%-A
Same as writing %-H, new line, %-B
.TP
%-B
The body part of the biffing message
.TP
%-H
The header part of the biffing message. If shows only From:, To: Subject: and
Date: headers, or whatever you have set the \fIbiffhead\fR configuration
variable to. All headers are showed as one line of text, regardless of their
actual length. There will be three trailing dots at the end to signal that
truncation occurred.  For a news article (biffing after a POST -b), the To:
and Cc: fields are never shown, even if specified in \fIbiffhead\fR.
.TP
%-T
Same as %-B, but trimming is activated. The purpose of trimming is to remove
any leading quotation in the message, to get only the most meaningful part.
This assumes the quoting character is a single non-alphanumeric character.
The leading attribution line that may introduce the quotation can be also
removed, and a minimum length for the quotation can be set in the configuration
file.
.TP
%B
The relative path under %d of the message folder, full path (%p) if not
saved under that directory.  The newsgroup name for news articles.
.TP
%D
The directory where the message is stored. If an MH folder, this is the
folder full path. The home directory is replaced by a ~.  Empty
for news articles.
.TP
%F
The base name (last path component) of the message. For an MH message, this
is the message number.  Empty for news articles.
.TP
%P
The folder path. It has the correct semantics for MH and directory folders,
i.e. it points to the folder directory itself. Otherwise, the same as %p.
.TP
%a
Alarm characters (^G).
May expand to more than one under the control
of the BEEP filtering command. Use %b if you only want a single bell.
.TP
%b
A beeping character (^G).
As opposed to %a, this only expands to give \fBone\fR bell.
.TP
%d
Full path where folders such as the one being saved into are stored if not
qualified (i.e. your MH path for MH folders, of something like \fI~/Mail\fR
for other folders).  Empty for news articles.
.TP
%f
Folder where mail was saved, home replaced by ~ for short.  The newsgroup
when article was posted for news.
.TP
%m
A '+' sign if the folder is an MH one, empty otherwise.
.TP
%p
The full path name (same as %f) of the message, but without any ~ shortcut.
The newsgroup name for news articles.
.TP
%t
The type of message: usually "mail", but set to "article" for biffing after
a POST command.
.PD
.PP
You can get the standard macro expansion by using \fI%:f\fR for instance,
since the \fI%f\fR macro is superseded. The \fI%:\fR form lets you obtain
the standard macro definition anyway, no matter what, so you don't have
to remember whether a given macro is superseded in this context or not.
Besides, it is safer since new macros may be added here without notice.
Note that macros related to the message content all start
with \fI%-\fR and therefore are not conflicting with standard one.
.PP
Here is the format you need to use to get the same behaviour as the
default hardwired format:
.Ex
%b
New %t for %u has arrived in %f:
----
%-A
----%b
.Ef
Note that the string \fI...more...\fR appears at the end of the body when
it has not been completely printed out on the screen, regardless of the
value of the remaining lines. This means you'll get the \fI...more...\fR
string even if all the lines from now on are blank and \fIbiffnl\fR is OFF.
And it's not possible to customize this bit, sorry.
.SS "Trimming Leading Quotation"
.PP
It is a standard practice, when replying to a message, to include an
excerpt of the sentences being replied-to, using a non-alphanumeric
character such as '>' to prefix quoted lines. Something like:
.Ex
Quoting John Doe:
> This is quoted material.
> Another line from John's mail.

This is part of the reply to John.
.Ef
The leading "Quoting ..." line, called the \fIattribution\fR line, is
optional and may be missing or take another free form.
.PP
However, when biffing, this may be seen as useless noise, especially
nowadays where people freely quote more and more in their replies. Since
the biff message only shows the top lines of the message, it may be
desirable to automatically trim those quoted lines.
.PP
Via the \fI%-T\fR macro in the customized biff format, you may request
trimming of the leading quotation material, keeping the attribution line
or not, and even replace trimmed material with a notification that so
many lines have been removed.
.PP
All this customization is done from the \fI~/.mailagent\fR configuration
file, using the \fIbifftrim\fR, \fIbifftrlen\fR and \fIbiffquote\fR
variables.
.PP
You first need to turn trimming on by using a customized biff format
using the \fI%-T\fR macro. By setting \fIbifftrlen\fR to 3, you may
request that only quotations of at least 3 lines be trimmed. Turning
\fIbifftrim\fR off will remove the trimming notification, whilst
turning \fIbiffquote\fR off will also strip the attribution line, when
present.
.PP
For instance, assuming the following settings:
.Ex
bifftrim : ON
bifftrlen: 2
biffquote: OFF
.Ef
then the above example would produce the following biffing output (header
of the message not withstanding):
.Ex
[trimmed 3 lines starting with a leading '>' character & attribution line]
This is part of the reply to John.
.Ef
because the blank line following the quoted material is counted as being
part of the quotation. The "[trimmed ..]" message can be turned off by
setting \fIbifftrim\fR to OFF.
.PP
The trimming algorithm considers the first line of the body to see if it
starts with a non-alphanumeric character. If it does, then all the following
lines starting with that same character, or any blank line is removed, up to
the first non-blank line starting with another character. Optionally, the
first line (and that line only) is skipped if the second one starts with a
non-alphanumeric character, and the first line is taken as being the
attribution line.
.SS "Using Compact MH-style Biffing"
.PP
The so-called \fIMH-style\fR biffing is a way of presenting a compacted body
where all the lines are joined together into a big happy string with successive
spaces turned into a single space character. To enable it, you need to set
the \fIbiffmh\fR variable to ON.
.PP
Since this compacting is output verbatim on the tty, line breaks will occur
randomly and this may make reading difficult. You may request an automatic
reformatting of the compacted body by turning \fIbiffnice\fR to ON and the
biff output will fit nicely within 80 columns.
.PP
Unfortunately, it is not possible to customize the amount of columns that
should be used for formatting: since you may biff to any tty you are logged
on, that would force \fImailagent\fR to probe the tty for its column size,
for each possible tty where output may go, and there is no reliable portable
way of doing that. Sorry.
'''
''' E x t e n d i n g   F i l t e r i n g   C o m m a n d s
'''
.SH EXTENDING FILTERING COMMANDS
Once you've reached the \fIexpert\fR level, and provided you have a fair
knowledge of \fIperl\fR, you may feel the need for more advanced commands
which are not part of the standard set. This section explains how you
can achieve this dynamically, without the need of diving deep inside the
source code.
.PP
Once you have extended the filtering command set, you may use those commands
inside the rule file as if they were built-in. You may even choose to redefine
the standard commands if they do not suit you (however, if you wish to do
that, you should know exactly what you are doing, or you may start loosing
some mail or get an unexpected behavior -- this also voids your warranty :-).
.PP
The ability to provide external commands without actually modifying the main
source code is, I believe, a strong point in favor of having a program written
in an interpreted language like \fIperl\fR. This of course once you have
convinced yourself that it is a Good Thing to customize and extend a program
in the same language as the one used for the core, meaning usually a fairly
low-level language with fewer user-friendly hooks.
'''
.SS Overview
.PP
In order to implement a new command, say FOLD, you will need to do the
following:
.IP \(bu 5
Write a perl subroutine to implement the FOLD action and put that into
an external file. Say we write the subroutine \fIfold\fR and we store
that in a \fIfold.pl\fR file. This is naturally the difficult part, where
you need to know some basic things about mailagent internals.
.IP \(bu
Choose where you want to store your \fIfold.pl\fR file. Then check the
syntax with \fIperl \-c\fR, just to be sure...
.IP \(bu
Edit the \fInewcmd\fR file (as given by the configuration file) to record
your new command. Then make sure this file is tightly protected. You must
own it, and it should not be writable by any other individual but you.
.IP \(bu
Additionally, you may want to specify whether FOLD is to modify the existing
execution status and whether or not it will be allowed within the special
_SEEN_ mode.
.IP \(bu
Write some rules using the new FOLD command. This is the \fIeasy\fR part!
Note that your command may also be used within perl hooks as if it were
a builtin command (this means there is an interface function built for
you within the \fImailhook\fR package).
.PP
In the following sections, we're going to describe the syntax of the
\fInewcmd\fR file, and we'll then present some low-level internal variables
which may be used when implementing new commands.
'''
.SS New Command File Format
.PP
The \fInewcmd\fR file consists of a series of lines, each line describing
one command. Blank lines are ignored and shell-style comments introduced by
the sharp (#) character are allowed.
.PP
Each line is formed by 3 principal fields and 2 optional ones; fields are
separated by spaces or tabs. Here is a skeleton:
.Ex
<cmd_name> <path> <function> <status_flag> <seen_flag>
.Ef
The \fIcmd_name\fR is the name of the command you wish to add. In our
previous example, it would be FOLD. The next field, \fIpath\fR, tells
mailagent where the file containing the command implementation is
located. Say we store it in \fI~/mail/cmds/fold.pl\fR. The \fIfunction\fR
field is the name of the \fIperl\fR function implementing FOLD, which may
be found in \fIfold.pl\fR. Here, we named our function \fIfold\fR. Note that
if your function has its name within the \fInewcmd\fR package, which is the
default behavior if you do not specify any, then there is no need to prefix
the function name with the package. Otherwise, you must use a fully qualified
name.
.PP
The last two fields are optional, and are boolean values which may be
specified by \fItrue\fR or \fIyes\fR to express truth, and \fIfalse\fR
or \fIno\fR to express falsehood. If \fIstatus_flag\fR is set to
true, then the command will modify the last execution status variable.
If \fIseen_flag\fR is true, then the command may be used when the filter
is in _SEEN_ mode. The default values are respectively \fItrue\fR and
\fIfalse\fR.
.PP
So in our example, we would have written:
.Ex
FOLD  ~/mail/cmds/fold.pl  fold  no  yes
.Ef
to allow FOLD even in _SEEN_ mode and have it executed without modifying
the current value of the \fIlast-command-status\fR variable.
'''
.SS Writing An Implementation
.PP
Your perl function will be loaded when needed into the special package
\fInewcmd\fR, so that its own name-space is protected and does not accidentally
conflict with other mailagent routines or variables. When you need to call the
perl interface of some common mailagent functions, you will have to remember
to use the fully qualified routine name, for instance \fI&mailhook'leave\fR
to actually execute the LEAVE command.
.PP
(Normally, in PERL hooks, there is no need for this prefixing since the perl
script is loaded in the \fImailhook\fR package. When you are extending your
mailagent, you should be extra careful however, and it does not really hurt
to use this prefixing. You are free to use the perl \fIpackage\fR directive
within your function, hence switching to the \fImailhook\fR package in
the body of the routine but leaving its name in the \fInewcmd\fR package.)
.PP
Since mailagent will dynamically load the implementation of your command
the first time it is run, by loading the specified perl script into memory
and evaluating it, I suggest you put each command implementation in a separate
file, to avoid storing potentially unneeded code in memory.
.PP
Each command is called with one argument, namely the full command string as
read from the filter rules. Additionally, the special \fI@ARGV\fR array is
set by performing a shell-style parsing of the command line (which will fail
if quotes are mismatched, but then you can do the parsing by yourself since you
get the command line).
At the end of your routine, you must return a failure status, i.e.
\fB0\fR for success and \fB1\fR to signal failure.
.PP
Those are your only requirements. You are free to do whatever you want inside
the routine. To ease your task however, some variables are pre-computed for
you, the same ones that are made available within mail hooks, only they are
defined within the \fInewcmd\fR package this time. There are also a few
special variables which you need to know about, and a set of standard routines
you may want to call. Please avoid calling something which is not documented
here, since it may change without prior notice. If you would like to use one
routine and it is not documented in this manual page, please let me know.
.PP
Each command is called from within an \fIeval\fR construct, so you may
safely use \fIdie\fR or call external library routines that use \fIdie\fR.
If you use \fIrequire\fR, be aware that mailagent is setting up a special
\fI@INC\fR array by putting its private library path first, so you may place
all your \fImailagent\fR-related library files in this place.
'''
.SS Special Variables
.PP
The following special variables (some of them marked read-only, meaning you
shouldn't modify them, and indeed you can't) made available directly
within the \fInewcmd\fR package, are pre-set by the filter
automaton, and are used to control the filtering process:
.sp
.TP 15
.I \$mfile
The base name of the mail file being processed. This variable is read-only.
It is mainly used in log messages, as in [\$mfile] to tag each log, since a
single mailagent process may deal with multiple messages.
.TP
.I \$ever_saved
This is a boolean, which should be \fIset\fR to \fB1\fR once a successful
saving operation has been completed. If at the end of the filtering, this
variable is still \fB0\fR, then the default LEAVE will be executed.
.TP
.I \$folder_saved
The value of that variable governs the \fI\$msgpath\fR convenience variable
set for PERL escapes. It is updated whenever a message is written to a file,
to hold the path of the written file.
.TP
.I \$cont
This is the continuation status, a variable of the utmost importance when
dealing with the control flow. Four constants from the \fImain\fR package
can be used to specify whether we should continue with the current rule
(\$FT_CONT), abandon current rule (\$FT_REJECT), restart filtering from the
beginning (\$FT_RESTART) or simply abort processing (\$FT_ABORT). More on
this later.
.TP
.I \$lastcmd
The last failure status recorded by the last command (among those which do
modify the execution status). You should not have to update this by yourself
unless you are implementing some encapsulation for other commands, like BACK
or ONCE, since by default \fI\$lastcmd\fR will be set to the value you return
at the end of the command.
.TP
.I \$wmode
This records the current state of the filter automaton (working mode), in a
literal string form, typically modified by the BEGIN command or as a side
effect, as in REJECT for instance.
.PP
All the special variables set-up for PERL escapes are also installed within
the \fInewcmd\fR package. Those are \fI\$login\fR, \fI%header\fR, etc... You
may peruse them at will.
.PP
Other variables you might have a need for are configuration parameters, held
in the \fI~/.mailagent\fR configuration file. Well, the rule is simple. The
value of each parameter \fIparam\fR from the configuration file is held in
variable \fI\$cf'param\fR. Variable \fI\$main'loglvl\fR is the copy of
\fI\$cf'level\fR, since it's always shorter to type in \fI\$'loglvl\fR after
each call to the logging routine \fI&add_log\fR.
.PP
There is one more variable worth knowing about: \fI\$main'FILTER\fR, which is
the suitable X-Filter line that should be appended in \fBall\fR the mail you
send via mailagent, in order to avoid loops. Also when you save mails
to a folder, it's wise adding this line in case a problem arises: you may
then identify the culprit.
'''
.SS Rule Environment
.PP
An action might have a legitimate desire of altering the environment for
the scope of one rule only, reverting to the previous value when exiting
the rule. Or you might want to change the value forever.
.PP
When we speak about altering the environment, we refer to the one set up
via the configuration file, whose values end-up in the \fIcf\fR package.
Well, some of those variables are copied in the \fIenv\fR package before
filtering of a message starts (under the control of the \fI@env'Env\fR array).
.PP
All rules should then refer to the version in the \fIenv\fR package, and not
in the \fIcf\fR package, to see alterations. Global changes are made by
affecting directly to the variable in the \fIenv\fR package, while local
changes are requested by calling the \fI&env'local\fR routine.
.PP
For instance, the \fIcf'umask\fR value is copied as \fIenv'umask\fR because
\fIumask\fR is held in \fI@env'Env\fR. Global changes are made by setting that
copy directly, while local changes may be made with:
.Ex
	&env'local('umask', 0722);
.Ef
to set-up a new local value. The first time \fI&env'local\fR is called on
a variable, its value is saved somewhere, and will be restored upon exiting
the scope of the rule. Then the new value is affected to the variable.
.PP
Variables requiring a side effect when their value is changed (such as the
umask variable, which requires a system call to let the kernel see the change)
may specify it by accessing the \fI%env'Spec\fR array, the key being the
name of the variable requiring a side effect, the value being interpreted
as a bit of perl code ran once the original value is restored. For instance,
we say somewhere (in \fI&env'init\fR):
.Ex
	package env;
	\$Spec{'umask'} = 'umask(\$umask)';
.Ef
to update the kernel view when leaving scope. Note that the side effect is
evaluated once the variable has recovered its original value, and within
the \fIenv\fR package.
.PP
Internally, the \fI&analyze_mail\fR
routine calls \fI&env'setup\fR before starting
its processing to initialize the \fIenv\fR package, and \fI&env'cleanup\fR
at the end before returning. Before running the actions specified on a rule
match, \fI&apply_rules\fR calls \fI&env'restore\fR to ensure a coherent
view of the environment while running the actions for that particular rule.
'''
.SS Altering Control Flow
.PP
When you want to alter control flow to perform a REJECT, a RESTART or an
ABORT, you have three choices. If you wish to control that action via an
option, the same way the standard UNIQUE does (with \fB\-c\fR, \fB\-r\fR or
\fB\-a\fR), you may call \fI&main'alter_execution(option, mode)\fR giving it
two parameters: the option letter and the mode you wish to change to before
altering the control flow.
.PP
You may also want to directly alter the \fI\$wmode\fR and \fI\$cont\fR variables,
but then you'll have to do your own logging if you want some. Or you may
call low-level routines \fI&main'do_reject\fR, \fI&main'do_restart\fR and
\fI&main'do_abort\fR to perform the corresponding operation (with logging).
.PP
Remember that the mode _SEEN_ is special and directly handled at the
filter level, and the filter begins in the INITIAL mode. The default
action is to continue with the current rule, which is why there is no
routine to perform this task.
.PP
The preferred way is to invoke the \fImailhook\fR interface functions,
\fI&mailhook'begin\fR, \fI&mailhook'reject\fR, etc..., and that will work
even if you redefine those functions yourself. Besides, that's the only
interface which is likely not to be changed by new versions.
'''
.SS General Purpose Routines
.PP
The following is a list of all the general routines you may wish to call when
performing some low-level tasks. Note that this information is
version-dependent. Since I document them, I'll try to keep them in new
versions, but I cannot guarantee I will not have to slightly change some
of their semantics. There is a good chance you will never have to worry about
that anyway.
.sp
.TP 10
.I &header'format(rfc822-field)
Return a formatted RFC822 field to fit in 78 columns, with proper
continuations introduced by eight spaces.
.TP
.I &header'normalize(rfc822-header-name)
Normalize case in RFC822 header and return the new header name with every
first letter uppercased.
.TP
.I &header'reset
This is part of an RFC822 header validation, mainly used when splitting a
digest. This resets the recognition automaton (see &header'valid).
.TP
.I &header'valid(line)
Returns a boolean status, indicating if all the lines given so far to this
function since the last \fI&header'reset\fR are part of a valid RFC822 header.
The function understands the first From line which is part of UNIX mails.
At any time, the variable \fI\$header'maybe\fR may be checked to see if
so far we have found at least one essential mail header field.
.TP
.I &main'acs_rqst(file)
Perform a .lock locking on the file, returning 0 on success and -1 on failure.
If an old lock was present, it is removed (time limit set to one hour). Use
\fI&main'free_file\fR to release the lock.
.TP
.I &main'add_log(string)
Add the \fIstring\fR to the logfile. The usual idiom is to postfix that call
with the \fIif \$'loglvl > value\fR, where \fIvalue\fR is the logging
level you wish to have before emitting that kind of log (\fI$'loglvl\fR is
a short form for \fI\$main'loglvl\fR).
.TP
.I &main'free_file(file)
Remove a .lock on a file, obtained by \fI&main'acs_rqst\fR. It returns 0 if
the lock was successfully removed, -1 if it was a stale lock (obtained by someone
else).
.TP
.I &main'header_found(file)
Scan the head of a file and try to determine whether there is a mail header
at the beginning or not. Return true if a header was found.
.TP
.I &main'history_record
Record the message ID of the current message and return 0 if the message had
not been previously seen, 1 if it is a duplicate.
.TP
.I &main'hostname
Return the value of the hostname, lowercased, with possible domain name
appended to it.
The hostname is cached, since its value must initially be obtained by forking.
(see also \fI&main'myhostname\fR)
.TP
.I &main'internet_info(email-address)
Parse an e-mail internet address and return a three-element array containing
the host, the domain and the country part of the internet host. For instance,
if the address is \fIuser@d.c.b.a\fR, it will return \fI(c, b, a)\fR.
.TP
.I &main'login_name(email-address)
Parse the e-mail internet address and return the login name.
.TP
.I &main'macros_subst(*line)
Perform in-place macro substitution (line passed as a type glob) using
the information currently held in the \fI%main'Header\fR array. Do \fInot\fR
pass \fI*_\fR as a parameter, since internally \fImacros_subst\fR uses a local
variable bearing that name to perform the substitutions and you would end up
with an unmodified version. If you really want to pass \fI*_\fR, then you must
use the returned value from \fImacros_subst\fR which is the substituted text,
but that's less efficient than having it modified in place.
.TP
.I &main'makedir(pathname, mode)
Make directory, creating all the intermediate directories needed to make
\fIpathname\fR a valid directory. Has no effect if the directory already
exists. The mode parameter is optional, 0700 is used (octal number) if not
specified.
.TP
.I &main'myhostname
Returns the hostname of the current machine, without any domain name.
The hostname is cached, since its value must initially be obtained by forking.
.TP
.I &main'run_command(filter-command)
Execute the single filter command specified and return the continuation
status, which should normally be affected to the \fI\$cont\fR variable. You
will need this routine when trying to implement commands which encapsulate
other commands, like ONCE or SELECT.
.TP
.I &main'seconds_in_period(period)
Return the number of seconds in the period specified. See section \fISpecifying
A Period\fR to get valid period strings.
.TP
.I &main'shell_command(program, input, feedback)
Run a shell command and return a failure status (0 for OK). The input parameter
may be one of the following constants (defined in the \fImain\fR package):
\$NO_INPUT to close standard input, \$BODY_INPUT to pipe the body of the
current message, \$MAIL_INPUT to pipe the whole mail and \$HEADER_INPUT to
pipe the message header. The feedback parameter may be one of \$FEEDBACK or
\$NO_FEEDBACK depending whether or not you wish to use the standard output
to alter the corresponding part of the message. If no feedback is wanted, the
output of the command is mailed back to the user.
.TP
.I &main'parse_address(rfc822-address)
Parse an RFC822 e-mail address and return a two-elements array containing the
internet address and the comment part of that address.
.TP
.I &main'xeqte(filter-actions)
Execute a series of actions separated by the ';' character, calling
\fIrun_command\fR to actually perform the job. Return the continuation status.
Note that \$FT_ABORT will \fInever\fR be returned, since mailagent
usually stops after having executed one set of actions, only continuing
if it saw an RESTART or a REJECT. What ABORT does is skipping the remaining
commands on the line and exiting as if all the commands had been run. You
could say \fIxeqte\fR is the equivalent of the \fIeval\fR function in perl,
since it interprets a little filter script and returns control to the caller
once finished, and ABORT is perl's \fIdie\fR.
.PP
You may also use the three functions from the \fIextern\fR package which
manipulate persistent variables (already documented in the section dealing
with variables) as well as the user-defined macro routines.
'''
.SS Example
.PP
Writing your own commands is not easy, since it requires some basic knowledge
regarding mailagent internals. However, once you are familiar with that,
it should be relatively straightforward.
.PP
Here is a small example. We want to write a command to bounce back a mail
message to the original sender, the way sendmail does, with some leading
text to explain what happened. The command would have the following syntax:
.Ex
SENDBACK \fIreason\fR
.Ef
and we would like that command to modify the existing status, returning
a failure if the mail cannot be bounced back. Since this command actually
sends something back, we do not want it to be executed in _SEEN_ mode.
Here is my implementation (untested):
.Ex
sub sendback {
	local(\$cmd_line) = @_;
	local(\$reason) = join(' ', @ARGV[1..\$#ARGV]);
	unless (open(MAILER, "|/usr/lib/sendmail -odq -t")) {
		&'add_log("ERROR cannot run sendmail to send message")
			if \$'loglvl;
		return 1;
	}
	print MAILER <<EOF;
From: mailagent
To: \$header{'Sender'}
Subject: Returned mail: Mailagent failure
\$main'FILTER

  --- Transcript Of Session

\$reason

  --- Unsent Message Follows

\$header{'All'}
EOF
	close MAILER;
	\$ever_saved = 1;	# Don't want it in mailbox
	\$? == 0 ? 0 : 1;	# Failure status
}
.Ef
Assuming this command is put into ~/mail/cmds/sendback.pl, the line
describing it in the \fInewcmd\fR file would be:
.Ex
SENDBACK  ~/mail/cmds/sendback.pl  sendback  yes  no
.Ef
Now this command may be used freely in any rule, and will be logged
as a user-defined command by the command dispatcher. Who said it was
not easy to do? :-)
.PP
Note the use of the \$ever_saved variable to mark the mail as saved once
it has been bounced. Indeed, should the SENDBACK action be the only one
action to be run, we do not want mailagent to LEAVE the mail in the
mailbox because it has never been saved (this default behavior being
a precaution only -- better safe than sorry).
'''
.SS Conclusion
.PP
If along the way you imagine some useful commands which could be made
part of the standard command set, please e-mail them to me and I'll
consider integrating them. In the future, I would also like to provide
a standard library of perl scripts to implement some weird commands which
could be needed in special cases.
.PP
Note that you may also use the information presented here inside the
perl escape scripts. Via the \fIrequire\fR operator, it is easy to get
the new command implementation into your script and perform the same task.
You will maybe need to set up @ARGV by yourself if you rely on that
feature in your command implementation.
.PP
Command extension can also be viewed as a way to reuse some other perl
code, the mailagent providing a fixed and reliable frame and the external
program providing the service. One immediate extension would be mailing
list handling, using this mechanism to interface with some mailing list
management software written in perl.
'''
''' G e n e r i c   M a i l   S e r v e r
'''
.SH GENERIC MAIL SERVER
.PP
One nice thing about mailagent is that it provides you with the basic tools to
implement a generic mail server. Indeed, via the SERVER command, you can
process a mail message, extract and then execute some predefined commands.
For instance, you may implement an archive server, or a mailing list
manager, etc...
.PP
The major limitation currently is that only plain commands are accepted,
or commands taking some additional info as \fIstandard input\fR or
equivalent. There is no notion of modes, with separate command sets for
each mode or limited name-space visibility, at least for now, so it is not
easy (albeit possible) to implement an ftpmail server, for instance, since
this implies the notion of mode.
'''
.SS Overview
In order to implement a mail server command (say send \fIfile\fR, which
would send an arbitrary file from the file system in a separate mail message),
you need to do the following:
.IP \(bu 5
Think about the command from a security point of view. Here, the command we
want to implement is a potentially dangerous one since it can give access
to any file on the machine the individual running \fImailagent\fR has access to.
So we want to restrict that command to a limited number of trusted people,
who will be granted the \fIpower\fR to run this command. More on this later.
.IP \(bu
Choose whether you want to implement the command in perl or in another
programming language. If you do the latter, your command will be known as
a \fIshell\fR command (i.e. a command runnable directly from a shell), while
in the former case, you have the choice of making it appear as a \fIshell\fR
command, or have it hooked to the \fImailagent\fR in which case it is known
as a \fIperl\fR command. In that last case, your command will be dynamically
loaded into mailagent with all the advantages that brings you. Here, we are
going to write our command as a shell script.
.IP \(bu
Write the command itself. That's the most difficult part in this scheme.
Later on, we will see a straightforward implementation of the \fIsend\fR
command.
.IP \(bu
Edit the \fIcomserver\fR file (defined in your \fI~/.mailagent\fR) to
record your new command. Then make sure this file is tightly protected.
You must own it, and be the only one allowed to modify it.
.IP \(bu
Additionally, you may want to hide some of the arguments in the session
transcript (more on this later), allow the command to take a flow of
data as its \fIstandard input\fR, assign a path to the command, etc...
All those parameters take place in your \fIcomserver\fR file.
.IP \(bu
Start using the command... which of course is the nicest part in this scheme!
.PP
In the following sections, we'll learn about the syntax of the \fIcomserver\fR
file, what \fIpowers\fR are, how the session transcript is built, what the
command environment is, etc...
'''
.SS Builtin Commands Overview
.PP
The mail server has a limited set of builtin commands, dealing with user
authentication and command environment settings. User authentication
is password based and is not extremely strong since passwords are specified
in clear within the mail message itself, which could be easily intercepted.
.PP
The server maintains the notion of \fIpowers\fR. One user may have more
than one power at a time, each power granting only a limited access to
some sensitive area. A few powers are hardwired in the server, but the
user may create new ones when necessary. Those powers are software-enforced,
meaning the command must check for itself whether is has the necessary
power(s) to perform correctly.
.PP
Powers are protected by a password and a clearance file. Having the good
password is not enough, you have to be cleared in order to (ab)use it. The
clearance file is a list of e-mail address patterns, using the shell
metacharacters scheme, someone being cleared
if and only if his e-mail address matches at least one of the patterns from
the clearance file. The more use you will make of metacharacters, the weaker
this clearance scheme will be, so be careful.
.PP
Your commands and the output resulting from their execution is normally
mailed back to you as a session transcript. For security reasons, passwords
are hidden from the command line. Likewise, failure to get a power will not
indicate whether you lacked authorization or whether your password was bad.
.PP
A user with the \fIsystem\fR power is allowed to create new powers, delete
other powers, change power passwords, and list, remove or change power
clearances. This is somehow an important power which should be detained by
a small number of users with very strict clearance (no meta-characters in
the address, if possible). A good password should also protect that power.
.PP
However, a user with the \fIsystem\fR power is not allowed to directly get
another power without specifying its password and being allowed to do so by the
associated clearance file. But it would be possible to achieve that indirectly
by removing the power and creating a new one bearing the same name. In order
to control people with the \fIsystem\fR power and also for some tricky
situation, there is another more god-like power: the \fIroot\fR power.
.PP
A user with the \fIroot\fR power can do virtually anything, since it
instantly grants that individual \fIall\fR the powers available on the
server (but \fIsecurity\fR). The only limitation is that \fIroot\fR
cannot remove the \fIroot\fR
power alone. One needs to specify the \fIsecurity\fR password (another
hardwired power) in order to proceed. Needless to say, only \fBone\fR
individual should have both \fIroot\fR and \fIsecurity\fR clearance, and
only one individual should know the \fIsecurity\fR password and be listed
in the clearance file. The \fIsystem\fR power cannot harm any of those
two powers. Eventually, more than one user could have the \fIroot\fR power,
but do not grant that lightly...
.PP
Getting the \fIroot\fR power is necessary when \fIsystem\fR has messed with
the system configuration in an hopeless way, or when a long atomic sequence
of commands has to be issued: \fIroot\fR is not subject to the maximum
number of command that can be issued in one single message.
.PP
In case you think this \fImailagent\fR feature is dangerous for your account,
do not create the \fIroot\fR and \fIsecurity\fR powers, and do not write
any sensitive commands.
'''
.SS Builtin Commands Definition
.PP
Now let's have a look at those builtin commands. Passwords of sensitive
commands will be concealed in the session transcript. Some commands accept
input by reading the mail message up to the \fIEOF\fR marker, which is a
simple EOF string on a line by itself (analogous with shell's \fIhere
documents\fR).
.sp
.TP 10
.I addauth power password
Add users to clearance file for \fIpower\fR. If the power password is given,
no special power is needed, otherwise the \fIsystem\fR power is required.
For \fIroot\fR or \fIsecurity\fR powers, the corresponding power is
required, or the
\fIpassword\fR must be specified. The command reads the standard input
up to the EOF marker to get the new users.
.TP
.I approve password command
Records the password in the command environment, then executes the command.
If a power is required and not yet obtained, the command will look for the
password in the environment and try to get the relevant power using that
password. Hence, approved command (with proper password)
will transparently execute without the hassle of requesting the power,
issuing the command and then releasing the power. It is up to the command
to perform the \fIapprove\fR password test by looking at the \fIapprove\fR
variable in the command environment (see below). Since clearance checks
(such as those performed when requesting a power) are not performed, no
sensitive command should ever deal with the \fIapprove\fR construct.
.TP
.I delpower power password [security]
Delete a power from the system, and its associated clearance list. The
\fIsystem\fR power is required to delete most powers except \fIroot\fR and
\fIsecurity\fR. The \fIsecurity\fR power may only be deleted by itself and
the \fIroot\fR power may only be deleted when the \fIsecurity\fR password
is also specified.
.TP
.I getauth power password
Get current clearance file for a given power. No special power required if
the password is given or the power is already detained. Otherwise, the system
power is needed for all powers but \fIroot\fR or \fIsecurity\fR where the
corresponding power is mandatory.
.TP
.I newpower power password [alias]
Add a new power to the system. The command then reads the standard mail input
until the EOF marker to get the power clearance list. The \fIsystem\fR power
is required to create a new power, unless it's \fIroot\fR or \fIsecurity\fR:
The \fIsecurity\fR power is required to create \fIroot\fR and the \fIroot\fR
power is required to create \fIsecurity\fR.
.TP
.I passwd power old new
Change power password. It does not matter if you already hold the corresponding
power, you must give the proper old password. See also the \fIpassword\fR
command.
.TP
.I password power new
Change power password. The corresponding power is required, or you have to get
the \fIsystem\fR power. To change the \fIroot\fR or \fIsecurity\fR passwords,
you need the corresponding power.
.TP
.I power name password
Ask for a new power. Of course, \fIroot\fR does not need to request for any
other power but \fIsecurity\fR, less give any password. This command is not
honored when the server is not in trusted mode, unbeknownst to the user:
the error message in the transcript file is no different from the one
obtained with an invalid password.
.TP
.I powers regexp
List all the powers matching the perl regular expression, along with their
respective clearance file. The \fIsystem\fR power is required to get the list.
The \fIroot\fR or \fIsecurity\fR power are required to get access to the
\fIroot\fR or \fIsecurity\fR information, respectively.
If no arguments are given, all the powers are listed.
.TP
.I release power
Get rid of some power.
.TP
.I remauth power password
Remove users from clearance file, getting the list by reading the standard
mail input until the EOF marker. This command does not require any special
power if the proper password is given or if the power is already detained.
Otherwise, the \fIsystem\fR power is needed. For \fIroot\fR and \fIsecurity\fR
clearance, the corresponding power is needed as well.
.TP
.I set variable value
Set the variable to the corresponding value. Useful to alter internal
variables like the EOF marker value, or change some command environment.
The user may define his own variables for his commands.
For \fIflag\fR-type variable, a value of \fIon\fR, \fIyes\fR or \fItrue\fR sets
the variable to \fI1\fR, any other string sets it to \fI0\fR (false).
Used all by itself as \fIset\fR, the list of all the defined variables along
with their respective values is returned.
.TP
.I setauth power password
Replace power clearance file with one obtained from standard mail input up to
the EOF mark. The \fIsystem\fR power is needed unless you specify the proper
password or the power is already yours. As usual, \fIroot\fR or \fIsecurity\fR
clearances can only be changed when the power is detained.
.TP
.I user [e-mail [command]]
Execute command by assuming the e-mail identity specified. Powers are lost
while executing the command. The e-mail identity may be checked by the
command itself, which may impose further restrictions on the execution, like
getting user-defined powers. Note that this command only modifies the global
environment, and that it's up to the \fIcommand\fR implementation to make
use of that information. If no command is specified, the new identity is
assumed until changed by another \fIuser\fR command and all the powers
currently held by the user are released. If no \fIe-mail\fR address
is given, the original user ID is restored.
'''
.SS Command Environment
.PP
There are six types of commands and variables that can be specified in server
mode. Two of them, \fIend\fR and \fIhelp\fR types are special and handled
separately. Two types \fIvar\fR and \fIflag\fR refer to variables and the last
two types \fIperl\fR and \fIshell\fR refer to commands.
.PP
Whenever mailagent fires a server command, it sets up an environment for that
command: if it is a \fIperl\fR-type command, then a set of perl variables are
set before loading the command; if it is a \fIshell\fR-type command, some
environment variables are initialized and file descriptor #3 is set up to
point directly to the mailagent session transcript.
.PP
A \fIshell\fR-type command is forked, whilst a \fIperl\fR-type command is
loaded directly in \fImailagent\fR within the \fIcmdenv\fR package. This
operates much like the PERL filtering command, only the target package differs
and a distinct set of variables is preset.
.PP
Some commands collect additional data up to an end-of-file marker (by default
the string \fBEOF\fR on a line by itself) and those data are fed to shell
commands via \fIstdin\fR and to perl commands via the \fI@buffer\fR variable
set up in the environment package named \fIcmdenv\fR (in which the command is
loaded and run).
.PP
If you define your own variables (types \fIvar\fR or \fIflag\fR), you may
use the builtin \fIset\fR command to modify their values. Note that no default
value can be provided when defining your variable. A suitable default value
must be set within commands making use of them, with the advantage that
different default values may be used by different commands.
.PP
The following \fIenvironment\fR variables are defined. Most are read-only,
unless notified otherwise, in which case the builtin \fIset\fR command may
be used on them.
.TP 10
.I approve
The approve password for \fIapprove\fR commands, empty if not within a
builtin \fIapprove\fR construct.
.TP
.I auth
A flag set to true when a valid envelope was found in the mail message.
When this flag is false, the server cannot be put in trusted mode.
.TP
.I cmd
The command line, as written in the message.
.TP
.I collect
Internal flag set to true while collecting input from a here-document.
It is normally reset to false before calling the command.
.TP
.I debug
True when debug mode is activated (may be set).
.TP
.I disabled
A comma separated list of disabled commands, with no space between them.
This is initialized when the SERVER command is invoked and the \fB\-d\fR
option is used.
.TP
.I eof
The current end-of-file marker for here-document commands. By default set
to 'EOF' (may be changed).
.TP
.I errors
Number of errors so far.
.TP
.I jobnum
The job number assigned to the current mailagent.
.TP
.I log
What was logged in the transcript, with some args possibly concealed.
.TP
.I name
The command name.
.TP
.I pack
Packing mode for file sending (may be set).
.TP
.I path
Destination address for file sending or notification (may be set).
.TP
.I powers
A colon (:) separated list of powers the user currently has successfully
requested and got.
.TP
.I requests
Number of requests processed so far.
.TP
.I trace
True when shell commands want to be traced in transcript (may be set).
.TP
.I trusted
True when server is in trust mode, where powers may be gained. This
is activated by the \fB\-t\fR option of the SERVER command, provided a
valid mail envelope was found.
.TP
.I uid
Address of the sender of the message, where transcript is to be sent. By
extension, the real user ID for the server, which is the base of the power
clearance mechanism.
.TP
.I user
The effective user ID, originally the same as the uid, but may be changed
via the \fIuser\fR builtin command.
'''
.SS Session Transcript
.PP
A session transcript is mailed back automatically to the user who requested
a server access. This transcript shows the commands ran by the user and their
status: \fIOK\fR or \fIFAILED\fR. Between those two lines, the transcript show
any output explicitly made by the command to the transcript. Typically, the
transcript may be used to forward error messages back to the user, but even
commands executing correctly may want to issue an explicit message, stating
what has just been done.
.PP
A perl command may access the transcript via the \fIMAILER\fR file handle,
defined in the \fIcmdenv\fR package, whilst a shell command may access it via
its file descriptor #3.
.PP
Note that the session transcript is mailed to the \fIsender\fR of the message,
i.e. whoever the envelope header line says it is. As
far as the server is concerned, this e-mail address is used as the user ID,
just like a plain login name can be thought of as the user id. For sensitive
commands, authentication based on that information is really weak. A more
"secure" authentication is provided by the server powers, which is
password-based. Unfortunately, the clear password has to be transmitted in the
message itself and could be eavesdropped.
'''
.SS Recording New Commands and Variables
.PP
Server commands and variables are defined in the \fIcomserver\fR file defined
in your \fI~/.mailagent\fR. The format of the file is that of a table with
items on a row separated by tabs characters. Each line defines one command
or variable. Any irrelevant field may be entered as a single '-' (minus)
character. The format allows for shell-style (#) comments.
.PP
Each row has the following fields:
.Ex
\fIname type hide collect-data path extra\fR
.Ef
where:
.TP 15
.I name
is the name of the command or variable as recognized by the server.
.TP
.I type
is one of \fIperl\fR, \fIshell\fR, \fIvar\fR, \fIflag\fR, \fIhelp\fR
or \fIend\fR.
.TP
.I hide
indicates which arguments in the command are to be hidden (the command name
being argument zero) in the session transcript. Use '-' if no arguments
need to be hidden. Typically, this is used to hide clear passwords in commands.
If more than one argument has to be hidden, then a list of numbers separated
by a ',' (comma) may be specified, with \fBno spaces\fR between them. For
instance '2,4' would hide arguments 2 and 4 in the transcript.
.TP
.I collect-data
is a flag (specify as either 'y' or 'n', but you may use complete words 'yes'
or 'no') indicating whether the command collects additional data in a
here-document until the EOF marker. Alternatively, you may specify '-' in place
of 'n'.
.TP
.I path
specifies the path of the command (~name substitution allowed). If not relevant
(e.g. when defining a variable) or when you want to leave it blank, use '-'.
If a blank path is specified for a \fIperl\fR or \fIshell\fR command, then
the implementation of that command is expected to be found in \fIservdir\fR,
as defined in \fI~/.mailagent\fR. If the command name is \fIcmd\fR for instance,
then perl command are expected there in a file named \fIcmd\fR of \fIcmd.pl\fR,
whereas shell commands are expected to be found in a \fIcmd\fR of \fIcmd.sh\fR
file. Note that a command is disabled if it cannot be located at the time
the \fIcomserver\fR file is parsed.
.TP
.I extra
is any extra parameter needed for the command. Unlike other fields, this
should be left blank if not needed. Anything up to the end of the line is
grabbed by this field. Perl commands should specify the name of the perl
function to call to execute the command; if none is specified, the name of
the command itself is called. Shell commands may use that field to supply
additional options, which will be inserted right after the command name and
before any other user-supplied arguments. Others should leave this alone.
'''
.SS Special Command Types
.PP
There are currently two special command types.
.PP
The simplest is the \fIend\fR type. This is used to specify commands which may
end the server processing. By default, processing continues until the end
of the file is reached or a signature delimiter '--' is found. For instance,
you may wish to define the command \fIquit\fR and give it the \fIend\fR type.
As soon as the server reaches that command, it aborts processing and discards
the remaining of the message.
.PP
The \fIhelp\fR type is usually attached to an \fIhelp\fR command and prints
help on a command basis, help for each command being stored under the
\fIhelpdir\fR variable (defined in your ~/.mailagent) in a file bearing the
same name as the command itself. For example, assuming a command \fIshoot\fR,
its help file would be expected in \fIhelpdir/shoot\fR. If no file is found
there, mailagent looks in its public library ($privlibexp) for an help file.
Help is provided only when the help file exists and is not zero-sized.
'''
.SS Creating the Root Power
.PP
In order to bootstrap the server, you need to create the root power. All the
other powers may then be created by using the server interface, which ensures
consistency and logs your actions. If you don't plan using powers at all, you
may skip that section.
.PP
First, you need to pick up a good password for the \fIroot\fR power. Someone
with the \fIroot\fR power can do virtually anything with the server, so be
careful. Let's assume you choose \fIroot-pass\fR as a password.
.PP
Edit \fIpasswd\fR (defined in your \fI~/.mailagent\fR) and add the following
line:
.Ex
root:<root-pass>:
.Ef
i.e. enter the password in clear between '<' and '>'. It won't stay in that
form for long, but this is the easiest way to bootstrap it. Protect the
\fIpasswd\fR file tightly (read-write permissions only for you). Then create
a \fIpowerdir/root\fR file, protect it the same way and add your e-mail
address to it, on a line by itself. That \fBmust\fR be the address that
will show up in the \fIFrom:\fR line of your mails. Since clearance files
support shell-style patterns, you may use \fIlogin@*domain.top\fR to allow
mails from your login from any machine in your domain.
.PP
You are almost done. Now simply issue the following command:
.Ex
mailagent -i -e 'SERVER -t'
.Ef
and feed its standard input with:
.Ex
From \fIyour e-mail address\fR
From: \fIyour e-mail address\fR

power root root-pass
password root root-pass
^D
.Ef
Note that the first \fIFrom\fR line is mandatory here, since it's the
envelope on which authentication is based. Since we're feeding mailagent
with an handcrafted message, we must provide a valid envelope or the
server will not switch into trusted mode...
.PP
The side effect of re-instantiating your password will be to crypt it in
the \fIpasswd\fR file, so that anybody looking at that file cannot guess
your \fIroot\fR password, hopefully.
.PP
Once you have a valid \fIroot\fR power installed, you may create the
\fIsystem\fR power by using \fInewpower\fR. Further powers may then be
created and deleted using the \fIsystem\fR power only.
.PP
You should also create the \fIsecurity\fR power and give it a different
password than the \fIroot\fR password. This is really needed only if you wish
to remotely administrate the server. If you have local access and things
get corrupted, it's always possible to change the root password manually by
repeating this bootstrapping sequence.
.PP
Note that clearance checks are made using the envelope address of the message,
which is a little harder to forge than plain header fields like \fISender:\fR.
The envelope is extracted by looking at the first header line, which on Unix
systems looks like:
.Ex
	From \fIenvelope-address send-date\fR
.Ef
and is inserted by the mail transport agent (MTA). If you are using
\fIsendmail\fR as the MTA, then only \fItrusted\fR users declared in the
\fIsendmail.cf\fR file are able to create a "fake" envelope address, a
feature typically used by mailing list dispatchers, since that address is then
used as the bounce target in case the mail cannot be delivered.
If that first header line is absent, the
sender is computed using the \fISender:\fR field if present, then
the \fIFrom:\fR field, but the \fIauth\fR variable is set to false and the
server will not switch into trusted mode; in other words, it will not be
possible to gain powers in that session.
.PP
Moreover, since the session transcript is sent to that same envelope address
used to authenticate the eligibility for a power, the server feature can
hardly be used to retrieve confidential information held at the site where
the \fImailagent\fR is run since the information would be sent to one of the
users cleared for that power. It is the responsibility of you, the user, to
make sure this cannot happen or you could get into legal troubles.
.PP
Finally, sensitive commands should be protected by a proper power, and great
care should be taken in writing the command implementation to ensure the
security cannot be circumvented. But no, this mailagent feature is not
believed to be dangerous for the system or site it is used on, since a
determined user could implement one trivially via a five line shell script.
If security is really an issue, \fI.forward\fR files using the piping feature
should be prohibited and access to \fIcron\fR forbidden in order to avoid
automatic mail processing (since it would be possible to have cron invoke
a \fImailagent\fR process \-or any other program for that matter\- to process
the incoming mail in a comparable way).
'''
.SS Example
.PP
Here is an example showing the steps involved in creating a \fIshell\fR
command, which would take a script by collecting lines until an EOF mark
and feed it to a real shell for execution. Since allowing this feature
without any safeguards would be a real security hole, we protect that by
requesting the power \fIshell\fR before allowing the execution.
.PP
Here is my implementation of the \fIshell\fR command (available in the
mailagent distribution under \fImisc/shell\fR):
.Ex
#!/bin/sh

# Execute commands from stdin, as transmitted by the mailagent server.
# File descriptor #3 is a channel to the session transcript.

# Make sure we have the shell power.
# Don't even allow the root power to bypass that for security reasons.
case ":\$powers:" in
*:shell:*) ;;
*)
	echo "Permission denied." >&3
	exit 1
	;;
esac

# Perhaps a shell was defined... Otherwise, use /bin/sh
case "\$shell" in
\&'') shell='/bin/sh';;
esac

# Normally, a shell command has its output included in the transcript only in
# case of error or when the user requests the trace. Here however, we need to
# see what happened, so everything is redirected to the session transcript.

exec \$shell -x >&3 2>&3
.Ef
.PP
Note how we make access to the \fI\$powers\fR and \fI\$shell\fR environment
variable. That last one is user-defined to allow dynamic set-up of a shell.
.PP
Assuming we store that command under \fIservdir/shell.sh\fR (don't forget to
add the execution bit on the file...), here is how
we declare it and its variable in the \fIcomserver\fR file.
.Ex
shell	shell	-	y	-
shell	var	-	-	-
.Ef
This example shows that there is a separate name-space for variables and
commands. Moreover, the command bears the same name as its type -- don't let
that confuse you :-).
.PP
Now, assuming you have already created a \fIsystem\fR power and protected
it with a password (let's assume \fIsys-pass\fR for the purpose of this
example), you need to create the shell power. Although you could do it
manually (like when you handcrafted the \fIroot\fR power), it's better to
use the SERVER interface since it ensures consistency.
.PP
In order to create the \fIshell\fR power required to use the newly created
\fIshell\fR command, you need to add the following rule to your rule file:
.Ex
Subject: Server		{ SAVE server; SERVER -t };
.Ef
which will save all server mail in a dedicated folder and process them. Note
the \fB\-t\fR option, which allows trusted mode, in which powers may be gained.
Now send yourself the following mail:
.Ex
Subject: Server
power system sys-pass
newpower shell shell-pass
ram@acri.fr
EOF
.Ef
which requests for the \fIsystem\fR power (needed to created most powers),
and then creates a new power \fIshell\fR, assigning \fIshell-pass\fR as its
password and clearing \fIram@acri.fr\fR for it. Note the here-document
fill-in for the newpower command, up to the EOF marker. Of course, you need
to replace the address by your real address.
.PP
You will receive a session transcript along these lines:
.Ex
    ---- Mailagent session transcript for ram@acri.fr ----

----> power system ********
OK.

====> newpower shell ********
OK.

====> --
End of processing (.signature)

    ---- End of mailagent session transcript ----
.Ef
Note the concealed passwords, and the prompt change once the system
power has been granted. Since my mailer automatically appends a signature,
the processing stops on it.
.PP
Now let's use this new command... Send yourself the following mail:
.Ex
Subject: Server
set shell /bin/ksh
set eof END
shell
ls -l /etc/passwd
END
power shell shell-pass
shell
ls -l /etc/passwd
END
.Ef
If you everything is right, you should receive back a transcript looking
like this:
.Ex
    ---- Mailagent session transcript for ram@acri.fr ----

----> set shell /bin/ksh
OK.

----> set eof END
OK.

----> shell
Permission denied.
Command returned a non-zero status (1).
FAILED.

----> power shell ********
OK.

====> shell
+ ls -l /etc/passwd
-rw-r--r--   1 root     system       691 Oct 01 14:24 /etc/passwd
OK.

====> --
End of processing (.signature)

    ---- End of mailagent session transcript ----
.Ef
The first invocation of the \fIshell\fR command fails since we lack the
\fIshell\fR power. The string "Permission denied." is echoed by the
command itself into file descriptor #3 and makes it to the transcript.
'''
.SS Conclusion
.PP
The generic mail server implemented in mailagent can be used to
implement a mailing list manager, a vote server, an archive server, etc...
Unfortunately, it does not currently have the notion of state, with a command
set dedicated to each state, so it is not possible to implement an intelligent
archive server.
.PP
If you implement new simple server commands and feel they are generic enough
to be contributed, please send them to me and I will gladly integrate them.
.SH EXAMPLES
Here are some examples of rule files. First, if you do not specify a rule
file or if it is empty, the following built-in rule applies:
.Ex
All: /^Subject: [Cc]ommand/ { LEAVE; PROCESS };
.Ef
Every mail is left in the mailbox. Besides, mail with "Subject: Command"
anywhere in the message are processed.
.PP
The following rule file is the one I am currently using:
.Ex
maildir = ~/mail;

All: /^Subject: [Cc]ommand/	{ SAVE cmds; PROCESS };

To: gue@eiffel.fr		{ POST -l mail.gue };
Apparently-To: ram,
Newsgroups: mail.gue		{ BOUNCE gue@eiffel.fr };

<_SEEN_>
	Apparently-To: ram,
	Newsgroups: mail.gue	{ DELETE };

From: root, To: root		{ BEGIN ROOT; REJECT };
<ROOT> /^Daily run output/	{ WRITE ~/var/log/york/daily.%D };
<ROOT> /^Weekly run output/	{ WRITE ~/var/log/york/weekly };
<ROOT> /^Monthly run output/	{ WRITE ~/var/log/york/monthly };

From: ram		{ BEGIN RAM; REJECT };
<RAM> To: ram		{ LEAVE };
<RAM> X-Mailer: /mailagent/	{ LEAVE };
<RAM>			{ DELETE };
.Ef
.PP
The folder directory is set to \fI~/mail\fR. All command mails are saved
in the folder \fI~/mail/cmds\fR and processed. They do not show up in
my mailbox. Mails directed to the \fIgue\fR mailing list (French Eiffel's
Users Group, namely Groupe des Utilisateurs Eiffel) are posted on the local
newsgroup \fImail.gue\fR and do not appear in my mailbox either. Any follow-up
made on this group is mailed to me by \fIinews\fR (and not directly to the
mailing list, because those mails would get back to me again and be fed to the
newsgroup, which in turn would have them mailed back to the list, and so on,
and so forth).
Hence the next rule which catches those follow-ups and bounces them to the
mailing list. Those mails will indeed come back, but the _SEEN_ rule will
simply delete them.
.PP
On my machine, the mails for \fIroot\fR are forwarded to me. However,
everyday, the \fIcron\fR daemon starts some processes to do some
administration clean-up (rotating log files, etc...), and mails the results
back. They are redirected into specific folders with the WRITE command, to
ensure they do not grow up without limit. Note the macro substitution for the
daily output (on Mondays, the output is stored in \fIdaily.1\fR for instance).
.PP
The next group of rules prevents the mail system from sending back mails when
I am in a group alias expansion. This is a \fIsendmail\fR option which I
disabled on my machine. Care is taken however to keep mails coming from the
mailagent which I receive as a blind carbon copy.
.SH CAVEAT
In order to limit the load overhead on the system, only \fBone\fR mailagent
process is allowed to run the commands. If some new mail arrives while another
mailagent is running, that mail is queued and will be processed later by the
\fImain\fR mailagent.
.PP
For the same reason, messages sent back by mailagent are queued by
\fIsendmail\fR, to avoid the cost of mail transfer while processing commands.
.SH "SECURITY"
First, let me discuss what \fIsecurity\fR means here. It does \fBnot\fR mean
system safety against intruder attacks. If your system allows \fI.forward\fR
hooks and/or \fIcron\fR jobs to be set by regular users, then your system is
not secure at all. Period. So we're not bothering with security at the
system level, but rather at your own account level where all sort of precious
data is held.
.PP
To avoid any pernicious intrusion via Trojan horses, the C \fIfilter\fR will
refuse to run if the configuration
file \fI~/.mailagent\fR or the rule file specified are world writable or not
owned by the user. Those tests are enforced even if the \fIfilter\fR does
not run setuid, because they compromise the security of your account.
The \fImailagent\fR will also perform some of those checks, in case it is
not invoked via the C \fIfilter\fR.
.PP
Indeed, if someone can write into your \fI~/.mailagent\fR file, then he can
easily change your \fIrules\fR configuration parameter to point to another
faked rule file and then send you a mail, which will trigger mailagent,
running as you. Via the RUN command, this potential intruder could run any
command, using your privileges, and could set a Trojan horse for later
perusal. Applying the same logic, the rule file must also be protected tightly.
.PP
And, no surprise, the same rules apply for your \fInewcmd\fR file, which is
used to describe extended filtering commands. Otherwise it would allow someone
to quietly redefine a commonly used standard command like LEAVE and later
be able to assume your identity.
.PP
Versions after 3.0 PL44 come with an improved (from a security point of view) C
\fIfilter\fR that will not only perform the aforementionned checks but will
also ensure that the \fIperl\fR executable and the \fImailagent\fR script
it is about to exec are not loosely protected (when \fIexecsafe\fR is ON or
when running with superuser privileges).
Furthermore, if the \fIfilter\fR
is set up in your \fI.forward\fR as described in this man page, it will be
able to check itself for safety and will warn you loundly if it can be
tampered with, which could defeat all security checks.
.PP
Mailagent was also extended so that all programs executed via RUN and friends,
as well as mail hooks, are checked for obvious protection flaws before being
actually run
Interpreted scripts (starting with the #! magic token) and
perl scripts following the magic "exec perl if \$under_shell" incantation are
specially checked for further security of the relevant interpretor. Those
checks are performed systematically
(when \fIexecsafe\fR is ON or when running with superuser privileges)
even if the \fIsecure\fR parameter was
not set to ON. Also, all files about to be \fIexec()\fRed are checked using
the same extended check method used when \fIsecure\fR is ON (ownership tests
are skipped however when checking for \fIexec()\fR-ness of a file).
.SH FILES
.PD 0
.TP 20
~/.mailagent
configuration file for mailagent.
.TP
~/agent.trace
trace dump from a PROCESS command when error cannot be mailed back.
.TP
~/mbox.filter
mailbox used by \fIfilter\fR in case of error
.TP
~/mbox.urgent
mailbox used by \fImailagent\fR in case of error
.TP
~/mbox.<username>
mailbox used if writing access is denied in the mail spool directory
.TP
$privlibexp/mailagent
directory holding templates and samples.
.TP
Log/agentlog
mailagent's log file.
.TP
Spool/agent.wait
list of mails waiting to be processed and stored outside of mailagent's
queue directory. Even when logically empty, this file is kept around and
still holds one blank line to reserve a block on the filesystem.
.TP
Queue/qmXXXXX
mail spooled by \fIfilter\fR.
.TP
Queue/fmXXXXX
mail spooled by \fImailagent\fR.
.TP
Queue/cmXXXXX
mail spooled by the AFTER command.
.TP
Hash/X/Y
hash files used by RECORD, UNIQUE, ONCE commands and vacation mode.
.PD
.SH BUGS
There is a small chance that mail arrives while the \fImain\fR mailagent
is about to finish its processing. That mail will be queued and not
processed until another mail arrives (the \fImain\fR mailagent always
processes the queue after having dealt with the message that invoked it).
.PP
A version number must currently contain a dot. Moreover, an old system
(i.e. a system with an \fIo\fR in the patches column) must have a version
number, so that mailagent can compute the name of the directory
holding the patches.
.PP
The lock file is deliberately ignored when \fB\-q\fR option is used (in fact,
it is ignored whenever an option is specified).
This may result in having mails processed more than once.
.PP
Mailagent is at the mercy of any \fIperl\fR bug, and there is little I
can do about it. Some spurious warnings may be emitted by the data-loaded
version, although they do not appear with the plain version.
.PP
Parsing of the rule file should be done by a real parser and not lexically.
Or at least, it should be possible to escape otherwise meaningful characters
like ';' or '}' within the rules.
.SH AUTHOR
Raphael Manfredi <Raphael_Manfredi@pobox.com>.
.SH "SEE ALSO"
maildist($manext), mailhelp($manext), maillist($manext), mailpatch($manext),
perl(1).
!GROK!THIS!
chmod 444 mailagent.$manext
