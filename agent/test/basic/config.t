# This MUST be the first test ever run

# $Id: config.t,v 3.0.1.8 1999/01/13 18:16:19 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: config.t,v $
# Revision 3.0.1.8  1999/01/13  18:16:19  ram
# patch64: test for non-writable agent.wait file
#
# Revision 3.0.1.7  1997/02/20  11:48:11  ram
# patch55: avoid exec-safe checks and group-writable directories
#
# Revision 3.0.1.6  1997/01/07  18:36:24  ram
# patch52: force execsafe to OFF when running tests
#
# Revision 3.0.1.5  1996/12/24  15:01:24  ram
# patch45: added locksafe, set to OFF
#
# Revision 3.0.1.4  1995/01/25  15:31:46  ram
# patch27: now sets a default umask in the configuration
#
# Revision 3.0.1.3  1995/01/03  18:20:00  ram
# patch24: temporary directory is now local, don't clobber /tmp
#
# Revision 3.0.1.2  1994/09/22  14:40:52  ram
# patch12: added callout queue file definition
#
# Revision 3.0.1.1  1994/04/25  15:24:33  ram
# patch7: added commented 'fromesc' new variable
#
# Revision 3.0  1993/11/29  13:49:23  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/init.pl';
do '../pl/logfile.pl';
chdir '../out' || exit 0;
chop($pwd = `pwd`);
$path = $ENV{'PATH'};
$host = $ENV{'HOST'};
$host =~ s/-/_/g;		# Filter translates '-' into '_' in hostnames
$user = $ENV{'USER'};
open(CONFIG, ">.mailagent") || print "1\n";
print CONFIG <<EOF;
home     : $pwd
level    : 21			# Undocumented of course
umask    : 022
tmpdir   : $home/tmp
emergdir : $pwd/emerg
track    : OFF
path     : .
p_$host  : .
user     : $user
name     : Mailagent Test Suite
vacation : OFF
vacfile  : ~/.vacation
vacperiod: 1d
spool    : ~
queue    : ~/queue		# This is a good test for comments
logdir   : ~
context  : \$spool/context
callout  : \$spool/callout
log      : agentlog
seq      : .seq
timezone : PST8PDT
statfile : \$spool/mailagent.st
rules    : ~/.rules
rulecache: ~/.cache
maildrop : $pwd			# Do not LEAVE messages in /usr/spool/mail
mailbox  : \$user		# Use config variable, not current perl $user
#fromesc : ON			# Backward compatibility -- should be ON when absent
locksafe : OFF			# Don't bother with failed locks (for fsn <= 14 chars)
hash     : dbr
cleanlaps: 1M
autoclean: OFF
agemax   : 1y
comfile  : \$spool/commands
distlist : \$spool/distribs
proglist : \$spool/proglist
maxsize  : 150000
plsave   : \$spool/plsave
authfile : \$spool/auth
secure   : ON
execsafe : OFF			# Don't be too paranoid while running tests
execskip : ON			# Skip all exec()-related sanity checks
groupsafe: OFF			# Don't bother with writable group checks
sendmail : msend
sendnews : nsend
EOF
close CONFIG;
`rm -rf queue emerg tmp`;
`mkdir emerg tmp`;
`cp /dev/null agent.wait; chmod u-w agent.wait`;
$? == 0 || print "2\n";
# Use the special undocumented -t option from filter to get HOME directory
# via environment instead of /etc/passwd.
open(FILTER, "|$filter -t >/dev/null 2>&1") || print "3\n";
print FILTER <<EOF;
Dummy mail
EOF
close FILTER;
$? != 0 || print "4\n";			# No valid queue directory
$file = <emerg/*>;
if (-f "$file") {
	open(FILE, $file) || print "5\n";
	@file = <FILE>;
	close FILE;
	$file[0] eq "Dummy mail\n" || print "6\n";
	unlink "$file";
} else {
	print "5\n";				# No emergency dump
}
-s 'agentlog' || print "6\n";	# No logfile or empty
&get_log(7);
&check_log('FATAL', 8);				# There must be a FATAL
&check_log('MTA', 9);				# Filter must think mail is in MTA's queue
&check_log('updating PATH', 10);	# Make sure hostname is computed
&check_log('unable to queue', 11);	# Filter did not queue mail
unlink 'agentlog';
`mkdir queue`;
`chmod u+w agent.wait`;
$? == 0 || print "12\n";		# Cannot make queue
print "0\n";
