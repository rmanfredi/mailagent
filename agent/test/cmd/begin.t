# Test BEGIN command

# $Id: begin.t,v 3.0 1993/11/29 13:49:28 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: begin.t,v $
# Revision 3.0  1993/11/29  13:49:28  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'one', 'two', 'three';

&add_header('X-Tag: begin');
`$cmd`;
$? == 0 || print "1\n";
-f 'one' && print "2\n";		# Cannot happen in TWO mode
-f 'two' || print "3\n";		# Must be saved here
-f 'three' || print "4\n";		# And also here by THREE mode
-f "$user" && print "5\n";		# So default action did not apply

unlink 'one', 'two', 'three', 'mail';
print "0\n";
