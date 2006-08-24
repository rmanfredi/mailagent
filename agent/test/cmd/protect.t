# Test PROTECT command

# $Id: protect.t,v 3.0.1.1 1995/01/25 15:33:20 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: protect.t,v $
# Revision 3.0.1.1  1995/01/25  15:33:20  ram
# patch27: created
#

do '../pl/cmd.pl';

sub cleanup {
	unlink $user, 'fold.1', 'fold.2', 'fold.3', 'fold.4', 'fold.5', 'dflt';
}

&cleanup;
&add_header('X-Tag: protect');
`$cmd`;
$? == 0 || print "2\n";
-f $user && print "3\n";
-f 'dflt' || print "4\n";
-f 'fold.1' || print "5\n";
-f 'fold.2' || print "6\n";
-f 'fold.3' || print "7\n";
-f 'fold.4' || print "8\n";
-f 'fold.5' || print "9\n";
((2 * -s('fold.1')) == -s('dflt')) || print "10\n";	# Two saves in dflt

sub st_mode {
	(stat($_[0]))[2] & 0777;
}

&st_mode('dflt') == oct("0644") || print "11\n";	# Not altered by PROTECT
&st_mode('fold.1') == oct("0444") || print "12\n";
&st_mode('fold.2') == oct("0666") || print "13\n";
&st_mode('fold.3') == oct("0444") || print "14\n";
&st_mode('fold.4') == oct("0444") || print "15\n";
&st_mode('fold.5') == oct("0644") || print "16\n";

&cleanup;
print "0\n";
