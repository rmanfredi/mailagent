# The TR command

# $Id: tr.t,v 3.0.1.1 2001/03/13 13:16:19 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: tr.t,v $
# Revision 3.0.1.1  2001/03/13 13:16:19  ram
# patch71: added test cases for TR on header fields
#
# Revision 3.0  1993/11/29  13:49:53  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output';

&add_header('X-Tag: tr #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";
-f 'output' || print "3\n";
chop ($output = `cat output 2>/dev/null`);
$output eq 'RAM@EIFFEL.COM,' .
	'RE: mEltIng ICE tEChnology?,'.
	'RE: mEltIng ICE tEChnology?' || print "4\n";

unlink 'output';

sub cleanup {
	unlink 'subst', 'always', 'never', 'never2';
}

&cleanup;
&replace_header('X-Tag: tr #2');
`$cmd`;
$? == 0 || print "5\n";
-f 'subst' || print "6\n";
-f 'always' || print "7\n";
-f 'never' && print "8\n";
-f 'never2' && print "9\n";

get_log(10, 'subst');
not_log('^Received: .*[A-Z]', 11);

unlink 'mail';
&cleanup;

print "0\n";

