#!/bin/sh

# $Id: filter.sh,v 3.0.1.4 1999/01/13 18:03:19 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: filter.sh,v $
# Revision 3.0.1.4  1999/01/13  18:03:19  ram
# patch64: agent.wait is now stored in the spool rather than in queue
#
# Revision 3.0.1.3  1995/08/07  16:06:52  ram
# patch37: avoid forking of a new mailagent if one is sitting in background
#
# Revision 3.0.1.2  1994/10/29  17:39:23  ram
# patch20: made it behave more like the C filter
#
# Revision 3.0.1.1  1994/09/22  13:41:43  ram
# patch12: filter.sh now honours queuewait when defined
#
# Revision 3.0  1993/11/29  13:47:51  ram
# Baseline for mailagent 3.0 netwide release.
#

# You'll have to delete comments by yourself if your shell doesn't grok them

# You should install a .forward in your home directory to activate the
# process (sendmail must be used as a MTA). Mine looks like this:
#    "|exec /users/ram/mail/filter >>/users/ram/.bak 2>&1"

# Variable HOME *must* correctly be set to your home directory
# This should compute it correctly, if not, hardwire it
user=`(logname || whoami) 2>/dev/null`
HOME=`grep ^$user: /etc/passwd | cut -d':' -f 6`
export HOME

# The PATH variable must also correctly be set. This variable will be
# used by all the mailagent-related programs. If you have chosen to put
# the mailagent scripts in a dedicated directory (e.g. $HOME/mailagent),
# be sure to put that directory in the PATH variable.
# The mailagent scripts could also have been stored in a directory like
# /usr/local/scripts by your system administrator, because each user does
# not need to have a private copy of theese scrips.
PATH="/bin:/usr/bin:/usr/ucb:$HOME/bin/mailagent:$HOME/bin"

# The following will set the right path for some architecture-specific
# directories. For instance, if you have your home directory viewed on
# some different machines (e.g. it is NFS-mounted), then you must be
# sure the mailagent will be invoked with the right executables.
HOST=`(uname -n || hostname) 2>/dev/null`
case "$HOST" in
york) PATH="$HOME/bin/rs2030:$PATH" ;;
eiffel) PATH="/base/common/sun4/bin:$PATH" ;;
*) ;;
esac
export PATH

# The TZ may not correctly be set when sendmail is invoking the filter, hence
# funny date could appear in the log message (from GMT zone usually).
TZ='PST8PDT'
export TZ

##### You should not have to edit below this line #####

# This variable, when eval'ed, adds a log message at the end of the log file
# if any. Assumes the ~/.mailagent file was successfully parsed.
addlog='umask 077; if test -f $logdir/$log;
then /bin/echo "`date \"+%y/%m/%d %H:%M:%S\"` filter[$$]: $1" >> $logdir/$log;
else echo "`date \"+%y/%m/%d %H:%M:%S\"` filter[$$]: $1";
fi; umask 277
'

# This variable, when eval'ed, dumps the message on stdout. For this
# reason, error messages should be redirected into a file.
emergency='echo "*** Could not process the following ($1) ***";
cat $temp;
echo "----------- `date` -----------";
set "FATAL $1";
eval $addlog;
rm -f $spool/filter.lock $torm
'

# This is for safety reasons (mailagent may abort suddenly). Save the
# whole mail in a temporary file, which has very restrictive permissions
# (prevents unwanted removal). This will be eventually moved to the
# mailagent's queue if we can locate it.
umask 277
temp=/tmp/Fml$$
torm="$temp"

# The magic number '74' is EX_IOERR as understood by sendmail and means that
# an I/O error occurred. The mail is left in sendmail's queue. I expect "cat"
# to give a meaningful exit code.
cat > $temp || exit 74

# The following is done in a subshell put in background, so that this
# process can exit with a zero status immediately, which will make
# sendmail think that the delivery was successful. Hopefully we can
# do our own error recovery now.

