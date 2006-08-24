# The RESYNC command

# $Id: resync.t,v 3.0 1993/11/29 13:49:46 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: resync.t,v $
# Revision 3.0  1993/11/29  13:49:46  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'output', "$user.1";

&add_header('X-Tag: resync');
`$cmd`;
$? == 0 || print "1\n";
-f 'output' || print "2\n";		# Where mail is saved
-f "$user.1" && print "3\n";	# Cannot be there if RESYNC worked
-f "$user" && print "4\n";		# That would mean first match failed

unlink 'output', 'mail', "$user", "$user.1";
print "0\n";
