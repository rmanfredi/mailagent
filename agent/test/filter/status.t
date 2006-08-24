# Make sure commands record their exit status

# $Id: status.t,v 3.0 1993/11/29 13:50:06 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: status.t,v $
# Revision 3.0  1993/11/29  13:50:06  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
unlink 'never', 'always', 'always.2', 'always.3';

&add_header('X-Tag: status');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail has been saved
-f 'never' && print "3\n";		# Cannot match
-f 'always' || print "4\n";
-f 'always.2' || print "5\n";
-f 'always.3' || print "6\n";

unlink 'never', 'always', 'always.2', 'always.3';
print "0\n";
