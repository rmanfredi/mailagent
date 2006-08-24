# Test escape sequences within rules

# $Id: escape.t,v 3.0 1993/11/29 13:49:58 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: escape.t,v $
# Revision 3.0  1993/11/29  13:49:58  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
unlink 'output';

&add_header('X-Tag: escape');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Must have been deleted
-f 'output' || print "3\n";		# Created by RUN
chop($output = `cat output 2>/dev/null`);
$output eq ';,\\;,\\,\\w' || print "4\n";

unlink 'output';
print "0\n";
