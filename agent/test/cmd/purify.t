# The PURIFY command

# $Id: purify.t,v 3.0 1993/11/29 13:49:41 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: purify.t,v $
# Revision 3.0  1993/11/29  13:49:41  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output';

&add_header('X-Tag: purify 1');
`$cmd`;
$? == 0 || print "1\n";
-f 'output' || print "2\n";		# Where mail is saved
`grep -v X-Filter: output > comp`;
$? == 0 || print "3\n";
`grep -v Subject: mail > ok`;
((-s 'comp') - 1) == -s 'ok' || print "4\n";	# SAVE adds extra final new-line
-s 'comp' != -s 'output' || print "5\n";	# Casually check X-Filter was there

unlink 'output', 'mail', 'ok', 'comp';

cp_mail("../base64");
add_header('X-Tag: purify 2');
`$cmd`;
$? == 0 || print "6\n";
&get_log(7, 'output');
&check_log('successfully', 8);

unlink 'output', 'mail';

cp_mail("../qp");
add_header('X-Tag: purify 2');
`$cmd`;
$? == 0 || print "9\n";
&get_log(10, 'output');
&not_log('brok=', 11);			# Body must have been recoded
&not_log("char '=3D'!", 12);
&check_log("broken", 13);

unlink 'output', 'mail';
print "0\n";
