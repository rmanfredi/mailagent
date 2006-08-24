# Test user-defined commands

# $Id: newcmd.t,v 3.0 1993/11/29 13:50:10 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: newcmd.t,v $
# Revision 3.0  1993/11/29  13:50:10  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';
unlink "$user", 'always', 'test';

&add_option("-o 'newcmd: ~/.newcmd'");
open(NEWCMD, '>.newcmd') || print "1\n";
print NEWCMD <<EOF || print "2\n";
FIRST_CMD ~/commands first
SECOND_CMD ~/commands second
THIRD_CMD ~/commands third
EOF
close NEWCMD || print "3\n";

open(COM, '>commands') || print "4\n";
print COM <<'EOC' || print "5\n";
sub first {
	&mailhook'third_cmd('test');	# Make sure interface function is there
	open(OUT, '>output1');
	print OUT join(' ', @ARGV), "\n";
	print OUT "$to\n";
	close OUT;
	0;
}

sub second {
	&main'add_log('second user-defined command ran ok');
	open(OUT, '>output2');
	print OUT "$from\n";
	print OUT "$header{'Date'}\n";
	close OUT;
	0;
}

sub third {
	local($cmd) = @_;
	local(@cmd) = split(' ', $cmd);
	open(TEST, ">$cmd[1]");
	print TEST "$cmd\n";
	close TEST;
	0;
}
EOC
close COM || print "6\n";

&add_header('X-Tag: newcmd');
`$cmd`;
$? == 0 || print "7\n";
-f "$user" && print "8\n";		# Has defaulted to LEAVE -> something's wrong
-f 'output1' || print "9\n";
-f 'output2' || print "10\n";
-f 'test' || print "11\n";

chop($test = `cat test 2>/dev/null`);
$test eq 'third_cmd test' || print "12\n";

chop(@test = `cat output1 2>/dev/null`);
$test[0] eq 'FIRST_CMD arg1 arg2' || print "13\n";
$test[1] eq 'ram@eiffel.com' || print "14\n";

chop(@test = `cat output2 2>/dev/null`);
$test[0] eq 'compilers-request@iecc.cambridge.ma.us' || print "15\n";
$test[1] eq '3 Jul 92 00:43:22 EDT (Fri)' || print "16\n";

&get_log(17);
&check_log('second user-defined command ran ok', 18) == 1 || print "19\n";

unlink "$user", 'mail', 'test', 'output1', 'output2', 'commands', '.newcmd';
print "0\n";
