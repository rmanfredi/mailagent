case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting agent/magent (with variable substitutions)"
$spitshell >magent <<!GROK!THIS!
$startperl
	eval 'exec perl -S \$0 "\$@"'
		if \$running_under_some_shell;

# You'll need to set up a .forward file that feeds your mail to this script,
# via the filter. Mine looks like this:
#   "|exec /users/ram/mail/filter >>/users/ram/.bak 2>&1"

# $Id: magent.sh,v 3.0.1.17 2001/03/17 18:07:49 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: magent.sh,v $
# Revision 3.0.1.17  2001/03/17 18:07:49  ram
# patch72: mydomain and hiddennet now superseded by config vars
# patch72: changed email_addr() and domain_addr() to honour new config vars
#
# Revision 3.0.1.16  1999/01/13  18:08:48  ram
# patch64: changed agent_wait to AGENT_WAIT, now holding full path
#
# Revision 3.0.1.15  1997/09/15  15:05:06  ram
# patch57: call new pmail() routine to process main message
# patch57: fixed typo in -r usage
#
# Revision 3.0.1.14  1997/02/20  11:39:31  ram
# patch55: used $* variable for no purpose
#
# Revision 3.0.1.13  1996/12/24  14:06:02  ram
# patch45: rule file path is now absolute, so caching can be safe
# patch45: changed queue processing/sleeping logic for better interactivity
# patch45: new stat constants, and updated usage line
#
# Revision 3.0.1.12  1995/09/15  13:54:28  ram
# patch43: rewrote mbox_lock routine to deal with new locksafe variable
# patch43: will now warn if configured to do flock() but can't actually
# patch43: can now be configured to do safe or allow partial mbox locking
#
# Revision 3.0.1.11  1995/08/31  16:26:54  ram
# patch42: forced numeric value when reading the Length header
#
# Revision 3.0.1.10  1995/08/07  16:12:03  ram
# patch37: now remove mailagent's lock as soon as possible before exiting
# patch37: added support for locking on filesystems with short filenames
#
# Revision 3.0.1.9  1995/03/21  12:54:50  ram
# patch35: added pl/cdir.pl to the list of appended files
#
# Revision 3.0.1.8  1995/02/16  14:24:42  ram
# patch32: new -I option for installation setup and checking
# patch32: usage message now sorts options by case type
#
# Revision 3.0.1.7  1995/02/03  17:57:16  ram
# patch30: also select hot piping on stderr to avoid problems on fork
#
# Revision 3.0.1.6  1995/01/03  17:56:52  ram
# patch24: new library files pl/rulenv.pl and pl/options.pl included
# patch24: no longer uses pl/umask.pl
#
# Revision 3.0.1.5  1994/10/29  17:40:14  ram
# patch20: added built-in biffing support
#
# Revision 3.0.1.4  1994/10/04  17:34:14  ram
# patch17: no longer report errors when orgname file is missing
# patch17: mailbox locking now uses customized mboxlock parameter
#
# Revision 3.0.1.3  1994/09/22  13:52:34  ram
# patch12: now performs &init_constants as soon as possible
# patch12: changed interface for &queue_mail to include first 2 letters
# patch12: context is loaded earlier to initialize callout queue
# patch12: added definition for $MAX_LINKS, $S_IWOTH, $S_IWGRP and &abs
# patch12: changed &email_addr to cache its result and not rely on $cf'user
# patch12: moved &init_signals to pl/signals.pl as &catch_signals
#
# Revision 3.0.1.2  1994/07/01  14:54:29  ram
# patch8: fixed leading From date format (spacing problem)
#
# Revision 3.0.1.1  1994/01/26  09:27:56  ram
# patch5: new -F option to force procesing on filtered messages
#
# Revision 3.0  1993/11/29  13:48:22  ram
# Baseline for mailagent 3.0 netwide release.
#

# Perload ON

#
# The following were determined by Configure...
#

# Command used to compute hostname
\$phostname = '$phostname';

# Our domain name
\$mydomain = '$mydomain';

# Hidden network (advertised host)
\$hiddennet = '$hiddennet';

# Directory where mail is spooled
\$maildir = '$maildir';

# File in which mail is stored
\$mailfile = '$mailfile';

# Current version number and patchlevel
\$mversion = '$VERSION';
\$patchlevel = '$PATCHLEVEL';

# Want to lock mailboxes with flock ?
\$lock_by_flock = '$lock_by_flock';

