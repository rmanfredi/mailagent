# The SPLIT command

# $Id: split.t,v 3.0.1.2 1997/09/15 15:18:10 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: split.t,v $
# Revision 3.0.1.2  1997/09/15  15:18:10  ram
# patch57: fixed overzealous unlinks
#
# Revision 3.0.1.1  1994/10/10  10:26:05  ram
# patch19: added various escapes in strings for perl5 support
#
# Revision 3.0  1993/11/29  13:49:50  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';

&add_header('X-Tag: digest #2');
&make_digest;

# First time, normal split: one (empty) header plus 3 digest items.
# A single 'SPLIT here' is run
&add_header('X-Tag: split #1', 'digest');
`cp digest mail`;
unlink 'mail.lock';
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";			# Was not split in-place, but also saved
-f 'here' || print "3\n";			# Where digest was split...
&get_log(4, 'here');				# Slurp folder in @log
&check_log('^X-Tag: digest #1', 5) == 2 || print "6\n";
&check_log('^X-Tag: digest #2', 7) == 2 || print "8\n";
&check_log('^X-Tag: digest #3', 9) == 2 || print "10\n";
&check_log('^X-Tag: split #1', 11) == 2 || print "12\n";
&check_log('^X-Filter-Note:', 13) == 2 || print "14\n";
unlink 'here', 'mail.lock';

# Seconde time: a single 'SPLIT -id here' is run
&replace_header('X-Tag: split #2', 'digest');
`cp digest mail`;
`$cmd`;
$? == 0 || print "15\n";
-f "$user" && print "16\n";			# Was not split in-place, but in folder
-f 'here' || print "17\n";			# Where digest was split...
&get_log(18, 'here');				# Slurp folder in @log
&check_log('^X-Tag: digest #1', 19) == 1 || print "20\n";
&check_log('^X-Tag: digest #2', 21) == 1 || print "22\n";
&check_log('^X-Tag: digest #3', 23) == 1 || print "24\n";
&not_log('^X-Tag: split #2', 25);	# Header was deleted by -d
&check_log('^X-Filter-Note:', 26) == 2 || print "27\n";
&check_log('^X-Digest-To:', 84) == 3 || print "85\n";
unlink 'here', 'mail.lock';

# Third time: a single 'SPLIT -iew here' is run
&replace_header('X-Tag: split #3', 'digest');
`cp digest mail`;
`$cmd`;
$? == 0 || print "28\n";
-f "$user" && print "29\n";			# Was not split in-place, but in folder
-f 'here' || print "30\n";			# Where digest was split...
&get_log(31, 'here');				# Slurp folder in @log
&check_log('^X-Tag: digest #1', 32) == 1 || print "33\n";
&check_log('^X-Tag: digest #2', 34) == 1 || print "35\n";
&check_log('^X-Tag: digest #3', 36) == 1 || print "37\n";
&not_log('^X-Tag: split #3', 38);	# Header was deleted by -e
&check_log('^X-Filter-Note:', 39) == 3 || print "40\n";	# Trailing garbage...
&check_log('anticonstitutionellement', 41) == 1 || print "42\n";
unlink 'here', 'mail.lock';

# Fourth time: a single 'SPLIT -iew' is run. All the digest items will still
# be saved in 'here' because they all bear a X-Tag: header. The trailing
# garbage will not match anything and will be left in the mailbox.
&replace_header('X-Tag: split #4', 'digest');
`cp digest mail`;
`$cmd`;
$? == 0 || print "43\n";
-f "$user" || print "44\n";			# That must be the trailing garbage
-f 'here' || print "45\n";			# Where digest was split...
&get_log(46, 'here');				# Slurp folder in @log
&check_log('^X-Tag: digest #1', 47) == 1 || print "48\n";
&check_log('^X-Tag: digest #2', 49) == 1 || print "50\n";
&check_log('^X-Tag: digest #3', 51) == 1 || print "52\n";
&not_log('^X-Tag: split #3', 53);	# Header was deleted by -e
&check_log('^X-Filter-Note:', 54) == 2 || print "55\n";	# No trailing garbage...
&not_log('anticonstitutionellement', 56);
&get_log(57, "$user");
&check_log('anticonstitutionellement', 58) == 1 || print "59\n";
&check_log('^X-Filter-Note:', 60) == 1 || print "61\n";
unlink 'here', "$user", 'mail.lock';

