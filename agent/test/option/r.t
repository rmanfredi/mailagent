# -r: sepcify alternate rule file

# $Id: r.t,v 3.0 1993/11/29 13:50:20 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: r.t,v $
# Revision 3.0  1993/11/29  13:50:20  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
chdir '../out';
`cp ../rules .rules`;
$output = `$mailagent -d 2>/dev/null`;
$? == 0 || print "1\n";
`cp .rules myrules`;
$output_bis = `$mailagent -r myrules -d 2>/dev/null`;
$? == 0 || print "2\n";
$output eq $output_bis || print "3\n";
unlink 'myrules';
print "0\n";
