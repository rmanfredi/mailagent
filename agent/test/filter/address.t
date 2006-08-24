# Test various match patterns on address fields

# $Id: address.t,v 3.0.1.1 2001/03/17 18:15:16 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: address.t,v $
# Revision 3.0.1.1  2001/03/17 18:15:16  ram
# patch72: created
#

do '../pl/filter.pl';

sub cleanup {
	for $i (1..7) { unlink "ok.$i" }
	for $i (1..8) { unlink "bad.$i" }
}

&cleanup;
&add_header('X-Tag: address #1');
&replace_header('To: Raphael Manfredi <ram@eiffel.com>');
`$cmd`;
$? == 0 || print "1\n";
-f "ok.1" || print "2\n";
-f "ok.2" || print "3\n";
-f "ok.3" || print "4\n";
-f "ok.4" || print "5\n";
-f "ok.5" || print "6\n";
-f "ok.6" || print "7\n";
-f "ok.7" || print "8\n";
-f "bad.1" && print "9\n";
-f "bad.2" && print "10\n";
-f "bad.3" && print "11\n";
-f "bad.4" && print "12\n";
-f "bad.5" && print "13\n";
-f "bad.6" && print "14\n";
-f "bad.7" && print "15\n";
-f "bad.8" && print "16\n";
&cleanup;

print "0\n";

