# Check header field case insensitiveness

# $Id: case.t,v 3.0 1993/11/29 13:49:57 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: case.t,v $
# Revision 3.0  1993/11/29  13:49:57  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
do '../pl/logfile.pl';
unlink 'always';

&add_header('x-tag: case');
&add_header('CC: root');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# No default action
-f 'always' || print "3\n";		# Recognized both X-Tag and CC

&get_log(4, 'always');
&not_log('CC:', 5);				# CC was STRIPed out

unlink 'always', "$user";
print "0\n";
