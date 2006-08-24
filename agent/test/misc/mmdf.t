# Test MMDF-style mailboxes

# $Id: mmdf.t,v 3.0 1993/11/29 13:50:09 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: mmdf.t,v $
# Revision 3.0  1993/11/29  13:50:09  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';
unlink "$user", 'always';

&add_option("-o 'mmdf: ON' -o 'mmdfbox: OFF'");
&add_header('X-Tag: mmdf');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";
-f 'always' || print "3\n";

sub has_ctrl {
	local($file) = @_;
	open(FILE, $file) || return 0;
	local($count) = 0;
	local($_);
	while (<FILE>) {
		$count++ if /^\01\01\01\01$/;
	}
	$count;
}

&has_ctrl($user) == 0 || print "4\n";
&has_ctrl('always') == 0 || print "5\n";

$cmd =~ s/mmdfbox: OFF/mmdfbox: ON/ || print "6\n";
unlink 'always';
`$cmd`;
$? == 0 || print "7\n";
-f "$user" || print "8\n";
-f 'always' || print "9\n";

&has_ctrl($user) == 0 || print "10\n";
&has_ctrl('always') == 4 || print "11\n";

unlink $user, 'always', 'mail';
print "0\n";
