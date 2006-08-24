# The BEEP command

# $Id: beep.t,v 3.0.1.2 1995/08/07 16:27:31 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: beep.t,v $
# Revision 3.0.1.2  1995/08/07  16:27:31  ram
# patch37: added regression testing for BEEP
#
# Revision 3.0.1.1  1995/01/25  15:32:12  ram
# patch27: created
#

do '../pl/cmd.pl';
sub cleanup {
	unlink $user, 'tty0';
}

&cleanup;
&make_tty(0, 0777, 1);	# 1 & 2

sub make_tty {
	local($n, $mode, $log) = @_;
	open(TTY, ">tty$n") || print "$log\n";
	$log++;
	close TTY;
	chmod($mode, "tty$n") || print "$log\n";
}

open(BIFF, '>bfmt') || print "3\n";
print BIFF <<'EOM';
Got mail in %f:%a
#%b
EOM
close BIFF;

&add_header('X-Tag: beep 1');
`$cmd`;
$? == 0 || print "4\n";
-f $user || print "5\n";
-s 'tty0' || print "6\n";
&get_log(7, 'tty0');
&check_log('^Got mail.*:\07\07\07\07$', 8);
&check_log('^\r#\07$', 9);
unlink $user;

&replace_header('X-Tag: beep 2');
`$cmd`;
$? == 0 || print "10\n";
-f $user || print "11\n";
-s 'tty0' || print "12\n";
&get_log(13, 'tty0');
&check_log('^Got mail.*:$', 14);
&check_log('^\r#\07$', 15);
unlink $user;

&cleanup;
unlink 'mail';
print "0\n";
