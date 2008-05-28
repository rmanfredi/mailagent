# -i: interactive usage -- print log messages on stderr

# $Id: i.t,v 3.0 1993/11/29 13:50:17 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: i.t,v $
# Revision 3.0  1993/11/29  13:50:17  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
chdir '../out';
unlink 'agentlog';
$output = `$mailagent -d -i 2>&1 >/dev/null`;
$? == 0 || print "1\n";
open(LOG, 'agentlog') || print "2\n";
undef $/;
$log = <LOG>;
close LOG;
$output =~ s/^$mailagent_prog://mg;
$log =~ s/^.*$mailagent_prog\[.*\]\s*://mg;
$output eq $log || print "3\n";
$output ne '' || print "4\n";
print "0\n";
