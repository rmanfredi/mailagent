# The RESTART command

# $Id: restart.t,v 3.0 1993/11/29 13:49:46 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: restart.t,v $
# Revision 3.0  1993/11/29  13:49:46  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink "$user.1", 'never';

# Make sure everything after a RESTART is not executed
&add_header('X-Tag: restart');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";		# RESTART -> no match -> leave
-f "$user.1" && print "3\n";	# This SAVE was after the RESTART
-f 'never' && print "4\n";		# Idem

unlink "$user.1", "$user", 'never', 'mail';
print "0\n";