# Only use flock() and no .lock file
\$flock_only = '$flock_only';

# Our organization name
\$orgname = '$orgname';

# Private mailagent library
\$privlib = '$privlib';

# News posting program
\$inews = '$inews';

# Mail sending program
\$mailer = '$mailer';

# Can we have filenames longer than 14 characters?
\$long_filenames = '$d_flexfnam' eq 'define';

#
# End of configuration section.
#
!GROK!THIS!

$spitshell >>magent <<'!NO!SUBS!'

$prog_name = $0;				# Who I am
$prog_name =~ s|^.*/(.*)|$1|;	# Keep only base name
$has_option = 0;				# True if invoked with options
$nolock = 0;					# Do we need to get a lock file?
$config_file = '~/.mailagent';	# Default configuration file
$log_level = -1;				# Changed by -L option

# Calling the mailagent as 'mailqueue' lists the queue
if ($prog_name eq 'mailqueue') {
	unshift(@ARGV, '-l');
}

# Parse options
while ($ARGV[0] =~ /^-/) {
	$_ = shift;
	last if /--/;
	if ($_ eq '-c') {		# Specify alternate configuration file
		++$nolock;			# Immediate processing wanted
		$config_file = shift;
	}
	elsif ($_ eq '-d') {	# Dump rules
		++$has_option;		# Incompatible with other special options
		++$dump_rule;
	}
	elsif ($_ eq '-e') {	# Rule supplied on command line
		$_ = shift;
		s/\n/ /g;
		push(@Linerules, $_);
		++$edited_rules;	# Signals rules came from command line
		++$nolock;			# Immediate processing wanted
	}
	elsif ($_ eq '-f') {	# Take messages from UNIX mailbox
		++$nolock;			# Immediate processing wanted
		++$mbox_mail;
		$mbox_file = shift;	# -f followed by file name
	}
	elsif ($_ eq '-h') {	# Usage help
		&usage;
	}
	elsif ($_ eq '-i') {	# Interactive mode: log messages also on stderr
		*add_log = *stderr_log;
	}
	elsif ($_ eq '-l') {	# List queue
		++$has_option;		# Incompatible with other special options
		++$list_queue;
		++$norule;			# No need to compile rules
	}
	elsif ($_ eq '-o') {	# Overwrite configuration variable
		++$nolock;			# Immediate processing wanted
		$over_config .= "\n" . shift;
	}
	elsif ($_ eq '-q') {	# Process the queue
		++$has_option;		# Incompatible with other special options
		++$run_queue;
	}
	elsif ($_ eq '-r') {	# Specify alternate rule file
		++$nolock;			# Immediate processing wanted
		$rule_file = shift;
		$rule_file = &cdir($rule_file);		# Make it an absolute path
	}
	elsif (/^-s(\S*)/) {	# Print statistics
		++$has_option;		# Incompatible with other special options
		++$stats;
		++$norule;			# No need to compile rules
		$stats_opt = $1;
	}
	elsif ($_ eq '-t') {	# Track rule matches on stdout
		++$track_all;
	}
	elsif ($_ eq '-F') {	# Force processing, even if already seen
		++$force_seen;
	}
	elsif ($_ eq '-I') {	# Install a suitable mailagent environment...
		++$has_option;		# That option must be the only one specified
		++$install_me;
	}
	elsif ($_ eq '-L') {	# Specify new logging level
		$log_level = int(shift);
	}
	elsif ($_ eq '-V') {	# Version number
		print STDERR "$prog_name $mversion PL$patchlevel\n";
		exit 0;
	}
	elsif ($_ eq '-U') {	# Do not allow UNIQUE to reject / abort
		++$disable_unique;
	}
	elsif ($_ eq '-TEST') {	# Mailagent run via TEST (undocumented feature)
		++$test_mode;
	}
	else {
		print STDERR "$prog_name: unknown option: $_\n";
		&usage;
	}
}

++$nolock if $has_option;		# No need to take a lock with special options

# Only one option at a time (among those options which change our goal)
if ($has_option > 1) {
	print STDERR "$prog_name: at most one special option may be specified.\n";
	exit 1;
}

