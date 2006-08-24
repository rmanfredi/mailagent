# Test FORWARD command

# $Id: forward.t,v 3.0 1993/11/29 13:49:31 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: forward.t,v $
# Revision 3.0  1993/11/29  13:49:31  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
do '../pl/mta.pl';

&add_header('X-Tag: forward 1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail not saved
&get_log(4, 'send.mail');
&check_log('^Resent-', 5) == 2 || print "6\n";
&check_log('^Resent-To: nobody', 7) == 1 || print "8\n";
&check_log('^To: ram', 9) == 1 || print "10\n";
&check_log('^Recipients: nobody$', 11) == 1 || print "12\n";

open(LIST, '>list') || print "13\n";
print LIST <<EOM;
first
# comment
second
third
EOM
close LIST;

&replace_header('X-Tag: forward 2');
unlink 'send.mail';
`$cmd`;
$? == 0 || print "14\n";
-f "$user" && print "15\n";		# Mail not saved
&get_log(16, 'send.mail');
&check_log('^Resent-', 17) == 2 || print "18\n";
&check_log('^Resent-To: first, second, third$', 19) == 1 || print "20\n";
&check_log('^To: ram', 21) == 1 || print "22\n";
&check_log('^Recipients: first second third$', 23) == 1 || print "24\n";

&clear_mta;
unlink 'mail', 'list';
print "0\n";
