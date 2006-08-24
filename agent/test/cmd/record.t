# The RECORD command

# $Id: record.t,v 3.0.1.1 1994/01/26 09:35:57 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: record.t,v $
# Revision 3.0.1.1  1994/01/26  09:35:57  ram
# patch5: added tests for tag support
#
# Revision 3.0  1993/11/29  13:49:42  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink "$user.1", "$user.2", "$user.3";

&add_header('X-Tag: record #1');
`rm -rf dbr` if -d 'dbr';
`$cmd`;
$? == 0 || print "1\n";
-f "$user.1" || print "2\n";	# Was saved, first time.
unlink "$user.1";

-d 'dbr' || print "3\n";		# Make sure history recording works
-f 'dbr/i/e' || print "4\n";	# Hashing done on domain name

`$cmd`;
$? == 0 || print "5\n";
-f "$user.1" && print "6\n";	# We rejected this time, in SEEN mode
-f "$user.2" || print "7\n";	# And saved it here
unlink "$user.2";

&replace_header('X-Tag: record #2');
`$cmd`;
$? == 0 || print "8\n";
-f "$user.1" && print "9\n";	# We restarted this time
-f "$user.3" || print "10\n";	# And caught that rule in RECORD mode
-f "$user" && print "11\n";		# Nothing here
unlink "$user.3";

&replace_header('X-Tag: record #3');
`$cmd`;
$? == 0 || print "12\n";
-f "$user.1" && print "13\n";	# We aborted
-f "$user" || print "14\n";		# Must be there (aborted, no match)
unlink "$user.1", "$user";

&replace_header('X-Tag: record #4');
`$cmd`;
$? == 0 || print "15\n";
-f "$user.1" && print "16\n";	# We rejected
-f "$user.2" || print "17\n";	# Must be there (saved in mode RECORD)
-f "$user" && print "18\n";
unlink "$user.1", "$user.2", $user;

&replace_header('X-Tag: record #5');
`$cmd`;
$? == 0 || print "19\n";
-f "$user.1" || print "20\n";	# First time with both tags tag1 and tag2
-f "$user.2" && print "21\n";	# Can't be there (tag2 already recorded)
-f "$user.3" && print "22\n";	# Can't be there (already recorded previously)
-f "$user" && print "23\n";
&get_log(24, 'dbr/i/e');
&check_log('<tag2>$', 25) == 1 || print "26\n";
&check_log('<tag1>$', 27) == 1 || print "28\n";
&check_log('cambridge', 29) == 3 || print "30\n";
unlink "$user.1", "$user.2", "$user.3", $user;

&replace_header('X-Tag: record #6');
`rm -rf dbr` if -d 'dbr';
`$cmd`;
$? == 0 || print "31\n";
-f "$user.1" || print "32\n";	# First time with tag 'tag'
-f "$user.2" || print "33\n";	# Tag 'other' distinct from 'tag'
-f "$user.3" && print "34\n";	# Sorry, already recorded
-f "$user" && print "35\n";
&get_log(36, 'dbr/i/e');
&check_log('cambridge', 37) == 2 || print "38\n";

`rm -rf dbr` if -d 'dbr';
unlink "$user", "$user.1", "$user.2", "$user.3", 'mail';
print "0\n";
