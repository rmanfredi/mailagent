# Ensure loops are detected

# $Id: loop.t,v 3.0 1993/11/29 13:50:02 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: loop.t,v $
# Revision 3.0  1993/11/29  13:50:02  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';

&add_header('X-Tag: loop #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";		# Loop was detected (otherwise never ends)

`mv $user mail 2>/dev/null`;
&replace_header('X-Tag: loop #2');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" || print "4\n";		# Loop was detected (otherwise mail deleted)

unlink 'mail', "$user";
print "0\n";
