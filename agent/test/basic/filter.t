# Make sure filter queues messages correctly

# $Id: filter.t,v 3.0.1.3 1999/01/13 18:16:41 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: filter.t,v $
# Revision 3.0.1.3  1999/01/13  18:16:41  ram
# patch64: agent.wait file moved from queue to spool dir
#
# Revision 3.0.1.2  1995/08/07  16:27:05  ram
# patch37: added support for locking on filesystems with short filenames
#
# Revision 3.0.1.1  1993/12/15  09:05:53  ram
# patch3: now make sure that filter.lock has correct timestamp
#
# Revision 3.0  1993/11/29  13:49:24  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out' || exit 0;
open(WAIT, ">agent.wait") || print "1\n";
close WAIT;
`chmod u-w queue`;
$? == 0 || print "2\n";
# Use the special undocumented -t option from filter to get HOME directory
# via environment instead of /etc/passwd.
open(FILTER, "|$filter -t >/dev/null 2>&1") || print "3\n";
print FILTER <<EOF;
Dummy mail
EOF
close FILTER;
$? == 0 || print "4\n";		# Must terminate correctly (stored in agent.wait)
&get_log(5);
&check_log('memorized', 6);	# Make sure mail has been memorized
-s 'agent.wait' || print "7\n";
$file = <emerg/*>;
if (-f "$file") {
	chop($what = `cat agent.wait`);
	chop($pwd = `pwd`);
	$what eq "$pwd/$file" || print "8\n";
	unlink "$file";
} else {
	print "8\n";
}
`chmod u+w queue`;
unlink 'agent.wait', 'agentlog';
open(FILTER, "|$filter -t >/dev/null 2>&1") || print "9\n";
print FILTER <<EOF;
Dummy mail
EOF
close FILTER;
$? == 0 || print "10\n";	# Must terminate correctly (queued)
&get_log(11);
&check_log('QUEUED', 12);	# Mail was queued
$file = <queue/qm*>;
-f "$file" || print "13\n";	# Must have been left in queue
unlink "$file", 'agentlog';

# Make sure file is correctly queued when another filter is running
unlink "filter$lockext";		# In case an old one remains
`cp /dev/null filter$lockext`;	# Make sure we have a new fresh one
$? == 0 || print "14\n";

open(FILTER, "|$filter -t >/dev/null 2>&1") || print "15\n";
print FILTER <<EOF;
Dummy mail
EOF
close FILTER;
$? == 0 || print "16\n";	# Must terminate correctly (queued)
&get_log(17);
&check_log('QUEUED', 18);	# Mail was queued
$file = <queue/fm*>;
-f "$file" || print "19\n";	# Must have been left in queue as a 'fm' file
unlink "$file", 'agentlog', "filter$lockext";
print "0\n";
