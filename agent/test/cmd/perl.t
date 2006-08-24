# Test PERL command

# $Id: perl.t,v 3.0.1.1 1994/07/01 15:08:05 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: perl.t,v $
# Revision 3.0.1.1  1994/07/01  15:08:05  ram
# patch8: added test for correct exit status propagation
#
# Revision 3.0  1993/11/29  13:49:38  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'perl.1', 'perl.2', 'never', 'always', 'exit_ok';

open(PERL, ">perl.1") || print "1\n";
print PERL <<'EOP';
&save('always') || &save('never');
&reject('-t');
&save('never');
EOP
close PERL;

open(PERL, ">perl.2") || print "2\n";
print PERL <<'EOP';
unlink 'always' if -d '../out';
&exit(1) if $ARGV[1] ne 'arg 1' || $ARGV[2] ne 'arg 2';
&perl('perl.1');		# Recursion
&save('never');
EOP
close PERL;

&add_header('X-Tag: perl');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";
-f 'never' && print "5\n";
&get_log(6, 'always');
&check_log('^To: ram', 7) == 2 || print "8\n";
-f 'exit_ok' || print "9\n";

unlink 'mail', 'perl.1', 'perl.2', 'never', 'always', 'exit_ok';
print "0\n";
