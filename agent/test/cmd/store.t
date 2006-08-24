# The STORE command

# $Id: store.t,v 3.0 1993/11/29 13:49:50 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: store.t,v $
# Revision 3.0  1993/11/29  13:49:50  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
$mbox = 'mbox';

&add_header('X-Tag: store #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$mbox" || print "2\n";		# Mail saved here
-f "$user" || print "3\n";		# Leave copy in mailbox
-s "$mbox" == -s "$user" || print "4\n";	# Same content

# When mailbox protected against writing...
unlink <emerg/*>;
unlink "$user";
$size = -s "$mbox";
chmod 0444, "$mbox";
`$cmd`;
$? == 0 || print "5\n";
-f "$mbox" || print "6\n";				# Must still be there
$size == -s "$mbox" || print "7\n";		# And not altered
-f "$user" || print "8\n";				# Left only copy in mailbox
$size == -s "$user" || print "9\n";		# Which must also match in size
@emerg = <emerg/*>;
@emerg == 1 || print "10\n";			# Emeregency as SAVE failed

# There is no X-Filter mail in the emergency saving
`grep -v X-Filter: $mbox > ok`;
$? == 0 || print "11\n";
-s $emerg[0] eq -s 'ok' || print "12\n";	# Full mail saved, of course
unlink "$mbox", "$user";

# Make sure STORE creates full path when needed
&replace_header('X-Tag: store #2');
`rm -rf path` if -d 'path';
`$cmd`;
$? == 0 || print "13\n";
-f 'path/another/third/mbox' || print "14\n";
-f "$user" || print "15\n";

`rm -rf path` if -d 'path';
unlink <emerg/*>;
unlink "$mbox", "$user", 'mail', 'ok';
print "0\n";