(
# Script used to save the processed mail in an emergency situation
saver='umask 077; if (cat $temp; echo ""; echo "") >> $HOME/mbox.filter; then
	set "DUMPED in ~/mbox.filter"; eval $addlog; rm -f $torm; else
	set "unable to dump in ~/mbox.filter"; eval $emergency;
fi'

# Set a trap in case of interruption. Mail will be dumped in ~/mbox.filter
trap 'eval $saver; exit 0' 1 2 3 15

# Look for the ~/.mailagent file, exit if none found
if test ! -f $HOME/.mailagent; then
	set 'FATAL no ~/.mailagent'
	eval $addlog
	eval $saver
	exit 0
fi

# Parse ~/.mailagent to get the queue location
set X `<$HOME/.mailagent sed -n \
	-e '/^[ 	]*#/d' \
	-e 's/[ 	]*#/#/' \
	-e 's/^[ 	]*\([^ 	:\/]*\)[ 	]*:[ 	]*\([^#]*\).*/\1="\2";/p'`
shift

# Deal with possible white spaces in variables
cmd=''
for line in $*; do
	cmd="$cmd$line"
done
cmd=`echo $cmd | sed -e "s|~|$HOME|g"`
eval $cmd

# It would be too hazardous to continue without a valid queue directory
if test ! -d "$queue"; then
	set 'FATAL no valid queue directory'
	eval $addlog
	eval $saver
	exit 0
fi

# If there is already a filter.lock file, then we set busy to true. Otherwise,
# we create the lock file. Note that this scheme is a little lousy (race
# conditions may occur), but that's not really important because the mailagent
# will do its own tests with the perl.lock file.The motivation here is to avoid
# a myriad of filter+perl processes spawned when a lot of mail is delivered
# via SMTP (for instance after a uucp connection).
#
# There is also a chance there be a perl.lock file (indicating mailagent is
# processing messages or waiting in the background for a new batch) but no
# filter.lock (because the main filter has exited a while ago). That's likely
# to happen when mailagent processes maildist commands, and is the reason why
# we also test for perl.lock below.

busy=''
if test -f $spool/filter.lock; then
	busy='true'
elif test -f $spool/perl.lock; then
	set "NOTICE mailagent seems to be active in background"
	eval $addlog
	busy='true'
else
	# Race condition may (and will) occur, but the permissions are kept by 'cp',
	# so the following will not raise any error message.
	cp /dev/null $spool/filter.lock >/dev/null 2>&1 || busy='true'
fi

# Copy tmp file to the queue directory and call the mailagent. If the file
# already exists (very unlikely, but...), we append a 'b' for bis. When busy,
# create a 'fm' mail message instead, to allow mailagent to process it as soon
# as possible, mailagent being the one spawned by the main filter.

case "$busy" in
true) bq=fm;;
*) bq=qm;;
esac
qbase=${bq}$$
while test -f "$queue/$qbase"; do
	# Race condition still possible since file is not created yet
	qbase=${qbase}b
done
qtemp=$queue/$qbase
tqtemp=$queue/T$qbase

# Set a proper waiting time. If queuewait is not defined in the config file,
# let it default to 60 seconds.
test "$queuewait" || queuewait=60

# Do not write in a queue file directly, or the mailagent might start
# its processing on an incomplete file.
if cp $temp $tqtemp; then
	mv $tqtemp $qtemp
	base=`echo $qtemp | sed -e 's/.*\/\(.*\)/\1/'`
	size=`perl -e 'print 0 + -s("'$qtemp'"), "\n";'`
	set "QUEUED [$base] $size bytes"
	eval $addlog
	if test x = "x$busy"; then
		sleep $queuewait
		if perl -S mailagent $qtemp; then
			rm -f $temp $qtemp $spool/filter.lock
			exit 0
		fi
	else
		# Mail queued in a 'fm' file, will be processed by the main mailagent
		# invoked by the filter process which got its lock...
		rm -f $temp
		exit 0
	fi
else
	set 'ERROR unable to queue mail before processing'
	eval $addlog
	if test x = "x$busy"; then
		sleep $queuewait
		if perl -S mailagent $temp; then
			rm -f $temp $spool/filter.lock
			exit 0
		fi
	fi
fi

# We come here only if the mailagent failed its processing. The unprocessed
# mail either left in the queue or is given a meaningful name.

# Mail was queued correctly, leave it there
if cmp $temp $qtemp >/dev/null 2>&1; then
	rm -f $temp $spool/filter.lock
	set "ERROR mailagent failed, [$base] left in queue"
	eval $addlog
	exit 0
fi

# Change the name of the temporary file.
tmpdir=`echo $temp | sed -e 's/\(.*\)\/.*/\1/'`
mv $temp $tmpdir/$user.$$
temp="$tmpdir/$user.$$"
if test x = "x$busy"; then
	set "ERROR mailagent failed, mail left in $temp"
	rm -f $spool/filter.lock
else
	set "WARNING filter busy, mail left in $temp"
fi
eval $addlog

# Give the mailagent a clue as to where the mail has been stored. As this
# should be very very unlikely, no test is done to see whether a mailagent
# is already updating the agent.wait file. The worse that could result from
# this shallowness would be having an unprocessed mail.
umask 077
set "WARNING mailagent ignores mail was left in $temp"
if /bin/echo "$temp" >> $spool/agent.wait; then
	if grep "$temp" $spool/agent.wait >/dev/null 2>&1; then
		set "NOTICE $temp memorized into agent.wait"
	fi
fi
eval $addlog
rm -f $qtemp

# Attempt an emergency saving
eval $saver
exit 0
) &

# Delivery was ok -- for sendmail
exit 0
