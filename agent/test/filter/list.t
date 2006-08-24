# This tests mathching on list selectors like To or Newsgroups.

# $Id: list.t,v 3.0.1.3 2001/03/17 18:16:05 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: list.t,v $
# Revision 3.0.1.3  2001/03/17 18:16:05  ram
# patch72: unlink files we expect to be created before running command
#
# Revision 3.0.1.2  1999/07/12  13:57:15  ram
# patch66: added new test cases
#
# Revision 3.0.1.1  1996/12/24  15:03:03  ram
# patch45: added new tests for Relayed processing
#
# Revision 3.0  1993/11/29  13:50:01  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';

sub cleanup {
	for ($i = 1; $i <= 9; $i++) {
		unlink "$user.$i";
	}
	for ($i = 1; $i <= 3; $i++) {
		unlink "ok.$i";
	}
	unlink 'never';
}

&cleanup;
&add_header('X-Tag: list #1');
unlink "$user.1";
`$cmd`;
$? == 0 || print "1\n";
-f "$user.1" || print "2\n";
unlink "$user.1";

&replace_header('To: uunet!eiffel.com!max, other@max.com');
unlink "$user.2";
`$cmd`;
$? == 0 || print "3\n";
-f "$user.2" || print "4\n";
unlink "$user.2";

&replace_header('To: root@eiffel.com (Super User), max <other@max.com>');
unlink "$user.3";
`$cmd`;
$? == 0 || print "5\n";
-f "$user.3" || print "6\n";
unlink "$user.3";

# Following is illeaal in RFC-822: should be "root@eiffel.com" <maxime>
&replace_header('To: riot@eiffel.com (Riot Manager), root@eiffel.com <maxime>');
unlink "$user.4";
`$cmd`;
$? == 0 || print "7\n";
-f "$user.4" || print "8\n";
unlink "$user.4";

&replace_header('To: other, me, riotintin@eiffel.com, and, so, on');
unlink "$user.5";
`$cmd`;
$? == 0 || print "9\n";
-f "$user.5" || print "10\n";
unlink "$user.5";

&replace_header('To: other, me, chariot@eiffel.com, and, so, on');
unlink "$user.6";
`$cmd`;
$? == 0 || print "11\n";
-f "$user.6" || print "12\n";
unlink "$user.6";

&replace_header('To: other, me, abricot@eiffel.com, and, so, on');
&add_header('Newsgroups: comp.lang.perl, news.groups, news.lists');
unlink "$user.7";
`$cmd`;
$? == 0 || print "13\n";
-f "$user.7" || print "14\n";
unlink "$user.7";

&replace_header('Newsgroups: comp.lang.perl, news.groups, news.answers');
unlink "$user.9";
`$cmd`;
$? == 0 || print "15\n";
-f "$user.9" || print "16\n";
unlink "$user.9";

&replace_header('Newsgroups: none');
&replace_header('To: abricot@eiffel.com, rame@hp.com');
&add_header('To: root@localhost');

unlink "$user.8";
`$cmd`;
$? == 0 || print "17\n";
-f "$user.1" && print "18\n";
-f "$user.8" || print "19\n";
unlink "$user.8";

&replace_header('X-Tag: list #2');
`$cmd`;
$? == 0 || print "20\n";
-f 'ok.1' || print "21\n";
-f 'ok.2' || print "22\n";
-f 'ok.3' || print "23\n";
-f 'never' && print "24\n";

&cleanup;
unlink 'mail';
print "0\n";
