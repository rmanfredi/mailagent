# The ONCE command and autocleaning feature

# $Id: once.t,v 3.0 1993/11/29 13:49:37 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: once.t,v $
# Revision 3.0  1993/11/29  13:49:37  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'one', 'two', 'three', 'four', "$user";

&add_header('X-Tag: once');
`rm -rf dbr` if -d 'dbr';
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";
-f 'one' || print "3\n";
-f 'two' && print "4\n";
-f 'three' || print "5\n";
-f 'four' || print "6\n";
-d 'dbr' || print "7\n";
@files = <dbr/*/*>;
@files == 3 || print "8\n";

# Make sure ONCE dbr database not disturbed by autocleaning, and, along
# the way, check that auto cleaning is correctly run.

$level = $ENV{'LEVEL'};
`$mailagent -L $level -q -o 'autoclean: ON' 2>/dev/null`;
$? == 0 || print "9\n";
@new_files = <dbr/*/*>;
@new_files == @files || print "10\n";
unlink 'one', 'two', 'three', 'four', "$user";
-f 'context' || print "11\n";

`$cmd`;
$? == 0 || print "12\n";
-f "$user" && print "13\n";
-f 'one' && print "14\n";
-f 'two' && print "15\n";
-f 'three' && print "16\n";
-f 'four' || print "17\n";
-d 'dbr' || print "18\n";

# Make sure autocleaning leaves things in a coherent state

`$mailagent -q -L $level -o 'autoclean: ON' -o 'agemax: 0m' 2>/dev/null`;
-d 'dbr' && print "19\n";
-f 'context' || print "20\n";

`$mailagent -q -L $level 2>/dev/null`;
-f 'context' && print "21\n";

unlink 'one', 'two', 'three', 'four', "$user", 'mail';
print "0\n";
