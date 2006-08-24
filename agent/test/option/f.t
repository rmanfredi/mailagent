# -f: get messages from UNIX-style mailbox file

# $Id: f.t,v 3.0 1993/11/29 13:50:16 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: f.t,v $
# Revision 3.0  1993/11/29  13:50:16  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
unlink 'agentlog';
$user = $ENV{'USER'};
unlink "$user";
open(MBOX, ">mbox") || print "1\n";
print MBOX <<'EOM';
From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #1

Body #1
From ram Sat Jul 11 17:17:12 PDT 1992
Previous line is just a dummy From line.

From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #2

Body #2
From ram Sat Jul 11 17:17:12 PDT 1992
From: nearly a header!!
Previous 2 lines are just dummy lines.

From ram Sat Jul 11 17:17:12 PDT 1992
From: ram
To: ram
Subject: test #3

Body #3
EOM
close MBOX;
`$mailagent -e 'LEAVE' -f mbox 2>/dev/null`;
$? == 0 || print "2\n";
-s "$user" || print "3\n";
&get_log(4);
@queued = grep(/QUEUED/, @log);
@queued == 3 || print "5\n";
@subject = grep(/ABOUT.*test/, @log);
@subject == 3 || print "6\n";
@filtered = grep(/FILTERED/, @log);
@filtered == 3 || print "7\n";
@files = <queue/*>;
@files == 0 || print "8\n";
open(MBOX, "$user") || print "9\n";
@mbox = <MBOX>;
close MBOX;
@msg = grep(/^X-Filter:/, @mbox);
@msg == 3 || print "10\n";
unlink 'agentlog', "$user", 'mbox';
print "0\n";
