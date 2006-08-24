# Test KEEP command

# $Id: keep.t,v 3.0 1993/11/29 13:49:33 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: keep.t,v $
# Revision 3.0  1993/11/29  13:49:33  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'ok', 'no_resync';

open(LIST, '>header-list') || print "17\n";
print LIST <<EOL;
To
Subject
U*
X*
EOL
close LIST;

&add_header('X-Tag: keep');
&add_header('X-Long-Line: this is a long line and has a continuation');
&add_header('  right below it with a MARK token');
&add_header('  and another with the MARK token');
&add_header('X-Removed-Line: this is a long line and has a continuation');
&add_header('  right below it with another mark TOKEN');
&add_header('  and another with the mark TOKEN');
&add_header('unusual-header: None');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail saved...
-f 'ok' || print "3\n";			# ...here
&get_log(4, 'ok');
&not_log('^Received:', 5);		# Make sure Received: disappeared
&check_log('^To:', 6);			# But To: still here
&check_log('^From:', 7);
&check_log('^Subject:', 8);
&not_log('^X-None:', 9);
&check_log('MARK', 10) == 2 || print "11\n";		# Continuation line kept
&check_log('^X-Long-Line:', 12);	# So is the parent field
&not_log('^X-Removed-Line:', 13);
&not_log('TOKEN', 14);			# This continuation was removed
&check_log('^unusual-header:', 16);
-f 'no_resync' || print "15\n";	# Ensure header not disturbed

# Last: 17
unlink 'ok', 'no_resync', 'mail', 'header-list';
print "0\n";
