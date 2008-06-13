# Test GIVE command

# $Id: give.t,v 3.0 1993/11/29 13:49:32 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: give.t,v $
# Revision 3.0  1993/11/29  13:49:32  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output';

&add_header('X-Tag: give 1');
`$cmd`;
$? == 0 || print "1\n";
-f 'output' || print "2\n";		# Where output is created
chop($output = `cat output 2>/dev/null`);
@output = split(' ', $output);
@valid = (17, 132, 804);		# Output of wc on body
$ok = 1;
for ($i = 0; $i < 3; $i++) {
	$ok = 0 if $valid[$i] != $output[$i];
}
$ok || print "3\n";
-f "$user" || print "4\n";		# Default action applies

unlink 'output', 'mail', "$user";

&cp_mail("../base64");
&add_header('X-Tag: give 2');
`$cmd`;
$? == 0 || print "5\n";
&get_log(6, 'output');
&check_log('successfully decoded', 7) == 1 || print "8\n";

unlink 'output', 'mail', "$user";

&cp_mail("../qp");
&add_header('X-Tag: give 2');
`$cmd`;
$? == 0 || print "9\n";
&get_log(10, 'output');
&check_log('broken', 11) == 1 || print "12\n";
&check_log('Raphaël', 13) == 1 || print "14\n";

unlink 'output', 'mail', "$user";
print "0\n";
