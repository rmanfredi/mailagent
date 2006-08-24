# Test APPLY command

# $Id: apply.t,v 3.0.1.1 1999/07/12 13:56:51 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: apply.t,v $
# Revision 3.0.1.1  1999/07/12  13:56:51  ram
# patch66: added test for variable propagation
#
# Revision 3.0  1993/11/29  13:49:26  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';

sub cleanup {
	unlink 'apply.1', 'apply.2', 'never', 'always', 'folder';
}

&cleanup;
open(RULES, ">apply.1") || print "1\n";
print RULES <<'EOR';
# Make sure there is no side effect with calling environment wrt states
<INITIAL> To: ram
	{
		BEGIN OTHER;
		APPLY apply.2;
		REJECT -f;
		BEGIN IMPOSSIBLE
	};
# This one will be called recursively from apply.2
<APPLY_2>			{ ABORT };
{ SAVE never };
EOR
close RULES;

open(RULES, ">apply.2") || print "2\n";
print RULES <<'EOR';
# We are in OTHER mode when called from apply.1
<OTHER>		{ SAVE always; BEGIN APPLY_2; APPLY apply.1; REJECT -t };
# Called from main 'actions' file.
<APPLY>		{ SAVE always };
{ SAVE never };
EOR
close RULES;

&add_header('X-Tag: apply #1');
`$cmd`;
$? == 0 || print "3\n";
-f "$user" && print "4\n";
-f 'never' && print "5\n";
&get_log(6, 'always');
&check_log('^To: ram', 7) == 3 || print "8\n";
&cleanup;

open(RULES, ">apply.1") || print "9\n";
print RULES <<'EOR';
# Ensure non-persistent variables are propagated back and forth through APPLY
{
	SAVE %#folder;
	ASSIGN folder always;
};
EOR
close RULES;

&replace_header('X-Tag: apply #2');
`$cmd`;
$? == 0 || print "10\n";
-f "$user" && print "11\n";
-f "never" && print "12\n";
-f "folder" || print "13\n";
-f "always" || print "14\n";

unlink 'mail', 'mbox';		# 'mbox' is the default mailbox if no args to SAVE
&cleanup;
print "0\n";
