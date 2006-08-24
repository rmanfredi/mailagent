# -t: track rules on stdout

# $Id: t.t,v 3.0 1993/11/29 13:50:21 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: t.t,v $
# Revision 3.0  1993/11/29  13:50:21  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
chdir '../out';
open(MBOX, ">mbox") || print "1\n";
print MBOX <<'EOM';
From ram Sat Jul 11 18:51:16 PDT 1992
From: ram
To: ram
Subject: test

This is a test.
EOM
close MBOX;
$trace = `$mailagent -t -e 'STRIP To; DELETE; LEAVE' mbox 2>/dev/null`;
$? == 0 || print "2\n";
@trace = split(/\n/, $trace);
grep(/^-+\s+From/, @trace) || print "3\n";
grep(/^>> STRIP/, @trace) || print "4\n";
grep(/^>> DELETE/, @trace) || print "5\n";
grep(/^>> LEAVE/, @trace) || print "6\n";
grep(/match/i, @trace) || print "7\n";
$user = $ENV{'USER'};
-s "$user" || print "8\n";
unlink "$user", 'mbox';
print "0\n";
