# Test user-defined macros at the perl level
# NOTE: this test relies on a working PERL command

# $Id: usrmac.t,v 3.0 1993/11/29 13:50:11 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: usrmac.t,v $
# Revision 3.0  1993/11/29  13:50:11  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink "$user";

open(SCRIPT, '>script') || print "1\n";
print SCRIPT <<'EOC';
sub macfunc {				# Used for function macro substitution
	"macfunc $_[0] string";
}
$macval = 'macval string';	# Used for perl expression macro substitution

&usrmac'new('m', 'orig-macro-m', 'SCALAR');
&usrmac'push('m', 'this-is-macro-m', 'SCALAR');
&usrmac'new('mac1', "\$mailhook'macval", 'CONST');
&usrmac'new('mac2', "mailhook'macfunc", 'FN');
&substitute(1);

&usrmac'new('m', 'this-is-macro-mbis', 'SCALAR');
&usrmac'push('mac1', "\$mailhook'macval", 'EXPR');
&usrmac'push('mac2', '/bin/sh -c "echo macro %%-[%n]"', 'PROG');
$macval = 'macval bis';
&substitute(2);

&usrmac'pop('mac1');
&usrmac'pop('mac2');
&usrmac'pop('m');
&substitute(3);

sub substitute {
	local($num) = @_;
	open(TEXT, 'text');
	open(OUT, ">subst.$num");
	local($_);
	while (<TEXT>) {
		print OUT &'macros_subst(*_);
	}
	close OUT;
	close TEXT;
}
EOC
close SCRIPT;

open(TEXT, '>text') || print "2\n";
print TEXT <<'EOT';
%%%A%%
%N
%-m
%=vacation
%-(mac1)
%-(mac2)
This %-m is %-(mac1) and %-(mac2).
EOT
close TEXT;

$result1 = <<'EOR';
%cambridge.ma.us%
compilers-request
this-is-macro-m
OFF
macval string
macfunc mac2 string
This this-is-macro-m is macval string and macfunc mac2 string.
EOR

$result2 = <<'EOR';
%cambridge.ma.us%
compilers-request
this-is-macro-mbis
OFF
macval bis
macro %-[mac2]
This this-is-macro-mbis is macval bis and macro %-[mac2].
EOR

$result3 = <<'EOR';
%cambridge.ma.us%
compilers-request
orig-macro-m
OFF
macval string
macfunc mac2 string
This orig-macro-m is macval string and macfunc mac2 string.
EOR

sub verify {
	local($file, $result, $error) = @_;
	local($var);
	$var = `cat $file 2>&1`;
	$var eq $result || print "$error\n";
}

&add_header('X-Tag: usrmac');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";	# Created only if perl script fails
&verify('subst.1', $result1, 5);
&verify('subst.2', $result2, 6);
&verify('subst.3', $result3, 7);
unlink "$user", 'mail', 'script', 'text', 'subst.1', 'subst.2', 'subst.3';
print "0\n";

