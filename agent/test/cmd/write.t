# The WRITE command

# $Id: write.t,v 3.0 1993/11/29 13:49:55 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: write.t,v $
# Revision 3.0  1993/11/29  13:49:55  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';
$mbox = 'mbox';

&add_header('X-Tag: write #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$mbox" || print "2\n";		# Mail saved here
-f "$user" && print "3\n";		# Must not exist (yet)

# When mailbox protected against writing...
unlink <emerg/*>;
$size = -s "$mbox";
chmod 0444, "$mbox";
`$cmd`;
$? == 0 || print "4\n";
-f "$mbox" || print "5\n";				# Must still be there
$size == -s "$mbox" || print "6\n";		# And not altered
@emerg = <emerg/*>;
@emerg == 1 || print "7\n";				# Emeregency as SAVE failed
-f "$user" || print "8\n";				# Not saved -> leave in mbox
-s "$user" == -s "$mbox" || print "9\n";

# There is no X-Filter mail in the emergency saving
`grep -v X-Filter: $mbox > ok`;
$? == 0 || print "10\n";
-s $emerg[0] eq -s 'ok' || print "11\n";	# Full mail saved, of course

# Now verify WRITE actually overwrites the contentes
unlink "$user";
chmod 0644, "$mbox";
`$cmd`;
$? == 0 || print "12\n";
$size == -s "$mbox" || print "13\n";
-f "$user" && print "14\n";

# Make sure WRITE creates full path when needed
&replace_header('X-Tag: write #2');
`rm -rf path` if -d 'path';
`$cmd`;
$? == 0 || print "15\n";
-f 'path/another/third/mbox' || print "16\n";
`rm -rf path` if -d 'path';

unlink <emerg/*>;
unlink "$mbox", "$user", 'mail', 'ok';
print "0\n";
