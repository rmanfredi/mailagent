# -q: process the queue (special)

# $Id: q.t,v 3.0 1993/11/29 13:50:19 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: q.t,v $
# Revision 3.0  1993/11/29  13:50:19  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
chdir '../out';
unlink <queue/*>;
open(MBOX, ">mbox") || print "1\n";
print MBOX <<'EOM';
From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #1

Body #1

From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #2

Body #2

From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #3

Body #3
EOM
close MBOX;
`$mailagent -f mbox -e 'QUEUE' 2>/dev/null`;
$? == 0 || print "2\n";
$user = $ENV{'USER'};
unlink "$user";
`$mailagent -e 'LEAVE' -q 2>/dev/null`;
-f "$user" && print "3\n";
@queue = <queue/*>;
@queue == 3 || print "4\n";		# Still deferred for 30 minutes
$now = time;
$now -= 31 * 60;
utime $now, $now, @queue;
`$mailagent -e 'LEAVE' -q 2>/dev/null`;
-f "$user" || print "5\n";
@queue = <queue/*>;
@queue == 0 || print "6\n";		# Mails have been processed
unlink "$user", 'mbox';
print "0\n";
