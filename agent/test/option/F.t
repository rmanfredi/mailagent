# -F : force processing on seen mail

# $Id: F.t,v 3.0.1.1 1994/01/26 09:36:08 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: F.t,v $
# Revision 3.0.1.1  1994/01/26  09:36:08  ram
# patch5: created
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out';
$user = $ENV{'USER'};	# Don't want to include ../pl/filter.pl
unlink 'folder', 'again', $user;

system "$mailagent -e '{SAVE ~/folder}' -f ../mail >/dev/null 2>&1";
$? == 0 || print "1\n";
-f $user && print "2\n";
($old_size = -s 'folder') || print "3\n";
&get_log(4, 'folder');
&check_log('^X-Filter:', 5) == 1 || print "6\n";

system "$mailagent -e '{SAVE ~/folder}' -f ./folder >/dev/null 2>&1";
$? == 0 || print "7\n";
-f $user || print "8\n";
($old_size == -s 'folder') || print "9\n";
($old_size == -s $user) || print "10\n";
&get_log(11, $user);
&check_log('^X-Filter:', 12) == 1 || print "13\n";

# Now here comes the -F check, now that we know everything works fine
unlink $user;
system "$mailagent -F -e '{SAVE ~/again}' -f ./folder >/dev/null 2>&1";
$? == 0 || print "14\n";
-f $user && print "15\n";
-s 'again' || print "16\n";
&get_log(17, 'again');
&check_log('^X-Filter:', 18) == 1 || print "19\n";

print "0\n";
