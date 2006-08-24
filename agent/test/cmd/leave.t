# Test LEAVE command

# $Id: leave.t,v 3.0.1.1 1994/07/01 15:07:21 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: leave.t,v $
# Revision 3.0.1.1  1994/07/01  15:07:21  ram
# patch8: added tests for new fromall config option
#
# Revision 3.0  1993/11/29  13:49:33  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';		# Need &add_option also

&add_header('X-Tag: leave');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" || print "2\n";		# Mail saved here by default

# When mailbox protected against writing...
unlink <emerg/*>;
$size = -s "$user";
chmod 0444, "$user";
`$cmd`;
$? == 0 || print "3\n";
-f "$user" || print "4\n";				# Must still be there
$size == -s "$user" || print "5\n";		# And not altered
@emerg = <emerg/*>;
@emerg == 1 || print "6\n";				# Emeregency as LEAVE failed

# There is no X-Filter mail in the emergency saving
`grep -v X-Filter: $user > ok`;
$? == 0 || print "7\n";
-s $emerg[0] eq -s 'ok' || print "8\n";	# Full mail saved, of course

# Make sure From within body is escaped if preceded by blank line
&add_header("\nFrom mailagent");		# In effect adds an EOH
&add_body(<<'NEW');
The following introduces a leading
From line NOT preceded by a blank line

From my point of view,
the preceding should be escaped.
NEW
unlink "$user";
`$cmd`;
$? == 0 || print "9\n";
-f "$user" || print "10\n";				# Must still be there
&get_log(11, $user);
&check_log('^>From', 12) == 2 || print "13\n";
&check_log('^From line', 14) == 1 || print "15\n";

# Make sure all From lines are escaped when fromall is activated.
&add_option('-o fromall:ON');
unlink "$user";
`$cmd`;
$? == 0 || print "16\n";
-f "$user" || print "17\n";
&get_log(18, $user);
&check_log('^>From', 19) == 3 || print "20\n";
&not_log('^From line', 21);

unlink <emerg/*>;
unlink "$user", 'mail', 'ok';
print "0\n";
