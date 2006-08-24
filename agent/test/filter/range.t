# Test range selection

# $Id: range.t,v 3.0 1993/11/29 13:50:05 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: range.t,v $
# Revision 3.0  1993/11/29  13:50:05  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
unlink 'never', 'never.2', 'never.3', 'never.4', 'never.5', 'never.6',
	'always', 'always.2', 'always.3', 'always.4', 'always.5', 'always.6',
	'always.7', 'always.8';

&add_header('Cc: ram@acri.fr, must@yes.com, made@no.com');
&add_header('X-Tag: range');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail has been saved correctly
-f 'never' && print "3\n";		# Never(s) cannot match
-f 'never.2' && print "4\n";
-f 'never.3' && print "5\n";
-f 'never.4' && print "6\n";
-f 'always' || print "7\n";		# Always must match
-f 'always.2' || print "8\n";
-f 'always.3' || print "9\n";
-f 'always.4' || print "10\n";
-f 'always.5' || print "11\n";
-f 'always.6' || print "12\n";
-f 'always.7' || print "13\n";
-f 'always.8' || print "14\n";
-f 'never.5' && print "15\n";
-f 'never.6' && print "16\n";

unlink 'never', 'never.2', 'never.3', 'never.4', 'never.5', 'never.6',
	'always', 'always.2', 'always.3', 'always.4', 'always.5', 'always.6',
	'always.7', 'always.8';
print "0\n";
