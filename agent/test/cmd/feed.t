# Test FEED command

# $Id: feed.t,v 3.0 1993/11/29 13:49:31 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: feed.t,v $
# Revision 3.0  1993/11/29  13:49:31  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'ok', 'resynced';

&add_header('X-Tag: feed 1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail saved...
&get_log(3, 'ok');				# ...here
&check_log('^$', 4);			# EOH present
&not_log('^To:', 5);			# Make sure To: disappeared
-f 'resynced' || print "6\n";	# Ensure RESYNC was done under the hood

unlink 'ok', 'resynced', 'mail';

# PIPE checks base64, FEED checks quoted-printable

&cp_mail("../qp");
&add_header('X-Tag: feed 2');
`$cmd`;
$? == 0 || print "7\n";
get_log(8, 'output');
check_log('Content-Transfer-Encoding: quoted-printable', 9);
not_log('broken', 10);
&check_log('^$', 11);			# EOH present

unlink 'output', "$user";

&replace_header('X-Tag: feed 3');
`$cmd`;
$? == 0 || print "12\n";
get_log(13, 'output');
not_log('Content-Transfer-Encoding:', 14);
check_log('broken', 15);
&check_log('^$', 16);			# EOH present
get_log(17, $user);
check_log('Content-Transfer-Encoding: quoted-printable', 18);
not_log('broken', 19);

unlink 'output', "$user";

&replace_header('X-Tag: feed 4');
`$cmd`;
$? == 0 || print "20\n";
get_log(21, 'output');
not_log('Content-Transfer-Encoding:', 22);
check_log('broken', 23);
&check_log('^$', 24);			# EOH present
get_log(25, $user);
check_log('Content-Transfer-Encoding: quoted-printable', 26);
not_log('broken', 27);

unlink 'output', "$user";

# Check that message will be recoded optimally as 7bit
&cp_mail("../base64");
&add_header('X-Tag: feed 4');
`$cmd`;
$? == 0 || print "28\n";
get_log(29, 'output');
not_log('Content-Transfer-Encoding:', 30);
check_log('successfully', 31);
check_log('^$', 32);			# EOH present
get_log(33, $user);
check_log('Content-Transfer-Encoding: 7bit', 34);
check_log('successfully', 35);

unlink 'output', 'mail', "$user";
print "0\n";
