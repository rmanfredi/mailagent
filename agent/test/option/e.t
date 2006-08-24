# -e : enter rules to be applied

# $Id: e.t,v 3.0 1993/11/29 13:50:15 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: e.t,v $
# Revision 3.0  1993/11/29  13:50:15  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
$output = `$mailagent -e '{ OWN_RULE_1 };' -e '{OWN_RULE_2 };' -d`;
$? == 0 || print "1\n";
@log = split(/\n/, $output);	# want to use check_log()
&check_log('OWN_RULE_1', 2);
&check_log('OWN_RULE_2', 3);
# Single rule may not be specified between {}
$output = `$mailagent -e 'SINGLE' -d`;
$? == 0 || print "4\n";
$output_bis = `$mailagent -e '{ SINGLE }' -d`;
$? == 0 || print "5\n";
$output eq $output_bis || print "6\n";
$output = `$mailagent -e 'SINGLE' -e '{ OTHER }' -d`;
$? == 0 || print "7\n";
$output_bis = `$mailagent -e '{ SINGLE };' -e '{ OTHER }' -d`;
$? == 0 || print "8\n";
$output ne $output_bis || print "9\n";
@log = split(/\n/, $output);
grep(/# Rule 2/, @log) && print "10\n";			# Only one rule
grep(/Subject: SINGLE/, @log) || print "11\n";	# No selector -> Subject
@log = split(/\n/, $output_bis);
grep(/# Rule 2/, @log) || print "12\n";			# Two rules
grep(/Subject: \*/, @log) || print "13\n";		# No pattern -> *
print "0\n";
