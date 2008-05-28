# -U : disable reject / abort of first UNIQUE and REJECT.

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
# $Log: F.t,v $
# Revision 3.0.1.1  1994/01/26  09:36:08  ram
# patch5: created
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
$user = $ENV{'USER'};	# Don't want to include ../pl/filter.pl
unlink 'folder', 'again', $user;

$devnull = ">/dev/null 2>&1";

# Load the dbr database
unlink("dbr/i/e");
system "$mailagent -e '{ UNIQUE (a); UNIQUE (b); }' -f ../mail $devnull";
$? == 0 || print "1\n";
-f $user || print "2\n";

unlink $user;
system "$mailagent -U -e '{ UNIQUE (a); SAVE ~/again; }' -f ../mail $devnull";
$? == 0 || print "3\n";
-f $user && print "4\n";
-s 'again' || print "5\n";
&get_log(6, 'again');
&check_log('^X-Filter:', 7) == 1 || print "8\n";

unlink $user, 'again';
system "$mailagent -U -e '{ UNIQUE (a); UNIQUE (b); SAVE ~/again; }' -f ../mail"
	. $devnull;
$? == 0 || print "9\n";
-f $user && print "10\n";
-s 'again' || print "11\n";

unlink $user, 'again';
system "$mailagent -U -e '{ RECORD (a); RECORD (b); SAVE ~/again; }' -f ../mail"
	. $devnull;
$? == 0 || print "12\n";
-f $user && print "13\n";
-s 'again' || print "14\n";

unlink $user, 'again';
system "$mailagent -U -e '{ RECORD (a); UNIQUE (a); SAVE ~/again; }' -f ../mail"
	. $devnull;
$? == 0 || print "15\n";
-f $user || print "16\n";
-s 'again' && print "17\n";

unlink $user, 'again';
system "$mailagent -U -e '{ UNIQUE (a); RECORD (a); SAVE ~/again; }' -f ../mail"
	. $devnull;
$? == 0 || print "18\n";
-f $user || print "19\n";
-s 'again' && print "20\n";

print "0\n";
