# Make sure default actions apply correctly

# $Id: default.t,v 3.0 1993/11/29 13:49:58 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: default.t,v $
# Revision 3.0  1993/11/29  13:49:58  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';

&add_header('X-Tag: default #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Must have been deleted

&replace_header('X-Tag: default #2');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" || print "4\n";		# A NOP -> default action leave
&get_mbox(5);

&replace_header('X-Tag: never matched');
`$cmd`;
$? == 0 || print "6\n";
-f "$user" || print "7\n";		# No match -> default action
&get_mbox(8);
$mbox2 eq $mbox1 || print "9\n";

&replace_header('X-Tag: unknonw');
`$cmd`;
$? == 0 || print "10\n";
-f "$user" || print "11\n";		# Unknown action without previous saving
&get_mbox(12);
$mbox2 eq $mbox1 || print "13\n";
unlink 'mail';
print "0\n";

sub get_mbox {
	local($num);
	undef $/;
	open(MBOX, "$user");
	eval "$mbox$num = <MBOX>";
	close MBOX;
	$/ = "\n";
	unlink "$user";
}

