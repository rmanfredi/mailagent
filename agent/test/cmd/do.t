# Test DO command

# $Id: do.t,v 3.0.1.1 1994/09/22 14:41:01 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: do.t,v $
# Revision 3.0.1.1  1994/09/22  14:41:01  ram
# patch12: created
#

do '../pl/cmd.pl';
sub cleanup {
	unlink 'perl.1', 'perl.2', 'never', 'always', 'always.2';
}

&cleanup;
open(PERL, ">perl.1") || print "1\n";
print PERL <<'EOP';
sub perl_1 {
	local($name) = @_;
	&mailhook'save($name);
}
EOP
close PERL;

open(PERL, ">perl.2") || print "2\n";
print PERL <<'EOP';
sub perl_2 {
	return if defined &main'perl_1;
	return unless defined &__test__'perl_1;
	local($mode) = @_;
	&mailhook'reject($mode);
}

sub __foo__'perl_3 {
	local($name) = @_;
	return unless defined &perl_2;
	return if defined $name;
	&mailhook'abort;
}
EOP
close PERL;

&add_header('X-Tag: do');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";
-f 'never' && print "5\n";
-f 'always' || print "6\n";
-f 'always.2' || print "7\n";

unlink 'mail';
&cleanup;
print "0\n";
