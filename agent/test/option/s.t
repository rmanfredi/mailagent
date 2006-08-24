# -s: report gathered statistics (special)

# $Id: s.t,v 3.0.1.1 1995/08/07 16:28:45 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: s.t,v $
# Revision 3.0.1.1  1995/08/07  16:28:45  ram
# patch37: added support for locking on filesystems with short filenames
#
# Revision 3.0  1993/11/29  13:50:20  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
unlink 'mailagent.st';
$out = `$mailagent -summary 2>/dev/null`;
$? == 0 || print "1\n";
`cp /dev/null mailagent.st`;
$mail_test = <<'EOM';
From ram Sat Jul 11 18:51:16 PDT 1992
From: ram
To: ram
Subject: test

This is a test.
EOM
# First time creates new statistics, second time updates them.
for ($i = 0; $i < 2; $i++) {
	open(MAILAGENT, "|$mailagent -e 'STRIP Nothing; LEAVE' 2>/dev/null") ||
	print "2x$i\n";
	print MAILAGENT $mail_test;
	close MAILAGENT;
	$? == 0 || print "3x$i\n";
	sleep 1 while -f "perl$lockext";	# Wait for background process to finish
}
$user = $ENV{'USER'};
-s "$user" || print "4\n";
$out = `$mailagent -s 2>/dev/null`;
$out ne '' || print "5\n";
@out = split(/\n/, $out);
@leave = grep(/LEAVE/, @out);
@strip = grep(/STRIP/, @out);
@leave == @strip || print "6\n";
@leave == 1 || print "7\n";
$out = `$mailagent -sm 2>/dev/null`;
@out = split(/\n/, $out);
@leave = grep(/LEAVE/, @out);
@strip = grep(/STRIP/, @out);
@leave == @strip || print "8\n";
@leave == 2 || print "9\n";
$out = `$mailagent -sr 2>/dev/null`;
@out = split(/\n/, $out);
grep(/STRIP.*LEAVE/, @out) || print "10\n";
&get_log(11, 'mailagent.st');
&check_log('^---', 12) == 1 || print "13\n";	# Rules did not changed
&check_log('^\+\+\+', 14) == 1 || print "15\n";

# Now change rules slightly
open(MAILAGENT, "|$mailagent -e 'STRIP Other; LEAVE' 2>/dev/null") ||
print "16\n";
print MAILAGENT $mail_test;
close MAILAGENT;
$? == 0 || print "17\n";
sleep 1 while -f "perl$lockext";	# Wait for background process to finish
&get_log(18, 'mailagent.st');
&check_log('^---', 19) == 2 || print "20\n";	# Rules did changed
&check_log('^\+\+\+', 21) == 2 || print "22\n";

unlink 'mailagent.st', "$user";
print "0\n";
