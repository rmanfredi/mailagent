# Test UMASK command

# $Id: umask.t,v 3.0.1.3 1996/12/24 15:02:36 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: umask.t,v $
# Revision 3.0.1.3  1996/12/24  15:02:36  ram
# patch45: fixed test for perl5
#
# Revision 3.0.1.2  1995/02/03  18:05:08  ram
# patch30: fixed regexp bug that could lead the test to fail
#
# Revision 3.0.1.1  1994/07/01  15:08:10  ram
# patch8: created
#

do '../pl/misc.pl';		# Uses &add_option

sub cleanup {
	unlink $user, 'ok.1', 'ok.2', 'ok.3', 'never';
}

open(PERL, ">umask_is") || print "1\n";
print PERL <<'EOP';
$mode = $ARGV[1];
$mode = oct($mode) if $mode =~ /^0/;

# In perl5 the sub umask declaration in the mailhook package interferes
# with the umask built-in. Therefore, we must ensure we call the
# right version while running this PERL hook. To avoid an eval, we
# simply switch to package main while calling umask!
{
	package main;
	$mailhook'umask = umask;
}

&exit($mode == $umask ? 0 : 1);
EOP
close PERL;

&cleanup;
&add_header('X-Tag: umask #1');
`$cmd`;
$? == 0 || print "2\n";
-f $user && print "3\n";
-f 'never' && print "4\n";
-f 'ok.1' || print "5\n";
-f 'ok.2' || print "6\n";

&cleanup;
&replace_header('X-Tag: umask #3');
system '(cat mail; echo " "; cat mail) > mail2 && mv mail2 mail';
print "7\n" if $?;
$cmd =~ s/($mailagent.*)\bmail\b/$1-f mail/;	# exclude path...
&add_option("-o 'umask: 027'");
&replace_header('X-Tag: umask #2');

# At this point, we're going to process two messages in mail. The first
# one is tagged 'umask #2' and the second is tagged 'umask #3'. We wish
# to make sure that mailagent restores the default umask before processing
# a new message.

`$cmd`;
$? == 0 || print "8\n";
-f $user && print "9\n";
-f 'never' && print "10\n";
-f 'ok.1' || print "11\n";
-f 'ok.2' || print "12\n";
-f 'ok.3' || print "13\n";

&cleanup;
unlink 'umask_is';
print "0\n";
