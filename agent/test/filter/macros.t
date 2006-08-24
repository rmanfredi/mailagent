# Test patterns with macros in them

# $Id: macros.t,v 3.0.1.2 1994/10/10 10:26:10 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: macros.t,v $
# Revision 3.0.1.2  1994/10/10  10:26:10  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.1  1994/07/01  15:09:17  ram
# patch8: created
#

do '../pl/filter.pl';

&add_header('X-Tag: macros');
&replace_header("To: $user\@eiffel.com");
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Must have been deleted

unlink $user;	# Just in case

# Now check that macro susbstitution occurs in pattern when enabled

$cmd =~ s/^(\S+)/$1 -o 'rulemac: ON'/;
`$cmd`;
$? == 0 || print "3\n";
-f "$user" || print "4\n";		# This time, it has been leaved

unlink $user;
print "0\n";
