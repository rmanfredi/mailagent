# Test hooking facilities

# $Id: hook.t,v 3.0 1993/11/29 13:50:00 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: hook.t,v $
# Revision 3.0  1993/11/29  13:50:00  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
do '../pl/logfile.pl';
unlink 'never', 'always', 'always.2', 'always.3';
unlink 'hook.1', 'hook.2', 'hook.3', 'hook.4';

open(HOOK, '>hook.1') || print "1\n";
print HOOK <<'EOH';
#! /bin/sh
cat > always
exit 0
EOH
close HOOK;

open(HOOK, '>hook.2') || print "2\n";
print HOOK <<'EOH';
#: deliver
open(OUT, '>always.2') || exit 1;
print OUT "$login\n";
close OUT;
print "SAVE ~/always; RUN /bin/echo hi! > always.3";
EOH
close HOOK;

open(HOOK, '>hook.3') || print "3\n";
print HOOK <<'EOH';
#: rules
!To: ram { SAVE never };
{ SAVE ~/always; RUN /bin/echo hi! > always.3 };
EOH
close HOOK;

open(HOOK, '>hook.4') || print "29\n";
print HOOK <<'EOH';
#: perl
&save("~/always");
&run("/bin/echo hi! > always.3");
EOH
close HOOK;
chmod 0544, 'hook.1', 'hook.2', 'hook.3', 'hook.4';

&add_header('X-Tag: hook #1');
`$cmd`;
$? == 0 || print "4\n";
-f 'never' && print "5\n";
&get_log(6, 'always');
&check_log('^To: ram', 7) == 1 || print "8\n";
&get_log(9, 'hook.1');
&not_log('^To: ram', 10);
unlink 'never', 'always', 'always.2', 'always.3';

&replace_header('X-Tag: hook #2');
`$cmd`;
$? == 0 || print "11\n";
-f 'never' && print "12\n";
&get_log(13, 'always');
&check_log('^To: ram', 14) == 1 || print "15\n";
&get_log(16, 'always.3');
&check_log('^hi!', 17) == 1 || print "18\n";
&get_log(19, 'always.2');
&check_log('^compilers-request$', 20);
unlink 'never', 'always', 'always.2', 'always.3';

&replace_header('X-Tag: hook #3');
`$cmd`;
$? == 0 || print "21\n";
-f 'never' && print "22\n";
&get_log(23, 'always');
&check_log('^To: ram', 24) == 1 || print "25\n";
&get_log(26, 'always.3');
&check_log('^hi!', 27) == 1 || print "28\n";
unlink 'never', 'always', 'always.2', 'always.3';

&replace_header('X-Tag: hook #4');
`$cmd`;
$? == 0 || print "30\n";
-f 'never' && print "31\n";
&get_log(32, 'always');
&check_log('^To: ram', 33) == 1 || print "34\n";
&get_log(35, 'always.3');
&check_log('^hi!', 36) == 1 || print "37\n";

unlink 'hook.1', 'hook.2', 'hook.3', 'hook.4';
unlink 'never', 'always', 'always.2', 'always.3';
print "0\n";
