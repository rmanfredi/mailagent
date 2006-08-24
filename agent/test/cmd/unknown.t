# Ensure unknown command defaults to LEAVE only when no saving was done

# $Id: unknown.t,v 3.0 1993/11/29 13:49:54 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: unknown.t,v $
# Revision 3.0  1993/11/29  13:49:54  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink "$user";

&add_header('X-Tag: unknown #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";		# Unknown was first
unlink "$user";

&replace_header('X-Tag: unknown #2');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";		# Unknown after saving status known

unlink "$user", 'mail';
print "0\n";
