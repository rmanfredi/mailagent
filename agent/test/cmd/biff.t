# The BIFF command

# $Id: biff.t,v 3.0.1.1 1995/08/07 16:28:37 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: biff.t,v $
# Revision 3.0.1.1  1995/08/07  16:28:37  ram
# patch37: created
#

do '../pl/cmd.pl';
sub cleanup {
	unlink $user, 'tty0', 'tty1', 'tty3', 'ok';
}

&cleanup;
&make_tty(0, 0777, 1);	# 1 & 2
&make_tty(1, 0666, 3);	# 3 & 4
&make_tty(3, 0777, 5);	# 5 & 6

sub make_tty {
	local($n, $mode, $log) = @_;
	open(TTY, ">tty$n") || print "$log\n";
	$log++;
	close TTY;
	chmod($mode, "tty$n") || print "$log\n";
}

open(BIFF, '>bfmt') || print "7\n";
print BIFF <<'EOM';
Got mail in %f:
%-H

%-B
#####
EOM
close BIFF;

&add_header('X-Tag: biff 1');
`$cmd`;
$? == 0 || print "8\n";
-f $user || print "9\n";
-f 'ok' || print "10\n";
-s 'tty1' && print "11\n";
-s 'tty0' || print "12\n";
-s 'tty3' || print "13\n";
-s('tty0') == -s('tty3') || print "14\n";
$dflt_size = -s 'tty0';
&get_log(15, 'tty0');
&check_log('^\rTo: ram', 16) == 1 || print "17\n";
&check_log('^\r----', 18) == 2 || print "19\n";
&not_log('^\r####', 20);
unlink $user, 'ok';

&replace_header('X-Tag: biff 2');
`$cmd`;
$? == 0 || print "21\n";
-f $user || print "22\n";
-f 'ok' || print "23\n";
-s('ok') == -s($user) || print "24\n";
-s 'tty1' && print "25\n";
-s 'tty0' || print "26\n";
-s 'tty3' || print "27\n";
-s('tty0') == -s('tty3') || print "28\n";
-s('tty0') != $dflt_size || print "29\n";
&get_log(30, 'tty0');
&check_log('^\rTo: ram', 31) == 1 || print "32\n";
&check_log('^Got mail in ~/ok', 33) == 1 || print "34\n";
&check_log('^\r####', 35) == 1 || print "36\n";
&check_log('moderated usenet', 37) == 1 || print "38\n";
&not_log('^\r----', 39);
&cleanup;

cp_mail("../mime");
&add_header('X-Tag: biff 3');
&make_tty(0, 0777, 40);	# 40 & 41
`$cmd`;
$? == 0 || print "42\n";
-f 'ok' || print "43\n";
-s 'tty0' || print "44\n";
&get_log(45, 'tty0');
&not_log('--foo', 46);
&check_log('^Got mail in ~/ok', 47) == 1 || print "48\n";
&check_log('successfully decoded', 49) == 1 || print "50\n";
&cleanup;

cp_mail("../qp");
my $subject = <<EOM;
Subject: =?latin1?Q?Perl:_La_haute_technicit=E9_au_service_des_professionnels?=
EOM
chop $subject;
&replace_header($subject);
&add_header('X-Tag: biff 3');
&make_tty(0, 0777, 50);	# 51 & 52
`$cmd`;
$? == 0 || print "53\n";
&get_log(54, 'tty0');
&check_log(
	'Subject: Perl: La haute technicité au service des professionnels', 55);
&cleanup;

cp_mail("../mime-recursive");
&add_header('X-Tag: biff 3');
&make_tty(0, 0777, 40);	# 56 & 57
`$cmd`;
$? == 0 || print "58\n";
-f 'ok' || print "59\n";
-s 'tty0' || print "60\n";
&get_log(61, 'tty0');
&not_log('--foo', 62);
&not_log('--bar', 63);
&check_log('^Got mail in ~/ok', 64) == 1 || print "65\n";
&check_log('successfully decoded', 66) == 1 || print "67\n";
&cleanup;

unlink 'mail';
print "0\n";
