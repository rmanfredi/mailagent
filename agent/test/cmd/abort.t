# Test ABORT command

# $Id: abort.t,v 3.0 1993/11/29 13:49:25 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: abort.t,v $
# Revision 3.0  1993/11/29  13:49:25  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink "$user.1", 'always';

&add_header('X-Tag: abort');
`$cmd`;
$? == 0 || print "1\n";
-f "$user.1" && print "2\n";	# Have aborted
-f "$user" && print "3\n";		# match -> no leave
-f 'always' || print "4\n";

unlink "$user", "$user.1", 'always', 'mail';
print "0\n";
