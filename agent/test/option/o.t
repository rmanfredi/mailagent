# -o: overwrite config file with supplied definition

# $Id: o.t,v 3.0 1993/11/29 13:50:18 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: o.t,v $
# Revision 3.0  1993/11/29  13:50:18  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
chdir '../out';
unlink 'mylog';
`$mailagent -d -o 'log: mylog' 2>/dev/null`;
$? == 0 || print "1\n";
-s 'mylog' || print "2\n";
unlink 'mylog';
print "0\n";