# Fifth time: a single 'SPLIT -iew here', but this time header is not empty...
# Besides, there will be an empty message between encapsulation boundaries
# and we want to make sure SPLIT deals correctly with it. Trailing garbage
# is removed.
open(MAIL, ">mail");
close MAIL;
&make_digest('Not empty digest header');
`cp digest mail`;
&add_header('X-Tag: split #5');
`$cmd`;
$? == 0 || print "62\n";
-f 'here' || print "63\n";			# Where digest was split...
&get_log(64, 'here');				# Slurp folder in @log
&check_log('^X-Tag: digest #1', 65) == 1 || print "66\n";
&check_log('^X-Tag: digest #3', 67) == 1 || print "68\n";
&not_log('^X-Tag: digest #2', 69);	# Empty second message
&not_log('Mailagent-Test-Suite', 70);	# No trailing garbage
&check_log('^X-Filter-Note:', 71) == 2 || print "72\n";
&check_log('^From ', 73) == 4 || print "74\n";	# One built up for last item
&check_log('^Message-Id:', 75) == 1 || print "76\n";
&check_log('^>From', 80) == 2 || print "81\n";
&check_log('^From which', 82) == 1 || print "83\n";
unlink 'here', 'mail.lock';

# Sixth time: mail is not in digest format.
`cp ../mail .`;
$? == 0 || print "77\n";		# Fool guard for myself
&add_header('X-Tag: split #5');
`$cmd`;
$? == 0 || print "78\n";
-f 'here' || print "79\n";		# Where mail was saved (not in digest format)

unlink 'mail', 'here', 'digest';
# Last is 85
print "0\n";

# Build digest out of mail
sub make_digest {
	local($msg) = @_;		# Optional, first line in header
	&get_log(100, 'mail');	# Slurp mail in @log
	open(DIGEST, ">digest");
	print DIGEST <<EOH;
Received: from eiffel.eiffel.com by lyon.eiffel.com (5.61/1.34)
	id AA25370; Fri, 10 Jul 92 23:48:30 -0700
Received: by eiffel.eiffel.com (4.0/SMI-4.0)
	id AA27809; Fri, 10 Jul 92 23:45:14 PDT
Date: Fri, 10 Jul 92 23:45:14 PDT
From: root\@eiffel.com (Postmaster)
Message-Id: <9207110645.AA27809\@eiffel.eiffel.com>
To: postmaster\@eiffel.com
Subject: Mail Report - 10/07

$msg
----------------------------------------------
From ram Sun Jul 12 18:20:27 PDT 1992
From: ram
Subject: Notice
X-Tag: digest #1

Just to tell you there was no digest header... unless $msg set

----

EOH
	print DIGEST @log;
	print DIGEST <<'EOM';
----
From: ram
X-Tag: digest #3

From line should be >escaped.
Another message with a really minimum set of header!!
From which should NOT be

From escaped again...
----

EOM
	if ($msg eq '') {
		print DIGEST <<'EOM';
This is trailing garbage. I will use the SPLIT command with the '-w'
option and this will be saved is a separate mail with the subject
taken from that of the whole digest, with the words (trailing garbage)
appended to it... This token, "anticonstitutionellement " will make
it obvious for grep -- it's the longest word in French, and it means
the government is not doing its job, roughly speaking :-).
EOM
	} else {
		print DIGEST <<'EOM';
End of digest Mailagent-Test-Suite
**********************************
EOM
	}
	close DIGEST;
}

