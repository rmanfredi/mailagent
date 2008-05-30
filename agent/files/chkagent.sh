#!/bin/sh
#
# $Id: chkagent.sh,v 3.0.1.3 1999/07/12 13:42:39 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: chkagent.sh,v $
# Revision 3.0.1.3  1999/07/12  13:42:39  ram
# patch66: added the UNLOCKED pattern
#
# Revision 3.0.1.2  1994/10/10  10:21:35  ram
# patch19: now honors config variables email and sendmail
#
# Revision 3.0.1.1  1994/04/25  15:10:32  ram
# patch7: also extract system error messages from logfile
#
# Revision 3.0  1993/11/29  13:47:49  ram
# Baseline for mailagent 3.0 netwide release.
#

# Make sure the mailagent is working well
lookat='ERROR|FAILED|UNLOCKED|FATAL|DUMPED|SYSERR'

trap "rm -f $report $output $todaylog $msg" 1 2 3 15

# Interpret the ~/.mailagent configuration file
set X `<$HOME/.mailagent sed -n \
	-e '/^[ 	]*#/d' \
	-e 's/[ 	]*#/#/' \
	-e 's/^[ 	]*\([^ 	:\/]*\)[ 	]*:[ 	]*\([^#]*\).*/\1="\2";/p'`
shift

# Deal with possible white spaces in variables and ~ substitution
cmd=''
for line in $*; do
	cmd="$cmd$line"
done
cmd=`echo $cmd | sed -e "s|~|$HOME|g"`
eval $cmd

# Compute location of report file and log file
report="/tmp/cAg$$"
output="/tmp/cAo$$"
logfile="$logdir/$log"
todaylog="/tmp/tAg$$"

# Current date format to look for in logfile
today=`date "+%y/%m/%d"`

if test -f "$logfile"; then
	grep "$today" $logfile > $todaylog
	egrep ": ($lookat)" $todaylog > $output
	if test -s "$output"; then
		echo "*** Errors from logfile ($logfile):" > $report
		echo " " >> $report
		cat $output >> $report
	fi
	rm -f $todaylog $output
else
	echo "Cannot find $logfile" > $report
fi

# ~/.bak is the output from .forward
if test -s "$HOME/.bak"; then
	echo " " >> $report
	echo "*** Errors from ~/.bak:" >> $report
	echo " " >> $report
	cat $HOME/.bak >> $report
	cp /dev/null $HOME/.bak
fi

# Look for mails in the emergency directory
ls -C $emergdir > $output
if test -s "$output"; then
	echo " " >> $report
	echo "*** Mails held in lost+mail ($emergdir):" >> $report
	echo " " >> $report
	cat $output >> $report
fi
rm -f $output

# Spot any unprocessed mails in the queue
cd $queue
ls -C qm* fm* > $output 2>/dev/null
if test -s "$output"; then
	echo " " >> $report
	echo "*** Unprocessed mails in queue ($queue):" >> $report
	echo " " >> $report
	cat $output >> $report
fi
rm -f $output

if test -s "$report"; then
	msg="/tmp/mAg$$"
	test "$email" || email=$user
	test "$sendmail" || sendmail=/usr/lib/sendmail
	cat >$msg <<EOM
To: $email
Subject: Errors from mailagent system

EOM
	cat $report >>$msg
	rm -f $report
	$sendmail $mailopt $email <$msg
	rm -f $msg
else
	rm -f $report
fi

exit 0
