# Test selectors specified via a pattern

# $Id: pattern.t,v 3.0.1.1 1996/12/24 15:03:19 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: pattern.t,v $
# Revision 3.0.1.1  1996/12/24  15:03:19  ram
# patch45: added Relayed to the list of returned headers
#
# Revision 3.0  1993/11/29  13:50:05  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
unlink 'macro';

&add_header('X-Tag: pattern');
&add_header('Replied: ram@eiffel.com');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Must have been deleted
-f 'macro' || print "3\n";		# Created by RUN
chop($macro = `cat macro 2>/dev/null`);
$macro eq 'Received,Relayed,Replied;Subject;' || print "4\n";

unlink 'macro';
print "0\n";
