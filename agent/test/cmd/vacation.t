# The VACATION command

# $Id: vacation.t,v 3.0.1.4 2001/01/10 16:58:53 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: vacation.t,v $
# Revision 3.0.1.4  2001/01/10 16:58:53  ram
# patch69: changed "tome" settings due to dropping of dot stripping
#
# Revision 3.0.1.3  1995/01/25  15:33:28  ram
# patch27: ported to perl 5.0 PL0
#
# Revision 3.0.1.2  1995/01/03  18:20:34  ram
# patch24: added tests for new -l option and extended parameters
#
# Revision 3.0.1.1  1994/07/01  15:09:13  ram
# patch8: added check for no vacation when Illegal-Object or Illegal-Field
# patch8: make sure the new tome config variable is honored
#
# Revision 3.0  1993/11/29  13:49:55  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';
do '../pl/mta.pl';
unlink $user, 'dbr/c/o';

sub cleanup {
	unlink 'send.mail', $user;
}

`rm -rf dbr`;		# Enable vacation messages
&add_option("-o 'vacation: ON' -o 'user: ram'");

open(VACATION, '>.vacation') || print "1\n";
print VACATION <<EOM;
Organization: Public Domain Software, Earth, Milkway.

Sent by %n.
EOM
close VACATION;

&add_header('X-Tag: vacation');	# No match in actions...
`$cmd`;
$? == 0 || print "2\n";
-f "$user" || print "3\n";		# Mail not saved
&get_log(4, 'send.mail');
&check_log('^$', 5) == 1 || print "6\n";
&check_log('^Subject: Re: melting', 7) == 1 || print "8\n";
&check_log('^Recipients: compilers-request\@iecc', 9) == 1 || print "10\n";
&check_log('^Sent by compilers-request.$', 11) == 1 || print "12\n";

&cleanup;
`$cmd`;							# This time, no vacation message
$? == 0 || print "13\n";
-f "$user" || print "14\n";		# Mail not saved, default rule applied
-f 'send.mail' && print "15\n";	# No vacation message sent

`rm -rf dbr`;		# Enable vacation messages

# Make sure vacation message is also sent when a rule match occurs

&replace_header('X-Tag: vacation #2');
&cleanup;
`$cmd`;
$? == 0 || print "29\n";
-f "$user" && print "30\n";		# Mail has been deleted
&get_log(31, 'send.mail');
&check_log('^$', 32) == 1 || print "33\n";
&check_log('^Subject: Re: melting', 34) == 1 || print "35\n";
&check_log('^Recipients: compilers-request\@iecc', 36) == 1 || print "37\n";
&check_log('^Sent by compilers-request.$', 38) == 1 || print "39\n";

`rm -rf dbr`;		# Enable vacation messages

# Ensure vacation message is sent when mail was addressed to an alias

&replace_header('To: Raphael.Manfredi@acri.fr');
&cleanup;
&add_option('-o tome:rmanfredi,raphael.man*');
`$cmd`;
$? == 0 || print "40\n";
-f "$user" && print "41\n";		# Mail has been deleted
-f 'send.mail' || print "42\n";	# Assume OK at that point if mail exists

&replace_header('X-Tag: vacation');	# Restore non-matching header
`rm -rf dbr`;						# Enable vacation messages

# Ensure vacation message is NOT sent when mail header has illegal headers

&cleanup;
&add_header('Illegal-Object: true');	# Will prevent vacation
`$cmd`;
$? == 0 || print "16\n";
-f "$user" || print "17\n";		# Mail not saved, default rule applied
-f 'send.mail' && print "18\n";	# No vacation message sent
&get_log(19, $user);
&check_log('^Illegal-Object:', 20) == 1 || print "21\n";

&cleanup;
&replace_header('Illegal-Object:', 'mail', 'Illegal-Field: from');
`$cmd`;
$? == 0 || print "22\n";
-f "$user" || print "23\n";		# Mail not saved, default rule applied
-f 'send.mail' && print "24\n";	# No vacation message sent
&get_log(25, $user);
&not_log('^Illegal-Object:', 26);
&check_log('^Illegal-Field:', 27) == 1 || print "28\n";
&replace_header('Illegal-Field:', 'mail', 'X-Removed: illegal-field');

# Ensure local setting of vacation message is understood as it should

open(VACATION, '>.vacfile') || print "43\n";
print VACATION <<EOM;
Organization: Public Domain Software, Earth, Milkway.

Sent by ram.
EOM
close VACATION;

&cleanup;
&replace_header('X-Tag: vacation #3');
`rm -rf dbr`;						# Enable vacation messages
`$cmd`;
$? == 0 || print "44\n";
-f "$user" && print "45\n";		# Mail deleted
-f 'send.mail' || print "46\n";	# Vacation message sent
&get_log(47, 'send.mail');
&check_log('^Sent by compilers-request.$', 48) == 1 || print "49\n";

&cleanup;
&replace_header('X-Tag: vacation #4');
`rm -rf dbr`;						# Enable vacation messages
`$cmd`;
$? == 0 || print "50\n";
-f "$user" && print "51\n";		# Mail deleted
-f 'send.mail' || print "52\n";	# Vacation message sent
&get_log(53, 'send.mail');
&check_log('^Sent by ram.$', 54) == 1 || print "55\n";

# Last: 55
&clear_mta;
unlink 'mail', '.vacation';
print "0\n";
