# Test matches with multiple headers

# $Id: multiple.t,v 3.0 1993/11/29 13:50:03 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: multiple.t,v $
# Revision 3.0  1993/11/29  13:50:03  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';

for ($i = 1; $i <= 3; $i++) {
	unlink "$user.$i";
}

&add_header('X-Tag: multiple #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user.1" || print "2\n";	# Selection worked
unlink "$user.1";

&replace_header('X-Tag: multiple #2');
&add_header('X-Other: multiple #2');
`$cmd`;
$? == 0 || print "3\n";
-f "$user.2" || print "4\n";	# Selection worked
unlink "$user.2";

&add_header('X-Other: another');
`$cmd`;
$? == 0 || print "5\n";
-f "$user.3" || print "6\n";	# Selection worked
-f "$user.2" || print "7\n";	# Selection on non-existent field
unlink "$user.2", "$user.3";

unlink 'mail';
print "0\n";
