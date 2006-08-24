# -c : specify alternate configuration file

# $Id: c.t,v 3.0.1.1 1997/09/15 15:18:45 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: c.t,v $
# Revision 3.0.1.1  1997/09/15  15:18:45  ram
# patch57: uses an empty file instead of /dev/null
#
# Revision 3.0  1993/11/29  13:50:13  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
$output = `cat ../mail | $mailagent -c foo 2>&1`;
$? != 0 || print "1\n";		# Cannot open config file
$* = 1;
$output =~ /^\*\*.*not processed/ || print "2\n";
chdir '../out';
$user = $ENV{'USER'};
unlink "$user";
`cp .mailagent alternate`;
open(EMPTY, '>empty'); close EMPTY;
$output = `$mailagent -c alternate empty 2>/dev/null`;
$? == 0 || print "3\n";
$output eq '' || print "4\n";
-s "$user" || print "5\n";
unlink "$user", 'alternate', 'empty';
print "0\n";
