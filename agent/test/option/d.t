# -d: dump filter rules (special)

# $Id: d.t,v 3.0 1993/11/29 13:50:15 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: d.t,v $
# Revision 3.0  1993/11/29  13:50:15  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
unlink '.rules';
# With no rule file, verify it dumps the default rules
$output = `$mailagent -d`;
$? == 0 || print "1\n";
@log = split(/\n/, $output);	# want to use check_log()
&check_log('# Rule 1', 2);
&check_log('PROCESS', 3);
# With an empty rule file, we must also have the default rules
open(RULES, ">.rules");
close RULES;
$output_bis = `$mailagent -d`;
$? == 0 || print "4\n";
$output_bis eq $output || print "5\n";
# Now check with some rules
`cp ../rules .rules`;
$output = `$mailagent -d`;
$? == 0 || print "6\n";
@log = split(/\n/, $output);	# want to use check_log()
&check_log('# Rule 1', 7);
&check_log('DELETE', 8);
print "0\n";
