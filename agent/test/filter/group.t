# Test grouping of selectors (mixing normal and inverted selections)

# $Id: group.t,v 3.0.1.1 1994/04/25 15:25:47 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: group.t,v $
# Revision 3.0.1.1  1994/04/25  15:25:47  ram
# patch7: added three additional tests after a bug was found
#
# Revision 3.0  1993/11/29  13:49:59  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';

sub cleanup {
	unlink 'never', 'never.2', 'always', 'always.2', 'always.3',
		'always.4', 'always.5';
}

&add_header('Cc: guy_1@acri.fr, guy_2@eiffel.com, guy_3@inria.fr');
&add_header('X-Tag: group');
&cleanup;

`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail has been deleted
-f 'never' && print "3\n";		# Cannot match
-f 'always' || print "4\n";		# This one must have matched
-f 'always.2' || print "5\n";
-f 'always.3' || print "6\n";
-f 'never.2' && print "7\n";
-f 'always.4' || print "8\n";
-f 'always.5' || print "9\n";

&cleanup;
print "0\n";
