# Test ANNOTATE command

# $Id: annotate.t,v 3.0.1.1 1995/01/03 18:20:17 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: annotate.t,v $
# Revision 3.0.1.1  1995/01/03  18:20:17  ram
# patch24: added tests for new -u option
#
# Revision 3.0  1993/11/29  13:49:26  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';

sub cleanup {
	unlink "$user", 'never';
}

&cleanup;
&add_header('X-Tag: annotate');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";		# No match -> leave
&get_log(3, $user);
&check_log('^X-Anno-1:', 4) == 2 || print "5\n";
&check_log('^X-Anno-2:', 6) == 2 || print "7\n";
&check_log('^X-Anno-3:', 8) == 1 || print "9\n";
&check_log('^X-Anno-4:', 10) == 2 || print "11\n";	# No RESYNC done
&not_log('^X-Anno-Error:', 12);
&check_log('^X-Anno-5:', 13) == 1 || print "14\n";
-f 'never' && print "15\n";

&cleanup;
unlink 'mail';
print "0\n";
