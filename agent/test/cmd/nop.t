# The NOP command

# $Id: nop.t,v 3.0 1993/11/29 13:49:35 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: nop.t,v $
# Revision 3.0  1993/11/29  13:49:35  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';

# Make sure NOP is recognized (not defaulted to LEAVE)
&add_header('X-Tag: nop');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";

unlink 'mail';
print "0\n";
