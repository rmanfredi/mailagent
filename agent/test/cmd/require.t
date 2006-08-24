# Test REQUIRE command

# $Id: require.t,v 3.0 1993/11/29 13:49:45 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: require.t,v $
# Revision 3.0  1993/11/29  13:49:45  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'perl.1', 'perl.2', 'never', 'ok';

open(PERL, ">perl.1") || print "1\n";
print PERL <<'EOP';
sub perl_1 {
	local($name) = @_;
	$name;
}
EOP
close PERL;

open(PERL, ">perl.2") || print "2\n";
print PERL <<'EOP';
$var = "perl_2";

sub perl_2 {
	$var;
}
EOP
close PERL;

&add_header('X-Tag: require');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";
-f 'never' && print "5\n";
&get_log(6, 'ok');
&check_log('^We got perl_1 and perl_2 here', 7);

unlink 'mail', 'perl.1', 'perl.2', 'never', 'ok';
print "0\n";
