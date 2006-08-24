# The ON command

# $Id: on.t,v 3.0.1.1 1998/03/31 15:29:01 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: on.t,v $
# Revision 3.0.1.1  1998/03/31  15:29:01  ram
# patch59: created
#

do '../pl/cmd.pl';
sub cleanup {
	unlink 'days', $user;
}
&cleanup;

&add_header('X-Tag: on');
`$cmd`;
$? == 0 || print "1\n";
-f $user || print "2\n";
-f 'days' || print "3\n";
-s $user || print "4\n";
-s($user) == -s('days') || print "5\n";		# One save made only into 'days'

unlink 'mail';
&cleanup;
print "0\n";
