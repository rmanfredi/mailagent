# The SELECT command

# $Id: select.t,v 3.0 1993/11/29 13:49:48 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: select.t,v $
# Revision 3.0  1993/11/29  13:49:48  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'one', 'two', 'three', 'four', 'five', "$user";

&add_header('X-Tag: select');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";
-f 'one' || print "3\n";
-f 'two' && print "4\n";
-f 'three' || print "5\n";
-f 'four' || print "6\n";
-f 'five' && print "7\n";

unlink 'one', 'two', 'three', 'four', 'five', "$user", 'mail';
print "0\n";
