# Basic mailagent test: ensure it is correctly invoked by filter.

# $Id: mailagent.t,v 3.0.1.2 1996/12/24 15:02:07 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: mailagent.t,v $
# Revision 3.0.1.2  1996/12/24  15:02:07  ram
# patch45: ensure we quote upper path properly, in case @ is there!
#
# Revision 3.0.1.1  1995/08/07  16:27:11  ram
# patch37: added support for locking on filesystems with short filenames
#
# Revision 3.0  1993/11/29  13:49:25  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
$user = $ENV{'USER'};
chdir '../out' || exit 0;
# Make sure we'll find the mailagent
system 'perl', '-i', '-p', '-e', "s|^path.*|path     :.:\Q$up\E|", '.mailagent';
$? == 0 || print "1\n";
unlink '.cache';		# Make sure no cached rules yet
open(RULES, ">.rules") || print "2\n";
print RULES "{ DELETE };\n";
close RULES;
unlink <queue/qm*>;
open(FILTER, "|$filter -t >>.bak 2>&1") || print "3\n";
print FILTER <<EOF;
From: test

Dummy body
EOF
close FILTER;
$? == 0 || print "4\n";
&get_log(5);
&check_log('WARNING.*assuming', 6);		# No To: field
&check_log('FILTERED', 7);				# Mail filtered
&check_log('DELETED', 8);				# Mail deleted by only rule
@files = <queue/qm*>;
@files == 0 || print "9\n";				# Queued mail deleted when filtered
unlink 'agentlog', '.rules';
sleep 1 while -f "perl$lockext";		# Let background mailagent die
# Check empty rules...
open(FILTER, "|$filter -t >>.bak 2>&1") || print "10\n";
print FILTER <<EOF;
From: test

Dummy body
EOF
close FILTER;
$? == 0 || print "11\n";
&get_log(12);
&check_log('FILTERED', 13);				# Mail filtered
&check_log('LEFT', 14);					# Mail left in mbox
&check_log('building default', 15);		# Used default rules
-s "$user" || print "16\n";				# Maildrop is here, so is mbox
@files = <queue/qm*>;
@files == 0 || print "17\n";			# Queued mail deleted when filtered
-f 'context' && print "18\n";			# Empty context must be deleted
unlink 'agentlog', "$user";
sleep 1 while -f "perl$lockext";		# Let background mailagent die
# Make sure file is correctly queued when another mailagent is running
`cp /dev/null perl$lockext`;
$? == 0 || print "19\n";
open(FILTER, "|$filter -t >>.bak 2>&1") || print "20\n";
print FILTER <<EOF;
Dummy mail
EOF
close FILTER;
$? == 0 || print "21\n";	# Must terminate correctly (queued)
&get_log(22);
&check_log('QUEUED', 23);	# Mail was queued
$file = <queue/fm*>;
-f "$file" || print "24\n";	# Must have been left in queue as a 'fm' file
-s '.cache' || print "25\n";	# Rules are cached in ~/.cache
unlink "$file", 'agentlog', "perl$lockext";
print "0\n";
