# The SAVE command

# $Id: save.t,v 3.0.1.2 1995/03/21 12:59:28 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: save.t,v $
# Revision 3.0.1.2  1995/03/21  12:59:28  ram
# patch35: fixed rename() syntax for perl 4.0
#
# Revision 3.0.1.1  1995/02/16  14:38:56  ram
# patch32: added checks for new fromfake config variable
#
# Revision 3.0  1993/11/29  13:49:48  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';		# Need &add_option also
$mbox = 'mbox';

&add_header('X-Tag: save #1');
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
unlink "$mbox", "$user";

# Make sure SAVE creates full path when needed
&replace_header('X-Tag: save #2');
`rm -rf path` if -d 'path';
`$cmd`;
$? == 0 || print "12\n";
-f 'path/another/third/mbox' || print "13\n";

`rm -rf path` if -d 'path';
unlink <emerg/*>;
unlink 'ok';

# Ensure fromfake works as advertised, i.e. that it creates a valid From:
# header when it is missing.
`grep -v '^From: ' mail >mail2`;
$? == 0 || print "14\n";
rename('mail2', 'mail');
&replace_header('X-Tag: save #3');
`$cmd`;
$? == 0 || print "15\n";
-f 'ok' || print "16\n";
$size = -s 'ok';

&add_option('-o fromfake: OFF');
`$cmd`;
$? == 0 || print "17\n";
&get_log(18, 'ok');
&check_log('^From: ', 19) == 1 || print "20\n";

unlink "$mbox", "$user", 'mail', 'ok';
print "0\n";
