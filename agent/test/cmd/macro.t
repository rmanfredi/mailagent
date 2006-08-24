# Test MACRO command

# $Id: macro.t,v 3.0 1993/11/29 13:49:34 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: macro.t,v $
# Revision 3.0  1993/11/29  13:49:34  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
unlink 'ok';

&add_header('X-Tag: macro');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail not saved
-f 'ok' || print "3\n";			# Output of /bin/echo
&get_log(4, 'ok');
&check_log('^It seems to work fine.', 5);		# It works

unlink 'ok', 'mail';
print "0\n";
