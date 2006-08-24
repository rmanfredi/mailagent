# Test BACK command

# $Id: back.t,v 3.0 1993/11/29 13:49:28 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: back.t,v $
# Revision 3.0  1993/11/29  13:49:28  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output';

open(PGM, ">pgm") || print "1\n";
print PGM '/bin/echo "RUN /bin/echo it works! > output; SAVE other"', "\n";
close PGM;
chmod 0755, 'pgm';

&add_header('X-Tag: back');
`$cmd`;
$? == 0 || print "2\n";
-f 'output' || print "3\n";		# Where output is created
chop($output = `cat output 2>/dev/null`);
$output eq 'it works!' || print "4\n";
-f 'other' || print "5\n";		# Mail also saved
-f "$user" && print "6\n";		# So default action does not apply

unlink 'pgm', 'output', 'mail', 'other';
print "0\n";
