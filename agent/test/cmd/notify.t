# Test NOTIFY command

# $Id: notify.t,v 3.0.1.3 1995/01/25 15:32:47 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: notify.t,v $
# Revision 3.0.1.3  1995/01/25  15:32:47  ram
# patch27: ported to perl 5.0 PL0
#
# Revision 3.0.1.2  1994/10/10  10:25:55  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0.1.1  1994/01/26  09:35:34  ram
# patch5: ensure header-added recipients looked for in messages
#
# Revision 3.0  1993/11/29  13:49:36  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
do '../pl/mta.pl';

open(MSG, '>msg') || print "1\n";
print MSG <<EOM;
Organization: Public Domain Software, Earth, Milkway.

Sent by %n.
EOM
close MSG;

open(MSG, '>msg.2') || print "21\n";
print MSG <<'EOM';
Cc: someone@random, %u
Organization: Public Domain Software, Earth, Milkway.

Message body.
EOM
close MSG;

&add_header('X-Tag: notify 1');
`$cmd`;
$? == 0 || print "2\n";
-f "$user" && print "3\n";		# Mail not saved
&get_log(4, 'send.mail');
&check_log('^$', 5) == 1 || print "6\n";
&check_log('^Subject: Re: melting', 7) == 1 || print "8\n";
&check_log('^Recipients: nobody$', 9) == 1 || print "10\n";
&check_log('^Sent by compilers-request.$', 11) == 1 || print "12\n";

open(LIST, '>list') || print "13\n";
print LIST <<EOM;
first
# comment
second
third
EOM
close LIST;

&replace_header('X-Tag: notify 2');
unlink 'send.mail';
`$cmd`;
$? == 0 || print "14\n";
-f "$user" && print "15\n";		# Mail not saved
&get_log(16, 'send.mail');
&check_log('^To: first, second, third$', 17) == 1 || print "18\n";
&check_log('^Recipients: first second third$', 19) == 1 || print "20\n";
unlink 'send.mail', $user;

&replace_header('X-Tag: notify 3');
`$cmd`;
$? == 0 || print "22\n";
-f "$user" && print "23\n";		# Mail not saved
&get_log(24, 'send.mail');
&check_log('^$', 25) == 1 || print "26\n";
&check_log('^Subject: Re: melting', 27) == 1 || print "28\n";
$recipients = join(' ', sort split(' ',
	"someone\@random some\@random.ctry $user"));
$recipients =~ s/@/\\@/g;		# Escape @ for perl5, grrr...
&check_log("^Recipients: $recipients", 29) == 1 || print "30\n";
&check_log('^Cc: someone\@random, ' . $user, 31) == 1 || print "32\n";

&clear_mta;
unlink 'mail', 'list', 'msg', 'msg.2', $user;
# Last is 32
print "0\n";