exit(&cf'setup) if $install_me;	# Get a suitable configuration if -I

$file_name = shift;				# File name to be processed (null if stdin)
$ENV{'IFS'}='' if $ENV{'IFS'};	# Shell separation field
&init_constants;				# Constants definitions
&get_configuration;				# Get a suitable configuration package (cf)
&patch_constants;				# Change some constants after config
select(STDERR); $| = 1;			# In case we get perl warnings...
select(STDOUT);					# and because the -t option writes on STDOUT,
$| = 1;							# make sure it is flushed before we fork().
$privlib = "$cf'home/../.." if $test_mode;	# Tests ran from test/out
$AGENT_WAIT = "$cf'spool/agent.wait";		# Waiting file for mails

$orgname = &tilda_expand($orgname);		# Perform run-time ~name substitution

if ($orgname =~ m|^/|) {		# Name of organization kept in file
	unless (open(ORG, $orgname)) {
		&add_log("ERROR cannot read $orgname: $!") if $loglvl && -f $orgname;
	} else {
		chop($orgname = <ORG>);
		close ORG;
	}
}

$ENV{'HOME'} = $cf'home;
$ENV{'USER'} = $cf'user;
$ENV{'NAME'} = $cf'name;
$baselock = "$cf'spool/perl";	# This file does not exist
$lockext = $long_filenames ? '.lock' : '!';	# Extension used by lock routines
$lockfile = $baselock . $lockext;

umask(077);						# Files we create are private ones
$jobnum = &jobnum;				# Compute a job number

# Allow only ONE mailagent at a time (resource consumming)
&checklock($baselock);			# Make sure old locks do not remain
unless (-f $lockfile) {
	# Try to get the lock file (acting as a token). We do not need locking if
	# we have been invoked with an option and that option is not -q.
	if ($nolock && !$run_queue) {
		&add_log("no need to get a lock") if $loglvl > 19;
	} elsif (0 == &acs_rqst($baselock)) {
		&add_log("got the right to process mail") if $loglvl > 19;
		++$locked;
	} else {
		&add_log("denied right to process mail") if $loglvl > 19;
	}
}

if (!$locked && !$nolock) {
	# Another mailagent is running somewhere
	&queue_mail($file_name, 'fm');
	exit 0;
}

# Initialize mail filtering and compile filter rule if necessary
&init_all;
&compile_rules unless $norule;
&context'init;		# Load context, initialize callout queue

# If rules are to be dumped, this is the only action
if ($dump_rule) {
	&dump_rules(*print_rule_number, *void_func);
	unlink $lockfile if $locked;
	exit 0;
}

# Likewise, statistics dumping is the only option
if ($stats) {
	&report_stats($stats_opt);
	unlink $lockfile if $locked;
	exit 0;
}

# Listing the queue is also the only performed action
if ($list_queue) {
	&list_queue;
	unlink $lockfile if $locked;
	exit 0;
}

# Taking messages from mailbox file
if ($mbox_mail) {
	++$run_queue if 0 == &mbox_mail($mbox_file);
	unless ($run_queue) {
		unlink $lockfile if $locked;
		exit 1;		# -f failed
	}
	&add_log("processing queued mails") if $loglvl > 15;
}

# Suppress statistics when mailagent invoked manually (i.e. not in test mode)
&no_stats if $nolock && !$test_mode;

&read_stats;					# Load statistics into memory for fast update
&newcmd'load if $cf'newcmd;		# Load user-defined command definitions

#
# If -q is not specfied, we need to process the file which was given to us
# on the command line. We're calling pmail() to process it via locking,
# but unfortunately we can't allow pmail() to unlink the processed file,
# because it might be something the user wants to keep around...
# However, if we were invoked by the filter program, the processed mail
# will be unlinked later on. The trouble is the file was unlocked and
# there is a slight time window were the message could be processed again by
# another mailagent. If the 'queuehold' variable is reasonably set, such a
# message will be skipped anyway, so it's not that critical.
#

if (!$run_queue) {				# Do not enter here if -q
	if (0 != &pmail($file_name, 0)) {
		&add_log("ERROR while processing main message--queing it") if $loglvl;
		&queue_mail($file_name, 'fm');
		unlink $lockfile;
		exit 0;					# Do not continue
	} 
}

unless ($test_mode) {
	# Fork a child: we have to take care of the filter script which is waiting
	# for us to finish processing of the delivered mail.
	&fork_child() unless $run_queue;

	# From now on, we are in the child process... Don't sleep at all if logging
	# level is greater that 11 or if $run_queue is true. Logging level of 12
	# and higher are for debugging and should not be used on a permanent basis
	# anyway.

	$sleep = 1;					# Give others a chance to queue their mail
	$sleep = 0 if $loglvl > 11 || $run_queue;

	do {						# Eventually process the queue
		sleep 30 if $sleep;		# Wait in case new mail arrives
	} while (&pqueue);
} else {
	&pqueue;					# Process the queue once in test mode
}

# Mailagent is exiting. Remove lock file as early as possible to avoid a
# race condition: another mailagent could start up and decide another one
# is already processing mail, but since we're about to exit...
unlink $lockfile if $locked;
&add_log("mailagent exits") if $loglvl > 17;

# End of mailagent processing
&write_stats;					# Resynchronizes the statistics file
&compress'recompress;			# Compress some of the folders we delivered to
&contextual_operations;			# Perform all the contextual operations
exit 0;

# Print usage and exit
sub usage {
	print STDERR <<EOF;
Usage: $prog_name [-dhilqtFIVU] [-s{umaryt}] [-f file] [-e rules] [-c config]
       [-L level] [-r file] [-o def] [mailfile]
  -c : specify alternate configuration file.
  -d : dump filter rules (special).
  -e : enter rules to be applied.
  -f : get messages from UNIX-style mailbox file.
  -h : print this help message and exits.
  -i : interactive usage -- print log messages on stderr.
  -l : list message queue (special).
  -o : overwrite config file with supplied definition.
  -q : process the queue (special).
  -r : specify alternate rule file.
  -s : report gathered statistics (special).
  -t : track rules on stdout.
  -F : force processing on already filtered messages.
  -I : install configuration and perform sanity checks.
  -L : force logging level.
  -V : print version number and exits.
  -U : prevent UNIQUE from rejecting an already processed Message-ID.
EOF
	exit 1;
}

# Read configuration file and alter it with the values specified via -o.
# Then apply -r and -t by modifying suitable configuration parameters.
sub get_configuration {
	&read_config($config_file);		# Read configuration file and set vars
	&cf'parse($over_config);		# Overwrite with command line options
	$cf'rules = $rule_file if $rule_file;		# -r overwrites rule file
	$loglvl = $log_level if $log_level >= 0;	# -L overwrites logging level
}

#
# The filtering routines
#

# Start-up initializations
sub init_all {
	&catch_signals;		# Trap common signals
	&init_interpreter;	# Initialize tables %Priority, %Function, ...
	&init_env;			# Initialize the %XENV array
	&init_matcher;		# Initialize special matching functions
	&init_pseudokey;	# Initialize the pseudo header keys for H table
	&init_builtins;		# Initialize built-in commands like @RR
	&init_filter;		# Initialize filter commands
	&init_special;		# Initialize special user table %Special
}

# Constants definitions
sub init_constants {
	require 'ctime.pl';
	# Values for flock(), usually in <sys/file.h>
	$LOCK_SH = 1;				# Request a shared lock on file
	$LOCK_EX = 2;				# Request an exclusive lock
	$LOCK_NB = 4;				# Make a non-blocking lock request
	$LOCK_UN = 8;				# Unlock the file

	# Stat constants for file rights
	$S_IWOTH = 00002;			# Writable by world (no .ph files here)
	$S_IWGRP = 00020;			# Writable by group
	$S_ISUID = 04000;			# Set user ID on exec
	$S_ISGID = 02000;			# Set group ID on exec

	# Status used by filter
	$FT_RESTART = 0;			# Abort current action, restart from scratch
	$FT_CONT = 1;				# Continue execution
	$FT_REJECT = 2;				# Abort current action, continue filtering
	$FT_ABORT = 3;				# Abort filtering process

	# Shall we append or remove folder?
	$FOLDER_APPEND = 0;			# Append in folder
	$FOLDER_REMOVE = 1;			# Remove folder

	# Used by shell_command and children
	$NO_INPUT = 0;				# No input (stdin is closed)
	$BODY_INPUT = 1;			# Give body of mail as stdin
	$MAIL_INPUT = 2;			# Pipe the whole mail
	$HEADER_INPUT = 3;			# Pipe the header only
	$NO_FEEDBACK = 0;			# No feedback wanted
	$FEEDBACK = 1;				# Feed result of command back into %Header
	
	# The filter message
	local($address) = &email_addr;
	$FILTER =
		"X-Filter: mailagent [version $mversion PL$patchlevel] for $address";
	$MAILER =
		"X-Mailer: mailagent [version $mversion PL$patchlevel]";

	# For header fields alteration
	$HD_STRIP = 0;				# Strip header fields
	$HD_KEEP = 1;				# Keep header fields

	# Faked leading From line (used for digest items, by SPLIT)
	local($now) = &ctime(time);
	$now =~ s/\s(\d:\d\d:\d\d)\b/0$1/;	# Add leading 0 if hour < 10
	chop($now);
	$FAKE_FROM = "From mailagent " . $now;

	# Miscellaneous constants
	$MAX_LINKS = 100;			# Maximum number of symbolic link levels
}

# Change some constants after configuration file was parsed
sub patch_constants {
	local($address) = &email_addr;	# Will prefer cf vars to hardwired ones
	$FILTER =
		"X-Filter: mailagent [version $mversion PL$patchlevel] for $address";
}

# Initializes environment. All the variables are initialized in XENV array
# The sole purpose of XENV is to be able to know what changes wrt the invoking
# environment when dumping the rules. It also avoid modifying the environment
# for our children.
sub init_env {
	foreach (keys(%ENV)) {
		$XENV{$_} = $ENV{$_};
	}
}

# List of special header keys which do not represent a true header field.
sub init_pseudokey {
	%Pseudokey = (
		'Body', 1,
		'Head', 1,
		'All', 1
	);
}

#
# Miscellaneous utilities
#

# Attempts a mailbox locking. The argument is the name of the file, the file
# descriptor is the global MBOX, opened for appending.
# Returns true if the lock was obtained, false if the lock could not be
# obtained but we wish to continue anyway, and undef if the lock was not
# obtained and locksafe is ON (i.e. the user does not wish to risk a delivery
# with no locking).
# If locksafe is set to PARTIAL, we only wish a lock to protect against
# another concurrent mailagent delivery, so any partial lock is ok (e.g. an
# flock() lock was obtained, but no .lock).
sub mbox_lock {
	local($file) = @_;				# File name
	local($locked) = 0;				# Did we get at least one lock?
	local($error) = 0;				# Assume no error
	local($lastlock) = '';			# Last lock we successfully grabbed

	# Initial .lock locking (optionally reconfigured via mboxlock)
	# Done only when not configured to perform flock()-style locks.

	unless ($flock_only) {			# Lock with .lock
		if (0 != &acs_rqst($file, $cf'mboxlock)) {
			&add_log("WARNING could not lock $file") if $loglvl > 5;
			$error++;
		} else {
			$locked++;
			$lastlock = 'mbox .lock';
		}
	}

	# Make sure the file is still there and as not been removed while we were
	# waiting for the lock (in which case our MBOX file descriptor would be
	# useless: we would write in a ghost file!). This could happen when 'elm'
	# (or other mail user agent) resynchronizes the mailbox.

	close MBOX;
	unless (open(MBOX, ">>$file")) {
		&fatal("could not reopen $file");
	}

	# Perform flock()-style locking if configured to do so.

	if ($lock_by_flock) {
		local($ok) = 0;
		eval { $ok = flock(MBOX, $LOCK_EX) };	# flock() may be missing!
		if ($@ ne '' && $flock_only) {
			&add_log("WARNING flock() not available for locking")
				if $loglvl > 5;
			$error++;
		} elsif ($ok) {
			$locked++;
			$lastlock = 'flock';
		} else {
			&add_log("WARNING could not flock $file: $!") if $loglvl > 5;
			$error++;
		}
	}

	&add_log("WARNING was unable to get any lock on $file")
		if !$locked && $loglvl > 5;

	&add_log("NOTICE got an \"$lastlock\"-style lock on $file")
		if $error && $locked && $cf'locksafe !~ /^ON/i && $loglvl > 6;

	seek(MBOX, 0, 2);			# Someone may have appended something

	if ($cf'locksafe =~ /^ON/i && $error) {
		&mbox_unlock;
		return undef;			# No lock grabbed, can't deliver to folder
	} elsif ($cf'locksafe =~ /^PARTIAL/i) {
		return 1 if $locked;	# We got a partial locking, allow delivery
		return undef;			# No lock, can't deliver to that mbox
	} elsif ($error) {
		return 0;				# False but defined, meaning we may deliver!
	}

	return 1;	# Ok, we did lock that mailbox and we may deliver to it
}

# Remove lock on mailbox and return a failure status if closing failed
sub mbox_unlock {
	local($file) = @_;				# File name
	local($status);					# Error status from close
	$status = close(MBOX);			# Closing will remove flock lock
	&free_file($file, $cf'mboxlock) unless $flock_only;	# Remove the lock
	$status ? 0 : 1;				# Return 0 for ok, 1 if close failed
}

# Computes the e-mail address of the user
# Can't rely on the value of $cf'user since config file may not have
# been parsed when this routine is first called. This routine is also used
# to set a default value for $cf'email.
# Once $cf'email exists however, its value is used.
sub email_addr {
	if (defined $cf'email) {
		my $mail = $cf'email;
		$mail .= '@' . &domain_addr unless $mail =~ /@/;
		return $mail;
	}
	return $email_addr_cached if defined $email_addr_cached;
	local($user);
	($user) = getpwuid($>);
	($user) = getpwuid($<) unless $user;
	$user = 'nobody' unless $user;
	$email_addr_cached = $user . '@' . &domain_addr;
	return $email_addr_cached;	# E-mail address in internet format
}

# Domain name address for current host
# Use $cf'domain and $cf'hidenet when available.
sub domain_addr {
	local($_);							# Our host name
	if (defined $cf'domain) {
		$_ = $cf'domain;
		if (lc($cf'hidenet) ne "on" || $_ eq '') {
			$_ = &hostname;
			$_ .= ".$cf::domain" unless /\./;
		}
	} else {
		$_ = $hiddennet if $hiddennet ne '';
		if ($_ eq '') {
			$_ = &hostname;					# Must fork to get hostname, grr...
			$_ .= $mydomain unless /\./;	# We want something fully qualified
		}
	}
	$_;
}

# Strip out leading path to home directory and replace it by a ~
sub tilda {
	local($path) = @_;					# Path we wish to shorten
	local($home) = $cf'home;
	$home =~ s/(\W)/\\$1/g;				# Escape possible meta-characters
	$path =~ s/^$home/~/;				# Replace the home directory by ~
	$path;								# Return possibly stripped path
}

# Compute absolute value -- on one line to avoid dataloading
sub abs { $_[0] > 0 ? $_[0] : -$_[0]; }

# Compute the system mailbox file name
sub mailbox_name {
	# If ~/.mailagent provides us with a mail directory, use it and possibly
	# override value computed by Configure.
	$maildir = $cf'maildrop if $cf'maildrop ne '';
	# If Configure gave a valid 'maildir', use it. Otherwise compute one now.
	unless ($maildir ne '' && -d "$maildir") {
		$maildir = "/usr/spool/mail";		# Default spooling area
		-d "/usr/mail" && ($maildir = "/usr/mail");
		-d "$maildir" || ($maildir = "$cf'home");
	}
	local($mbox) = $cf'user;					# Default mailbox file name
	$mbox = $cf'mailbox if $cf'mailbox ne '';	# Priority to config variable
	$mailbox = "$maildir/$mbox";				# Full mailbox path
	if (! -f "$mailbox" && ! -w "$maildir") {
		# No mailbox already exists and we can't write in the spool directory.
		# Use mailfile then, and if we can't write in the directory and the
		# mail file does not exist either, use ~/mbox.$cf'user as mailbox.
		$mailbox = $mailfile;		# Determined by configure (%~ and %L form)
		$mailbox =~ s/%~/$cf'home/go;	# %~ stands for the user directory
		$mailbox =~ s/%L/$cf'user/go;	# %L stands for the user login name
		$mailbox =~ m|(.*)/.*|;			# Extract dirname
		$mailbox = "$cf'home/mbox.$cf'user" unless (-f "mailbox" || -w "$1");
		&add_log("WARNING using $mailbox for mailbox") if $loglvl > 5;
	}
	$mailbox;
}

# Fork a new mailagent and update the pid in the perl.lock file. The parent
# then exits and the child continues. This enables the filter which invoked
# us to finally exit.
sub fork_child {
	local($pid) = fork;
	if ($pid == -1) {				# We cannot fork, exit.
		&add_log("ERROR couldn't fork to process the queue") if $loglvl > 5;
		unlink $lockfile if $locked;
		exit 0;
	} elsif ($pid == 0) {			# The child process
		# Update the pid in the perl.lock file, so that any process which will
		# use the kill(pid, 0) feature to check whether we are alive or not will
		# get a meaningful status.
		if ($locked) {
			chmod 0644, $lockfile;
			open(LOCK, ">$lockfile");	# Ignore errors
			chmod 0444, $lockfile;		# Now it's open, so we may restore mode
			print LOCK "$$\n";			# Write child's PID
			close LOCK;
		}
		sleep(2);					# Give filter time to clean up
	} else {						# Parent process
		exit 0;						# Exit without removing lock, of course
	}
	# Only the child comes here and returns
	&add_log("mailagent continues") if $loglvl > 17;
}

# Report any eval error and returns 1 if error detected.
sub eval_error {
	if ($@ ne '') {
		$@ =~ s/ in file \(eval\) at line \d+//;
		chop($@);
		&add_log("ERROR $@") if $loglvl > 1;
	}
	$@ eq '' ? 0 : 1;
}

!NO!SUBS!
$grep -v '^;#' pl/jobnum.pl >>magent
$grep -v '^;#' pl/read_conf.pl >>magent
$grep -v '^;#' pl/acs_rqst.pl >>magent
$grep -v '^;#' pl/free_file.pl >>magent
$grep -v '^;#' pl/add_log.pl >>magent
$grep -v '^;#' pl/checklock.pl >>magent
$grep -v '^;#' pl/lexical.pl >>magent
$grep -v '^;#' pl/parse.pl >>magent
$grep -v '^;#' pl/analyze.pl >>magent
$grep -v '^;#' pl/runcmd.pl >>magent
$grep -v '^;#' pl/filter.pl >>magent
$grep -v '^;#' pl/matching.pl >>magent
$grep -v '^;#' pl/locate.pl >>magent
$grep -v '^;#' pl/rfc822.pl >>magent
$grep -v '^;#' pl/macros.pl >>magent
$grep -v '^;#' pl/header.pl >>magent
$grep -v '^;#' pl/actions.pl >>magent
$grep -v '^;#' pl/stats.pl >>magent
$grep -v '^;#' pl/queue_mail.pl >>magent
$grep -v '^;#' pl/pqueue.pl >>magent
$grep -v '^;#' pl/builtins.pl >>magent
$grep -v '^;#' pl/rules.pl >>magent
$grep -v '^;#' pl/period.pl >>magent
$grep -v '^;#' pl/eval.pl >>magent
$grep -v '^;#' pl/dbr.pl >>magent
$grep -v '^;#' pl/history.pl >>magent
$grep -v '^;#' pl/once.pl >>magent
$grep -v '^;#' pl/makedir.pl >>magent
$grep -v '^;#' pl/emergency.pl >>magent
$grep -v '^;#' pl/listqueue.pl >>magent
$grep -v '^;#' pl/mbox.pl >>magent
$grep -v '^;#' pl/context.pl >>magent
$grep -v '^;#' pl/extern.pl >>magent
$grep -v '^;#' pl/mailhook.pl >>magent
$grep -v '^;#' pl/interface.pl >>magent
$grep -v '^;#' pl/getdate.pl >>magent
$grep -v '^;#' pl/include.pl >>magent
$grep -v '^;#' pl/plural.pl >>magent
$grep -v '^;#' pl/hostname.pl >>magent
$grep -v '^;#' pl/mmdf.pl >>magent
$grep -v '^;#' pl/compress.pl >>magent
$grep -v '^;#' pl/newcmd.pl >>magent
$grep -v '^;#' pl/q.pl >>magent
$grep -v '^;#' pl/hook.pl >>magent
$grep -v '^;#' pl/secure.pl >>magent
$grep -v '^;#' pl/cdir.pl >>magent
$grep -v '^;#' pl/cmdserv.pl >>magent
$grep -v '^;#' pl/power.pl >>magent
$grep -v '^;#' pl/file_edit.pl >>magent
$grep -v '^;#' pl/dynload.pl >>magent
$grep -v '^;#' pl/gensym.pl >>magent
$grep -v '^;#' pl/usrmac.pl >>magent
$grep -v '^;#' pl/tilde.pl >>magent
$grep -v '^;#' pl/mh.pl >>magent
$grep -v '^;#' pl/signals.pl >>magent
$grep -v '^;#' pl/callout.pl >>magent
$grep -v '^;#' pl/addr.pl >>magent
$grep -v '^;#' pl/utmp/utmp.pl >>magent
$grep -v '^;#' pl/biff.pl >>magent
$grep -v '^;#' pl/rulenv.pl >>magent
$grep -v '^;#' pl/options.pl >>magent
$grep -v '^;#' pl/install.pl >>magent
chmod 755 magent
$eunicefix magent
