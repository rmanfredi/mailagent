# -l: list message queue (special)

# $Id: l.t,v 3.0.1.1 1994/09/22 14:41:21 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: l.t,v $
# Revision 3.0.1.1  1994/09/22  14:41:21  ram
# patch12: now checks that callout messages are properly listed
#
# Revision 3.0  1993/11/29  13:50:18  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
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
@output = split(/\n/, $output = `$mailagent -l 2>/dev/null`);
@files = <queue/*>;
@files == 3 || print "3\n";	# Not a -l failure, but that will get our attention
foreach $file (@files) {
	$file =~ s|^queue/||;
	eval "grep(/$file/, \@output)" || $failed++;
}
$failed == 0 || print "4\n";
# Invoking mailagent as `mailqueue' lists the queue.
unlink 'mailqueue';
`ln $mailagent_path ./mailqueue 2>/dev/null`;
$? == 0 || print "5\n";
$output_bis = `./mailqueue 2>/dev/null`;
$output eq $output_bis || print "6\n";

# Ensure callout messages are also listed
`$mailagent -f mbox -e 'AFTER -a (now + 1 day) DELETE; DELETE' 2>/dev/null`;
$? == 0 || print "7\n";
@qfiles = <queue/[qf]m*>;
@cfiles = <queue/cm*>;
@qfiles == 3 || print "8\n";
@cfiles == 3 || print "9\n";

# Make sure there are three messages queued and three callouts reported
@log = `$mailagent -l 2>/dev/null`;
&check_log('Now', 10) == 3 || print "11\n";
&check_log('Skipped', 12) == 3 || print "13\n";
&check_log('Callout', 14) == 3 || print "15\n";

unlink <queue/*>, 'mbox', 'mailqueue', 'context', 'callout';
print "0\n";
