# Test POST command

# $Id: post.t,v 3.0 1993/11/29 13:49:39 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: post.t,v $
# Revision 3.0  1993/11/29  13:49:39  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
do '../pl/mta.pl';

&add_header('X-Tag: post 1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail not saved
&get_log(4, 'send.news');
&not_log('^To: ram', 5);		# Stripped out
&not_log('^Received:', 6);		# Stripped out
&check_log('^Newsgroups: alt.test,comp.others', 7) == 1 || print "8\n";
&not_log('^Distribution:', 9);

open(LIST, '>list') || print "13\n";
print LIST <<EOM;
first.news
# comment
second.news
third.news
EOM
close LIST;

&replace_header('X-Tag: post 2');
unlink 'send.news';
`$cmd`;
$? == 0 || print "10\n";
-f "$user" && print "11\n";		# Mail not saved
&get_log(12, 'send.news');
&check_log('^Newsgroups: first.news,second.news,third.news', 13);
&check_log('^Distribution: local', 14);

unlink 'send.news';
&replace_header('X-Tag: post 1');
# Subject with a trailing space
my $subject = <<EOM;
Subject: [perl #2783] Security of ARGV using 2-argument open - It's a feature 
EOM
chop $subject;
replace_header($subject);
`$cmd`;
$? == 0 || print "15\n";
&get_log(16, 'send.news');
# 1 EOH + 3 paragraphs in mail
&check_log('^$', 17) == 4 or print "18\n";

&clear_mta;
unlink 'mail', 'list';
print "0\n";
