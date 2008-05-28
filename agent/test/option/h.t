# -h: print this help message and exits

# $Id: h.t,v 3.0 1993/11/29 13:50:17 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: h.t,v $
# Revision 3.0  1993/11/29  13:50:17  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
$output = `$mailagent -h 2>&1`;
$? != 0 || print "1\n";		# -h -> exit status 1
$output =~ /-h : print/m || print "2\n";
print "0\n";
