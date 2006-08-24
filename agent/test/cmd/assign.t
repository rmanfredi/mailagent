# Test ASSIGN command

# $Id: assign.t,v 3.0 1993/11/29 13:49:27 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: assign.t,v $
# Revision 3.0  1993/11/29  13:49:27  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output';

&add_header('X-Tag: assign #1');
`$cmd`;
$? == 0 || print "1\n";
-f 'output' || print "2\n";		# Result of various assign commands
chop($output = `cat output 2>/dev/null`);
$output eq 'ram,try,try.2' || print "3\n";
unlink 'output';

&replace_header('X-Tag: assign #2');
`$cmd`;
$? == 0 || print "4\n";
-f 'output' || print "5\n";		# Result of various assign commands
chop($output = `cat output 2>/dev/null`);
$output eq '7,1+2,7' || print "6\n";

unlink 'output', 'mail';
print "0\n";
