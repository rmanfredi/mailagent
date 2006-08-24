;# $Id$
;#
;#  Copyright (c) 1990-2006, Raphael Manfredi
;#  
;#  You may redistribute only under the terms of the Artistic License,
;#  as specified in the README file that comes with the distribution.
;#  You may reuse parts of this distribution only within the terms of
;#  that same Artistic License; a copy of which may be found at the root
;#  of the source tree for mailagent 3.0.
;#
;# $Log: cmdserv.pl,v $
;# Revision 3.0.1.7  1999/07/12  13:50:49  ram
;# patch66: factorized servshell handling in function
;#
;# Revision 3.0.1.6  1998/07/28  17:02:15  ram
;# patch62: shell used is now customized by the "servshell" variable
;#
;# Revision 3.0.1.5  1998/03/31  15:20:35  ram
;# patch59: changed "set" to dump variables when not given any argument
;#
;# Revision 3.0.1.4  1997/02/20  11:43:12  ram
;# patch55: made 'perl -cw' clean
;#
;# Revision 3.0.1.3  1996/12/24  14:50:16  ram
;# patch45: all power-sensitive actions can now be logged separately
;# patch45: launch sendmail only when session is done to avoid timeouts
;# patch45: perform security checks on all server commands
;#
;# Revision 3.0.1.2  1995/08/07  16:18:26  ram
;# patch37: fixed symbol table lookups for perl5 support
;#
;# Revision 3.0.1.1  1994/10/04  17:49:52  ram
;# patch17: now uses the email config parameter to send messages to user
;# patch17: ensures envelope is not an hostile address before processing
;# patch17: the process routine now returns a failure/success condition
;#
;# Revision 3.0  1993/11/29  13:48:37  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# The command server is configured by a 'command' file, which lists the
;# available commands, their type and their locations. The command file has
;# the following format:
;#
;#   <cmd_name> <type> <hide> <collect> <path> <extra>
;#
;#  - cmd_name: the name of the command recognized by the server.
;#  - type: the type of command: shell, perl, var, flag, help or end.
;#  - hide: argument to hide in transcript (password usually).
;#  - collect: whether the command collects data following in mail message. Set
;#    to '-' means no, otherwise 'yes' means collecting is needed.
;#  - path: the location of the executable for shell commands (may be left out
;#    by specifying '-', in which case the command will be searched for in the
;#    path), the file where the command is implemented for perl commands, and
;#    the directory where help files are located for help, one file per command.
;#  - extra: either some options for shell commands or the name of the function
;#    within the perl file.
;#
;# Each command has an environment set up (part of the process environment for
;# shell commands, part of perl cmdenv package for other commands processed
;# by perl). This basic environment consists of:
;#  - jobnum: the job number of the current mailagent.
;#  - cmd: the command line as written in the message.
;#  - name: the command name.
;#  - log: what was logged in transcript (some args possibly concealed)
;#  - pack: packing mode for file sending.
;#  - path: destination for the command (where to send file / notification).
;#  - auth: set to true if valid envelope found (can "authenticate" sender).
;#  - uid: address of the sender of the message (where to send transcript).
;#  - user: user's e-mail, equivalent to UNIX euid here (initially uid).
;#  - trace: true when command trace wanted in transcript (shell commands).
;#  - powers: a colon separated list of privileges the user has.
;#  - errors: number of errors so far
;#  - requests: number of requests processed so far
;#  - eof: the end of file for collection mode
;#  - collect: true when collecting a file
;#  - disabled: a list of commands disabled (comma separated)
;#  - trusted: true when server in trust mode (where powers may be gainned)
;#  - debug: true in debug mode
;#  - approve: approve password for 'approve' commands, empty if no approve
;#
;# All convenience variables normally defined for the PERL command are also
;# made part of the command environment.
;#
;# For perl commands, collected data is available in the @buffer environment.
;# Shell commands can see those collected data by reading stdin.
;#
;# TODO:
;# Commands may be batched for later processing, in the batch queue. Each job
;# is recorded in a 'cm' file, the environment of the command itself is written
;# at the top, ending with a blank line and followed by the actual command to
;# be exectuted (i.e. the internal representation of 'cmd').
;#
#
# Command server
#

package cmdserv;

$loaded = 0;			# Set to true when loading done

# Initialize builtin server commands
sub init {
	%Builtin = (					# Builtins and their implemetation routine
		'addauth',	'run_addauth',	# Append to power clearance file
		'approve',	'run_approve',	# Record password for forthcoming command
		'delpower',	'run_delpower',	# Delete power from system
		'getauth',	'run_getauth',	# Get power clearance file
		'newpower',	'run_newpower',	# Add a new power to the system
		'passwd',	'run_passwd',	# Change power password, alternate syntax
		'password',	'run_password',	# Set new password for power
		'power',	'run_power',	# Ask for new power
		'powers',	'run_powers',	# A list of powers, along with clearances
		'release',	'run_release',	# Abandon power
		'remauth',	'run_remauth',	# Remove people from clearance file
		'set',		'run_set',		# Set internal variables
		'setauth',	'run_setauth',	# Set power clearance file
		'user',		'run_user',		# Commands on behalf of new user
	);
	%Conceal = (					# Words to be hidden in transcript
		'power',	'2',			# Protect power password
		'password',	'2',			# Second argument is password
		'passwd',	'2,3',			# Both old and new passwords are concealed
		'newpower',	'2',			# Power password
		'delpower',	'2,3',			# Power password and security
		'getauth',	'2',			# Power password if no system clearance
		'setauth',	'2',			# Power password
		'addauth',	'2',			# Power password
		'remauth',	'2',			# Power passowrd
		'approve',	'1',			# Approve passoword
	);
	%Collect = (					# Commands collecting more data from mail
		'newpower',	1,				# Takes list of allowed addresses
		'setauth',	1,				# Takes new list of allowed addresses
		'addauth',	1,				# Allowed addresses to be added
		'remauth',	1,				# List of addresses to be deleted
	);
	%Set = (						# Internal variables which may be set
		'debug',	'flag',			# Debugging mode
		'eof',		'var',			# End of file marker (default is EOF)
		'pack',		'var',			# Packing mode for file sending
		'path',		'var',			# Destination address for file sending
		'trace',	'flag',			# The trace flag
	);
}

# Load command file into memory, setting %Command, %Type, %Path and %Extra
# arrays, all indexed by a command name.
sub load {
	$loaded = 1;					# Do not come here more than once
	&init;							# Initialize builtins
	return unless -s $cf'comserver;	# Empty or non-existent file
	return unless &'file_secure($cf'comserver, 'server command');
	unless (open(COMMAND, $cf'comserver)) {
		&'add_log("ERROR cannot open $cf'comserver: $!") if $'loglvl;
		&'add_log("WARNING server commands not loaded") if $'loglvl > 5;
		return;
	}

	local($_);
	local($cmd, $type, $hide, $collect, $path, @extra);
	local(%known_type) = (
		'perl',		1,				# Perl script loaded dynamically
		'shell',	1,				# Program to run via fork/exec
		'help',		1,				# Help, send back files from dir
		'end',		1,				# End processing of requests
		'flag',		1,				# A variable flag
		'var',		1,				# An ascii variable
	);
	local(%set_type) = (
		'flag',		1,				# Denotes a flag variable
		'var',		1,				# Denotes an ascii variable
	);

	while (<COMMAND>) {
		next if /^\s*#/;			# Skip comments
		next if /^\s*$/;			# Skip blank lines
		($cmd, $type, $hide, $collect, $path, @extra) = split(' ');
		$path =~ s/~/$cf'home/;		# Perform ~ substitution

		# Perl commands whose function name is not defined will bear the same
		# name as the command itself. If no path was specified, use the value
		# of the servdir configuration parameter from ~/.mailagent and assume
		# each command is stored in a cmd or cmd.pl file. Same for shell
		# commands, expected in a cmd or cmd.sh file. However, if the shell
		# command is not found there, it will be located at run-time using the
		# PATH variable.
		@extra = ($cmd) if $type eq 'perl' && @extra == 0;
		if ($type eq 'perl' || $type eq 'shell') {
			if ($path eq '-') {
				$path = "$cf'servdir/$cmd";
				$path = "$cf'servdir/$cmd.pl" if $type eq 'perl' && !-e $path;
				$path = "$cf'servdir/$cmd.sh" if $type eq 'shell' && !-e $path;
				$path = '-' if $type eq 'shell' && !-e $path;
			} elsif ($path !~ m|^/|) {
				$path = "$cf'servdir/$path";
			}
		}

		# If path is specified, make sure it is valid
		if ($path ne '-' && !(-e $path && (-r _ || -x _))) {
			local($home) = $cf'home;
			$home =~ s/(\W)/\\$1/g;		# Escape possible metacharacters (+)
			$path =~ s/^$home/~/;
			&'add_log("ERROR command '$cmd' bound to invalid path $path")
				if $'loglvl > 1;
			next;					# Ignore invalid command
		}

		# Verify command type
		unless ($known_type{$type}) {
			&'add_log("ERROR command '$cmd' has unknown type $type")
				if $'loglvl > 1;
			next;					# Skip to next command
		}

		# If command is a variable, record it in the %Set array. Since all
		# variables are proceseed separately from commands, it is perfectly
		# legal to have both a command and a variable bearing the same name.
		if ($set_type{$type}) {
			$Set{$cmd} = $type;		# Record variable as being of given type
			next;
		}

		# Load command into internal data structures
		$Command{$cmd}++;			# Record known command
		$Type{$cmd} = $type;
		$Path{$cmd} = $path;
		$Extra{$cmd} = join(' ', @extra);
		$Conceal{$cmd} = $hide if $hide ne '-';
		$Collect{$cmd}++ if $collect =~ /^y/i;
	}
	close COMMAND;
}

# Process server commands held in the body, either by batching them or by
# executing them right away. A transcript is sent to the sender.
# Requires a previous call to 'setuid'.
sub process {
	local(*body) = @_;				# Mail body
	local($_);						# Current line processed
	local($metoo);					# Send blind carbon copy to me too?

	&load unless $loaded;			# Load commands unless already done
	$cmdenv'jobnum = $'jobnum;		# Propagate job number
	$metoo = $cf'email if $cf'scriptcc =~ /^on/i;

	# Make sure sender address is not hostile
	unless (&addr'valid($cmdenv'uid)) {
		&add_log("ERROR $cmdenv'uid is an hostile sender address")
			if $'loglvl > 1;
		return 1;	# Failed, will discard whole mail message then
	}

	# Set up a mailer pipe to send the transcript back to the sender
	#
	# We used to do a simple:
	#	open(MAILER, "|$cf'sendmail $cf'mailopt $cmdenv'uid $metoo")
	# here but this had a nasty side effect with smart mailers: a
	# lengthy command could cause a timeout, breaking the pipe and leading
	# to a failure.
	#
	# Intead, we just create a temporary file somewhere, and immediately
	# unlink it. Keeping the fd preciously lets us manipulate this temporary
	# file with the insurance that it will not leave any trace should we
	# fail abruptly.

	unless (open(MAILER, "+>$cf'tmpdir/serv.mail$$")) {
		&'add_log("ERROR cannot create temporary mail transcript: $!")
			if $'loglvl > 1;
	}

	# We may fork and have to close one end of the MAILER pipe, so make sure
	# no unflushed data ever remain...
	select((select(MAILER), $| = 1)[0]);

	# Build up initial header. Be sure to add a junk precedence, since we do
	# not want to get any bounces.
	# For some reason, perl 4.0 PL36 fails with the here document construct
	# when using dataloading.
	print MAILER
"To: $cmdenv'uid
Subject: Mailagent session transcript
Precedence: junk
$main'MAILER

    ---- Mailagent session transcript for $cmdenv'uid ----
";

	# Start message processing. Stop as soon as an ending command is reached,
	# or when more than 'maxerrors' errors have been detected. Also stop
	# processing when a signature is reached (introduced by '--').

	foreach (@body) {
		if ($cmdenv'collect) {			# Collecting data for command
			if ($_ eq $cmdenv'eof) {	# Reached end of "file"
				$cmdenv'collect = 0;	# Stop collection
				&execute;				# Execute command
				undef @cmdenv'buffer;	# Free memory
			} else {
				push(@cmdenv'buffer, $_);
			}
			next;
		}
		if ($cmdenv'errors > $cf'maxerrors && !&root) {
			&finish('too many errors');
			last;
		}
		if ($cmdenv'requests > $cf'maxcmds && !&root) {
			&finish('too many requests');
			last;
		}
		next if /^\s*$/;			# Skip blank lines
		print MAILER "\n";			# Separate each command
		s/^\s*//;					# Strip leading spaces
		&cmdenv'set_cmd($_);		# Set command environment
		$cmdenv'approve = '';		# Clear approve password
		&user_prompt;				# Copy line to transcript
		if (/^--\s*$/) {			# Signature reached
			&finish('.signature');
			last;
		}
		if ($Disabled{$cmdenv'name}) {		# Skip disabled commands
			$cmdenv'errors++;
			print MAILER "Disabled command.\n";
			print MAILER "FAILED.\n";
			&'add_log("DISABLED $cmdenv'log") if $'loglvl > 1;
			next;
		}
		unless (defined $Builtin{$cmdenv'name}) {
			unless (defined $Command{$cmdenv'name}) {
				$cmdenv'errors++;
				print MAILER "Unknown command.\n";
				print MAILER "FAILED.\n";
				&'add_log("UNKNOWN $cmdenv'log") if $'loglvl > 1;
				next;
			}
			if ($Type{$cmdenv'name} eq 'end') {	# Ending request?
				&finish("user's request");		# Yes, end processing then
				last;
			}
		}
		if (defined $Collect{$cmdenv'name}) {
			$cmdenv'collect = 1;		# Start collect mode
			next;						# Grab things in @cmdenv'buffer
		}
		&execute;				# Execute command, report in transcript
	}

	# If we are still in collecting mode, then the EOF marker was not found
	if ($cmdenv'collect) {
		&'add_log("ERROR did not reach eof mark '$cmdenv'eof'")
			if $'loglvl > 1;
		&'add_log("FAILED $cmdenv'log") if $'loglvl > 1;
		print MAILER "Could not find eof marker '$cmdenv'eof'.\n";
		print MAILER "FAILED.\n";
	}

	print MAILER <<EOM;

    ---- End of mailagent session transcript ----
EOM

	# We used to simply close MAILER at this point, but it is now a fd on
	# a temporary file. We're going to rewind in and copy it onto the SENDMAIL
	# real mailer descriptor.

	unless (open(SENDMAIL, "|$cf'sendmail $cf'mailopt $cmdenv'uid $metoo")) {
		&'add_log("ERROR cannot start $cf'sendmail to mail transcript: $!")
			if $'loglvl > 1;
		unless (open(SENDMAIL, ">> $cf'emergdir/serv-msg.$$")) {
			&'add_log("ERROR can't even dump into $cf'emergdir/serv-msg.$$: $!")
				if $'loglvl > 1;
			# Last chance, print on STDOUT
			open(SENDMAIL, '>&STDOUT');
			&'add_log("NOTICE dumping server transcript on stdout")
				if $'loglvl > 6;
			print STDOUT "*** dumping server transcript: ***\n";
		}
	}

	unless (seek(MAILER, 0, 0)) {
		&'add_log("ERROR cannot seek back to start of transcript: $!")
			if $'loglvl > 1;
	}

	local($l);
	while (defined ($l = <MAILER>)) {
		print SENDMAIL $l;
	}
	close MAILER;			# Bye bye temporary file

	unless (close SENDMAIL) {
		&'add_log("ERROR cannot mail transcript to $cmdenv'uid")
			if $'loglvl > 1;
	}
	0;	# Success
}

#
# Command execution
#

# Execute command recorded in the cmdenv environment. For each type of command,
# the routine 'exec_type' is called and returns 0 if ok. Builtins are dealt
# separately by calling the corresponding perl function.
sub execute {
	$cmdenv'requests++;				# One more request
	local($log) = $cmdenv'log;		# Save log, since it could be modified
	local($failed) = &dispatch;		# Dispatch command
	if ($failed) {
		&'add_log("FAILED $log") if $'loglvl > 1;
		$cmdenv'errors++;
		print MAILER "FAILED.\n";
	} else {
		&'add_log("OK $log") if $'loglvl > 2;
		print MAILER "OK.\n";
	}
}

# Dispatch command held in $cmdenv'name and return failure status (0 means ok).
sub dispatch {
	local($failed) = 0;
	&'add_log("XEQ ($cmdenv'name) as $cmdenv'user") if $'loglvl > 10;
	if (defined $Builtin{$cmdenv'name}) {	# Deal separately with builtins
		eval "\$failed = &$Builtin{$cmdenv'name}";	# Call builtin function
		if (chop($@)) {
			print MAILER "Perl failure: $@\n";
			$@ .= "\n";		# Restore final char for &'eval_error call
			&'eval_error;	# Log error
			$@ = '';		# Clear evel error condition
			$failed++;		# Make sure failure is recorded
		}
	} else {
		# Command may be unknwon if called from 'user <email> command' or
		# from an 'approve <password> comamnd' type of invocation.
		if (defined $Type{$cmdenv'name}) {
			eval "\$failed = &exec_$Type{$cmdenv'name}";
		} else {
			print MAILER "Unknown command.\n";
			$cmdenv'errors++;
			$failed++;
		}
	}
	$failed;		# Report failure status
}

# Shell command
sub exec_shell {
	# Check for unsecure characters in shell command
	if ($cmdenv'cmd =~ /([=\$^&*([{}`\\|;><?])/ && !&root) {
		$cmdenv'errors++;
		print MAILER "Unsecure character '$1' in command line.\n";
		return 1;		# Failed
	}

	# Initialize input script (if command operates in 'collect' mode)
	local($error) = 0;		# Error flag
	local($input) = '';		# Input file, when collecting
	if (defined $Collect{$cmdenv'name}) {
		$input = "$cf'tmpdir/input.cmd$$";
		unless (open(INPUT, ">$input")) {
			&'add_log("ERROR cannot create $input: $!") if $'loglvl;
			$error++;
		} else {
			foreach $collected (@cmdenv'buffer) {
				(print INPUT $collected, "\n") || $error++;
				&'add_log("SYSERR write: $!") if $error && $'loglvl;
				last if $error;
			}
			close(INPUT) || $error++;
			&'add_log("SYSERR close: $!") if $error == 1 && $'loglvl;
		}
		if ($error) {
			print MAILER "Cannot create input file ($!).\n";
			&'add_log("ERROR cannot initialize input file") if $'loglvl;
			unlink $input;
			return 1;		# Failed
		}
	}

	# Ensure the command we're about to execute is secure
	local(@argv) = split(' ', $cmdenv'cmd);
	$argv[0] = $Path{$cmdenv'name} if defined $Path{$cmdenv'name};
	local($cmd) = &'locate_program($argv[0]);
	unless ($cmd =~ m|/|) {
		&'add_log("ERROR cannot locate $cmd") if $'loglvl;
		unlink $input if $input;
		print MAILER "Unable to locate command.\n";
		return 1;			# Failed
	}
	unless (&'exec_secure($cmd, 'server command')) {
		&'add_log("ERROR unsecure command $cmd") if $'loglvl;
		unlink $input if $input;
		print MAILER "Unable to locate command.\n";	# Don't tell them the truth!
		return 1;			# Failed
	}

	# Create shell command file, whose purpose is to set up the environment
	# properly and do the appropriate file descriptors manipulations, which
	# is easier to do at the shell level, and cannot fully be done in perl 4.0
	# (see dup2 hack below).
	$cmdfile = "$cf'tmpdir/mess.cmd$$";
	unless (open(CMD, ">$cmdfile")) {
		&'add_log("ERROR cannot create $cmdfile: $!") if $'loglvl;
		print MAILER "Cannot create file comamnd file ($!).\n";
		unlink $input if $input;
		return 1;		# Failed
	}

	# Initialize command environment
	local($key, $val);		# Key/value from perl's symbol table
	local($value);
	# Loop over perl's symbol table for the cmdenv package
	eval "*_cmdenv = *::cmdenv::" if $] > 5;	# Perl 5 support
	while (($key, $val) = each %_cmdenv) {
		local(*entry) = $val;		# Get definitaions of current slot
		&'add_log("considering variable $key") if $'loglvl > 15;
		next unless defined $entry;	# No variable slot
		next if $key !~ /^[a-z]\w+$/i;		# Skip invalid names for shell
		($value = $entry) =~ s/'/'"'"'/g;	# Keep simple quotes
		(print CMD "$key='$value' export $key\n") || $error++;
		&'add_log("env set $key='$value'") if $'loglvl > 15;
	}
	# Now add command invocation and input redirection. Standard input will be
	# the collect buffer, if any, and file descriptor #3 is a path to the
	# session transcript.
	local($redirect);
	local($extra) = $Extra{$cmdenv'name};
	$redirect = "<$input" if $input;
	(print CMD "cd $cf'home\n") || $error++;	# Make sure we start from home
	(print CMD "exec 3>&2 2>&1\n") || $error++;	# See dup2 hack below
	(print CMD "$argv[0] $extra @argv[1..$#argv] $redirect\n") || $error++;
	close(CMD) || $error++;
	close CMD;
	if ($error) {
		&'add_log("ERROR cannot initialize $cmdfile: $!") if $'loglvl;
		unlink $cmdfile;
		unlink $input if $input;
		print MAILER "Cannot initialize command file ($!).\n";
		return 1;			# Failed
	}

	&include($cmdfile, 'command', '<<< ') if $cmdenv'debug;

	# Set up trace file
	$trace = "$cf'tmpdir/trace.cmd$$";
	unless (open(TRACE, ">$trace")) {
		&'add_log("ERROR cannot create $trace: $!") if $'loglvl;
		unlink $cmdfile;
		unlink $input if $input;
		print MAILER "Cannot create trace file ($!).\n";
		return 1;			# Failed
	}

	# Now fork a child which will redirect stdout and stderr onto the trace
	# file and exec the command file.

	local($pid) = fork;			# We fork here
	unless (defined $pid) {		# Apparently, we could not fork...
		&'add_log("SYSERR fork: $!") if $'loglvl;
		close TRACE;
		unlink $cmdfile, $trace;
		unlink $input if $input;
		print MAILER "Cannot fork ($!).\n";
		return 1;			# Failed
	}

	# Child process runs the command
	if ($pid == 0) {				# Child process
		# Perform a dup2(MAILER, 3) to allow file descriptor #3 to be a way
		# for the shell script to reach the session transcript. Since perl
		# insists on closing all file descriptors >2 ($^F) during the exec, we
		# remap the current STDERR to MAILER temporarily. That way, it will
		# be transmitted to the child, which is a shell script doing an
		# 'exec 3>&2 2>&1', meaning the file #3 is the original MAILER and
		# stdout and stderr for the script go to the same trace file, as
		# intiallly attached to stdout.
		#
		open(STDOUT, '>&TRACE');	# Redirect stdout to the trace file
		open(STDERR, '>&MAILER');	# Temporarily mapped to the MAILER file
		close(STDIN);				# Make sure there is no input

		# For HPUX-10.x, grrr... have to use /bin/ksh otherwise that silly
		# posix shell closes all the file descriptors greater than 2, defeating
		# all our cute setting here...

		local($shell) = &servshell;

		# Using a sub-block ensures exec() is followed by nothing
		# and makes mailagent "perl -cw" clean, whatever that means ;-)
		{ exec "$shell $cmdfile" }	# Don't let perl use sh -c

		&'add_log("SYSERR exec: $!") if $'loglvl;
		&'add_log("ERROR cannot exec $shell $cmdfile") if $'loglvl;
		print MAILER "Cannot exec command file ($!).\n";
		exit(9);
	}

	close TRACE;		# Only child uses it
	wait;				# Wait for child
	unlink $cmdfile;	# Has been used and abused...
	unlink $input if $input;

	if ($?) {			# Child exited with non-zero status
		local($status) = $? >> 8;
		&'add_log("ERROR child exited with status $status") if $'loglvl > 1;
		print MAILER "Command returned a non-zero status ($status).\n";
		$error = 1;
	}
	&include($trace, 'trace', '<<< ') if $error || $cmdenv'trace;
	unlink $trace;
	$error;				# Failure status
}

# Perl command
sub exec_perl {
	local($name) = $cmdenv'name;		# Command name
	local($fn) = $Extra{$name};			# Perl function to execute
	$fn = $name unless $fn;				# If none specified, use command name
	unless (&dynload'load('cmdenv', $Path{$name}, $fn)) {
		&'add_log("ERROR cannot load script for command $name") if $'loglvl;
		print MAILER "Cannot load $name command.\n";
		return 1;		# Failed
	}
	# Place in the cmdenv package context and call the function, propagating
	# the error status (1 for failure). Arguments are pre-split on space,
	# simply for convenience, but the command is free to parse the 'cmd'
	# variable itself.
	package cmdenv;
	local(*MAILER) = *cmdserv'MAILER;	# Propagate file descriptor
	local($fn) = $cmdserv'fn;			# Propagate function name
	local(@argv) = split(' ', $cmd);
	shift(@argv);						# Remove command name
	local($res) = eval('&$fn(@argv)');	# Call function, get status
	if (chop $@) {
		&'add_log("ERROR in perl $name: $@") if $'loglvl;
		print MAILER "Perl error: $@\n";
		$res = 1;
	}
	$res;		# Propagate error status
}

# Help command. Start by looking in the user's help directory, then in
# the public mailagent help directory. Users may disable help for a
# command by making an empty file in their own help dir.
sub exec_help {
	local(@topic) = split(' ', $cmdenv'cmd);
	local($topic) = $topic[1];	# Help topic wanted
	local($help);				# Help file
	unless ($topic) {			# General builin help
		# Doesn't work with a here document form... (perl 4.0 PL36)
		print MAILER
"Following is a list of the known commands. Some additional help is available
on a command basis by using 'help <command>', unless the command name is
followed by a '*' character in which case no further help may be obtained.
Commands collecting input until an EOF mark are flagged with a trailing '='.

";
		local(@cmds);			# List of known commands
		local($star);			# Does command have a help file?
		local($plus);			# Does command require additional input?
		local($online) = 0;		# Number of commands currently printed on line
		local($print);			# String printed for each command
		local($fieldlen) = 18;	# Amount of space dedicated to each command
		push(@cmds, keys(%Builtin), keys(%Command));
		foreach $cmd (sort @cmds) {
			$help = "$cf'helpdir/$cmd";
			$help = "$'privlib/help/$cmd" unless -e $help;
			$star = -s $help ? '' : '*';
			$plus = defined($Collect{$cmd}) ? '=' : '';
			# We print 4 commands on a single line
			$print = $cmd . $plus . $star;
			print MAILER $print, ' ' x ($fieldlen - length($print));
			if ($online++ == 3) {
				$online = 0;
				print MAILER "\n";
			}
		}
		print MAILER "\n" if $online;	# Pending line not completed yet
		print MAILER "\nEnd of command list.\n";
		return 0;	# Ok
	}
	$help = "$cf'helpdir/$topic";
	$help = "$'privlib/help/$cmd" unless -e $help;
	unless (-s $help) {
		print MAILER "Help for '$topic' is not available.\n";
		return 0;	# Not a failure
	}
	&include($help, "$topic help", '');	# Include file and propagate status
}

#
# Builtins
#

# Approve command in advance by specifying a password. The syntax is:
#    approve <password> [command]
# and the password is simply recorded in the command environment. Then parsing
# of the command is resumed.
# NOTE: cannot approve a command which collects input (yet).
sub run_approve {
	local($x, $password, @command) = split(' ', $cmdenv'cmd);
	$cmdenv'approve = $password;			# Save approve password
	&cmdenv'set_cmd(join(' ', @command));	# Set command environment
	&dispatch;			# Execute command and propagate status
}

# Ask for new power. The syntax is:
#    power <name> <password>
# Normally, 'root' does not need to request for any other powers, less give
# any password. However, for simplicity and uniformity, we simply grant it
# with no checks.
sub run_power {
	local($x, $name, $password) = split(' ', $cmdenv'cmd);
	if (!$cmdenv'trusted) {		# Server has to be running in trusted mode
		&power'add_log("WARNING cannot gain power '$name': not in trusted mode")
			if $'loglvl > 5;
	} elsif (&root || &power'grant($name, $password, $cmdenv'uid)) {
		&power'add_log("granted power '$name' to $cmdenv'uid") if $'loglvl > 2;
		&cmdenv'addpower($name);
		return 0;		# Ok
	}
	print MAILER "Permission denied.\n";
	1;		# Failed
}

# Release power. The syntax is:
#    release <name>
# If the 'root' power is released, other powers obtained while root or before
# are kept. That way, it makes sense to ask for powers as root when the
# password for some power has been changed. It is wise to release a power once
# it is not needed anymore, since it may prevent mistakes.
sub run_release {
	local($x, $name) = split(' ', $cmdenv'cmd);
	&cmdenv'rempower($name);
	0;		# Always ok
}

# List all powers with their clearances. The syntax is:
#    powers <regexp>
# and the 'system' power is needed to get the list. The root power or security
# power is needed to get the root or security information. If no arguments are
# specified, all the non-privileged powers (if you do not have root or security
# clearance) are listed. If arguments are given, they are taken as regular
# expression filters (perl way).
sub run_powers {
	local($x, @regexp) = split(' ', $cmdenv'cmd);
	unless (&cmdenv'haspower('system') || &cmdenv'haspower('security')) {
		print MAILER "Permission denied.\n";
		return 1;
	}
	unless (open(PASSWD, $cf'passwd)) {
		&power'add_log("ERROR cannot open password file $cf'passwd: $!")
			if $'loglvl;
		print MAILER "Cannot open password file ($!).\n";
		return 1;
	}
	print MAILER "List of currently defined powers:\n";
	local($_);
	local($power);			# Current power analyzed
	local($matched);		# Did power match the regular expression?
	while (<PASSWD>) {
		($power) = split(/:/);
		# If any of the following regular expressions is incorrect, a die will
		# be generated and caught by the enclosing eval.
		$matched = @regexp ? 0 : 1;
		foreach $regexp (@regexp) {
			eval '$power =~ /$regexp/ && ++$matched;';
			if (chop($@)) {
				print MAILER "Perl failure: $@\n";
				$@ = '';
				close PASSWD;
				return 1;
			}
			last if $matched;
		}
		next unless $matched;
		print MAILER "\nPower: $power\n";
		if (
			($power eq 'root' || $power eq 'security') &&
			!&cmdenv'haspower($power)
		) {
			print MAILER "(Cannot list clearance file: permission denied.)\n";
			next;
		}
		&include(&power'authfile($power), "$power clearance");
	}
	close PASSWD;
	0;
}

# Set new power password. The syntax is:
#    password <name> <new>
# To change a power password, you need to get the corresponding power or be
# system, hence showing you know the password for that power or have greater
# privileges. To change the 'root' and 'security' passwords, you need the
# corresponding security clearance.
sub run_password {
	local($x, $name, $new) = split(' ', $cmdenv'cmd);
	local($required) = $name;
	$required = 'system' unless &cmdenv'haspower($name);
	$required = $name if $name eq 'root' || $name eq 'security';
	unless (&cmdenv'haspower($required)) {
		print MAILER "Permission denied (not enough power).\n";
		&power'add_log("ERROR $cmdenv'uid tried a password change for '$name'")
			if $'loglvl > 1;
		return 1;
	}
	return &change_password($name, $new);
}

# Set new power password. The syntax is:
#    passwd <name> <old> <new>
# You do not need to have the corresponding power to change the password since
# the old password is requested. This is a short for the sequence:
#    power <name> <old>
#    password <name> <new>
#    release <name>
# excepted that even root has to give the correct old password if this form
# is used.
sub run_passwd {
	local($x, $name, $old, $new) = split(' ', $cmdenv'cmd);
	unless (&power'authorized($name, $cmdenv'uid)) {
		&power'add_log("ERROR $cmdenv'uid tried a password change for '$name'")
			if $'loglvl > 1;
		print MAILER "Permission denied (lacks authorization).\n";
		return 1;
	}
	unless (&power'valid($name, $old)) {
		&power'add_log("ERROR $cmdenv'uid gave wrong old password for '$name'")
			if $'loglvl > 1;
		print MAILER "Permission denied (invalid pasword).\n";
		return 1;
	}
	return &change_password($name, $new);
}

# Change password for power 'name' to be $new.
# All security checks have been performed at this point, so we may indeed
# attempt the change. Note that this subroutine is common for the two
# passwd and password commands.
# Returns 0 if OK, 1 on error.
sub change_password {
	local($name, $new) = @_;
	if (0 == &power'set_passwd($name, $new)) {
		&power'add_log("user $cmdenv'uid changed password for power '$name'")
			if $'loglvl > 2;
		return 0;
	}
	&power'add_log("ERROR user $cmdenv'uid failed change password for '$name'")
		if $'loglvl > 1;
	print MAILER "Could not change password, sorry.\n";
	1;
}

# Change user ID, i.e. e-mail address. The syntax is:
#    user [<email> [command]]
# and is used to execute some commands on behalf of another user. If a command
# is specified, it is immediately executed with the new identity, which only
# lasts for that time. Otherwise, the remaining commands are executed with that
# new ID. If no email is specified, the original sender ID is restored.
# All the powers are lost when a user command is executed, but this is only
# temporary when the command is specified on the same line.
sub run_user {
	local($x, $user, @command) = split(' ', $cmdenv'cmd);
	local(%powers);
	local($powers);
	if (0 == @command && $cmdenv'powers ne '') {
		print MAILER "Wiping out current powers ($cmdenv'powers).\n";
		&cmdenv'wipe_powers;
	}
	if (0 != @command && $cmdenv'powers ne '') {
		%powers = %cmdenv'powers;
		$powers = $cmdenv'powers;
		print MAILER "Current powers temporarily lost ($cmdenv'powers).\n";
		&cmdenv'wipe_powers;
	}
	unless ($user) {			# Reverting to original sender ID
		$cmdenv'user = $cmdenv'uid;
		print MAILER "Back to original identity ($cmdenv'uid).\n";
		return 0;
	}
	if (0 == @command) {
		$cmdenv'user = $user;
		print MAILER "New user identity: $cmdenv'user.\n";
		return 0;
	}

	&cmdenv'set_cmd(join(' ', @command));	# Set command environment
	local($failed) = &dispatch;				# Execute command

	if (defined %powers) {
		$cmdenv'powers = $powers;
		%cmdenv'powers = %powers;
		print MAILER "Restored powers ($powers).\n";
	}

	$failed;		# Propagate failure status
}

# Add a new power to the system. The syntax is:
#    newpower <name> <password> [alias]
# followed by a list of approved names who may request that power. The 'system'
# power is required to add a new power. An alias should be specified if the
# name is longer than 12 characters. The 'security' power is required to create
# the root power, and root power is needed to create 'security'.
sub run_newpower {
	local($x, $name, $password, $alias) = split(' ', $cmdenv'cmd);
	if (
		($name eq 'root' && !&cmdenv'haspower('security')) ||
		($name eq 'security' && !&cmdenv'haspower('root')) ||
		!&cmdenv'haspower('system')
	) {
		print MAILER "Permission denied.\n";
		return 1;
	}
	&newpower($name, $password, $alias);
}

# Actually add the new power to the system, WITHOUT any security checks. It
# is up to the called to ensure the user has correct permissions. Return 0
# if ok and 1 on error.
# The clearance list is taken from @cmdenv'buffer.
sub newpower {
	local($name, $password, $alias) = @_;
	local($power) = &power'getpwent($name);
	if (defined $power) {
		print MAILER "Power '$name' already exists.\n";
		return 1;
	}
	if (length($name) > 12 && !defined($alias)) {
		# Compute a suitable alias name, which never appears externally anyway
		# so it's not really important to use cryptic ones. First, reduce the
		# power name to 10 characters.
		$alias = $name;
		$alias =~ tr/aeiouy//d;
		$alias = substr($alias, 0, 6) . substr($alias, -6);
		if (&power'used_alias($alias)) {
			$alias = substr($alias, 0, 10);
			local($tag) = 'AA';
			local($try) = 100;
			local($attempt);
			while ($try--) {
				$attempt = "$alias$tag";
				last unless &power'used_alias($attempt);
				$tag++;
			}
			$alias = $attempt;
			if (&power'used_alias($alias)) {
				print MAILER "Cannot auto-select any unused alias.\n";
				return 1;	# Failed
			}
		}
		print MAILER "(Selecting alias '$alias' for this power.)\n";
	}
	# Make sure alias is not too long. Don't try to shorten any user-specified
	# alias if they took care of giving one instead of letting mailagent
	# pick one up...
	if (defined($alias) && length($alias) > 12) {
		print MAILER "Alias name too long (12 characters max).\n";
		return 1;
	}
	if (defined($alias) && &power'used_alias($alias)) {
		print MAILER "Alias '$alias' is already in use.\n";
		return 1;
	}
	if (defined($alias) && !&power'add_alias($name, $alias)) {
		print MAILER "Cannot add alias, sorry.\n";
		return 1;
	}
	unless (&power'set_auth($name, *cmdenv'buffer)) {
		print MAILER "Cannot set authentication file, sorry.\n";
		return 1;
	}
	if (-1 == &power'setpwent($name, "<$password>", '')) {
		print MAILER "Cannot add power, sorry.\n";
		return 1;
	}
	if (-1 == &power'set_passwd($name, $password)) {
		print MAILER "Warning: could not insert password.\n";
	}
	&power'add_log("NEW power '$name' created by $cmdenv'uid") if $'loglvl > 2;
	0;
}

# Delete a power from the system. The syntax is:
#    delpower <name> <password> [<security>]
# deletes a power and its associated user list. The 'system' power is required
# to delete most powers except 'root' and 'security'. The 'security' power may
# only be deleted by security and the root power may only be deleted when the
# security password is also specified.
sub run_delpower {
	local($x, $name, $password, $security) = split(' ', $cmdenv'cmd);
	if (
		($name eq 'security' && !&cmdenv'haspower($name)) ||
		($name eq 'root' && !&power'valid('security', $security)) ||
		!&cmdenv'haspower('system')
	) {
		print MAILER "Permission denied (not enough power).\n";
		return 1;
	}
	unless (&root) {
		unless (&power'valid($name, $password)) {
			print MAILER "Permission denied (invalid password).\n";
			return 1;
		}
	}
	&delpower($name);
}

# Actually delete a power from the system, WITHOUT any security checks. It
# is up to the called to ensure the user has correct permissions. Return 0
# if ok and 1 on error.
sub delpower {
	local($name) = @_;
	local($power) = &power'getpwent($name);
	if (!defined $power) {
		print MAILER "Power '$name' does not exist.\n";
		return 1;
	}
	local($auth) = &power'authfile($name);
	if ($auth ne '/dev/null' && !unlink($auth)) {
		&'add_log("SYSERR unlink: $!") if $'loglvl;
		&'add_log("ERROR could not remove clearance file $auth") if $'loglvl;
		print MAILER "Warning: could not remove clearance file.\n";
	}
	unless (&power'del_alias($name)) {
		print MAILER "Warning: could not remove power alias.\n";
	}
	if (0 != &power'rempwent($name)) {
		print MAILER "Failed (cannot remove password entry).\n";
		return 1;
	}
	&power'add_log("DELETED power '$name' by $cmdenv'uid") if $'loglvl > 2;
	0;
}

# Replace current clearance file. The syntax is:
#    setauth <name> <password>
# and requires no special power if the password is given or if the power is
# already detained. Otherwise, the system power is needed. For 'root' and
# 'security' clearances, the corresponding power is needed as well.
sub run_setauth {
	local($x, $name, $password) = split(' ', $cmdenv'cmd);
	local($required) = $name;
	$required = 'system' unless &cmdenv'haspower($name);
	$required = $name if $name eq 'root' || $name eq 'security';
	unless (&cmdenv'haspower($required)) {
		unless (&power'valid($name, $password)) {
			print MAILER "Permission denied.\n";
			return 1;
		}
	}
	unless (&power'set_auth($name, *cmdenv'buffer)) {
		print MAILER "Cannot set authentication file, sorry.\n";
		return 1;
	}
	0;
}

# Add users to clearance file. The syntax is:
#    addauth <name> <password>
# and requires no special power if the password is given or if the power is
# already detained. Otherwise, the system power is needed. For 'root' and
# 'security' clearances, the corresponding power is needed as well.
sub run_addauth {
	local($x, $name, $password) = split(' ', $cmdenv'cmd);
	local($required) = $name;
	$required = 'system' unless &cmdenv'haspower($name);
	$required = $name if $name eq 'root' || $name eq 'security';
	unless (&cmdenv'haspower($required)) {
		unless (&power'valid($name, $password)) {
			print MAILER "Permission denied.\n";
			return 1;
		}
	}
	unless (&power'add_auth($name, *cmdenv'buffer)) {
		print MAILER "Cannot add to authentication file, sorry.\n";
		return 1;
	}
	0;
}

# Remove users from clearance file. The syntax is:
#   remauth <name> <password>
# and requires no special power if the password is given or if the power is
# already detained. Otherwise, the system power is needed. For 'root' and
# 'security' clearances, the corresponding power is needed as well.
sub run_remauth {
	local($x, $name, $password) = split(' ', $cmdenv'cmd);
	local($required) = $name;
	$required = 'system' unless &cmdenv'haspower($name);
	$required = $name if $name eq 'root' || $name eq 'security';
	unless (&cmdenv'haspower($required)) {
		unless (&power'valid($name, $password)) {
			print MAILER "Permission denied.\n";
			return 1;
		}
	}
	unless (&power'rem_auth($name, *cmdenv'buffer)) {
		print MAILER "Cannot remove from authentication file, sorry.\n";
		return 1;
	}
	0;
}

# Get current clearance file. The syntax is:
#    getauth <name> <password>
# and requires no special power if the password is given or if the power is
# already detained. Otherwise, the system power is needed for all powers,
# and for 'root' or 'security', the corresponding power is required.
sub run_getauth {
	local($x, $name, $password) = split(' ', $cmdenv'cmd);
	local($required) = $name;
	$required = 'system' unless &cmdenv'haspower($name);
	$required = $name if $name eq 'root' || $name eq 'security';
	unless (&cmdenv'haspower($required)) {
		unless (&power'valid($name, $password)) {
			print MAILER "Permission denied.\n";
			return 1;
		}
	}
	local($file) = &power'authfile($name);
	&include($file, "$name clearance", '');	# Include file, propagate status
}

# Set internal variable. The syntax is:
#    set <variable> <value>
# and the corresponding variable from cmdenv package is set.
# If <variable> is missing, dump all the known variables.
sub run_set {
	local($x, $var, @args) = split(' ', $cmdenv'cmd);
	if ($var eq '') {				# Dump defined variables
		local($type, $val);
		foreach $name (keys %Set) {
			$type = $Set{$name};	# Variable type 'flag' or 'var'
			$val = eval "defined(\$cmdenv'$name) ? \$cmdenv'$name : undef";
			next unless defined $val;
			$val = $val ? 'true' : 'false' if $type eq 'flag';
			$val = "'$val'" if $type ne 'flag';
			print MAILER "$name=$val\n";
		}
		return 0;
	}
	unless (defined $Set{$var}) {
		print MAILER "Unknown or read-only variable '$var'.\n";
		return 1;		# Failed
	}
	local($type) = $Set{$var};		# The variable type
	local($_);						# Value to assign to variable
	local($val);					# Final assigned value
	if ($type eq 'flag') {
		$_ = $args[0];
		if ($_ eq '' || /on/i || /yes/i || /true/i) {
			$val = 1;
		} else {
			$val = 0;
		}
	} else {
		$val = join(' ', @args);
	}
	eval "\$cmdenv'$var = \$val";	# Set variable in cmdenv package
	0;
}

#
# Utilities
#

# Emit the user prompt in transcript, then copy current line
sub user_prompt {
	if (&root) {
		print MAILER "####> ";			# Command with no restrictions at all
	} elsif ($cmdenv'powers ne '') {
		print MAILER "====> ";			# Command with local privileges
	} elsif ($cmdenv'user ne $cmdenv'uid) {
		print MAILER "~~~~> ";			# Command on behalf of another user
	} else {
		print MAILER "----> ";			# Command from and for current user
	}
	print MAILER "$cmdenv'log\n";
}

# Include file in transcript, returning 1 on failure and 0 on success
# If the third parameter is given, then it is used as leading marks, and
# the enclosing digest lines are omitted.
sub include {
	local($file, $description, $marks) = @_;
	unless (open(FILE, $file)) {
		&'add_log("ERROR cannot open $file: $!") if $'loglvl;
		print MAILER "Cannot open $description file ($!).\n";
		return 1;
	}
	local($_);
	print MAILER "   --- Beginning of file ($description) ---\n"
		unless defined $marks;
	while (<FILE>) {
		(print MAILER) unless defined $marks;
		(print MAILER $marks, $_) if defined $marks;
	}
	close FILE;
	print MAILER "   --- End of file ($description) ---\n"
		unless defined $marks;
	0;		# Success
}

# Signals end of processing
sub finish {
	local($why) = @_;
	print MAILER "End of processing ($why)\n";
	&'add_log("END ($why)") if $'loglvl > 6;
}

# Check whether user has root powers or not.
sub root {
	&cmdenv'haspower('root');
}

#
# Server modes
#

# Allow server to run in trusted mode (where powers may be gained).
sub trusted {
	if ($cmdenv'auth) {			# Valid envelope in mail header
		$cmdenv'trusted = 1;	# Allowed to gain powers
	} else {
		&'add_log("WARNING unable to switch into trusted mode")
			if $'loglvl > 5;
	}
}

# Disable a list of commands, and only those commands.
sub disable {
	local($cmds) = @_;		# List of disabled commands
	undef %Disabled;		# Reset disabled commands, start with fresh set
	foreach $cmd (split(/[\s,]+/, $cmds)) {
		$Disabled{$cmd}++;
	}
	$cmdenv'disabled = join(',', sort keys %Disabled);	# No duplicates
}

# Get shell to run our commands
sub servshell {
	local($shell) = defined($cf'servshell) ? $cf'servshell : 'sh';
	$shell = &'locate_program($shell);
	if (defined($cf'servshell) && !-x($shell)) {
		&'add_log("WARNING invalid configured servshell $shell, using sh")
			if $'loglvl > 2;
		$shell = 'sh';
	}
	$shell;
}

#
# Environment for server commands
#

package cmdenv;

# Set user identification (e-mail address) within cmdenv package
sub inituid {
	# Convenience variables are part of the basic environment for all the
	# server commands. This includes the $envelope variable, which is the
	# user who has issued the request (real uid).
	&hook'initvar('cmdenv');
	$auth = 1;				# Assume valid envelope
	$uid = (&'parse_address($envelope))[0];
	if ($uid eq '') {		# No valid envelope
		&'add_log("NOTICE no valid mail envelope") if $'loglvl > 6;
		$uid = (&'parse_address($sender))[0];
		$auth = 0;			# Will not be able to run in trusted mode
	}
	$user = $uid;			# Until further notice, euid = ruid
	$path = $uid;			# And files are sent to the one who requested them
	undef %powers;			# Reset power table
	$powers = '';			# The linear version of powers
	$errors = 0;			# Number of failed requests so far
	$requests = 0;			# Total number of requests processed so far
	$eof = 'EOF';			# End of file indicator in collection mode
	$collect = 0;			# Not in collection mode
	$trace = 0;				# Not in trace mode
	$trusted = 0;			# Not in trusted mode
}

# Set command parameters
sub set_cmd {
	($cmd) = @_;
	($name) = $cmd =~ /^([\w-]+)/;	# Get command name
	$name =~ tr/A-Z/a-z/;			# Cannonicalize to lower case

	# Passwords in commands may need to be concealed
	if (defined $cmdserv'Conceal{$name}) {
		local(@argv) = split(' ', $cmd);
		local(@pos) = split(/,/, $cmdserv'Conceal{$name});
		foreach $pos (@pos) {
			$argv[$pos] = '********' if defined $argv[$pos];
		}
		$log = join(' ', @argv);
	} else {
		$log = $cmd;
	}
}

# Add a new power to the list once the user has been authenticated.
sub addpower {
	local($newpower) = @_;
	$powers{$newpower}++;
	$powers = join(':', keys %powers);
}

# Remove power from the list.
sub rempower {
	local($oldpower) = @_;
	delete $powers{$oldpower};
	$powers = join(':', keys %powers);
}

# Wipe out all the powers
sub wipe_powers {
	undef %powers;
	$powers = '';
}

# Check whether user has a given power... Note that 'root' has all powers
# but 'security'.
sub haspower {
	local($wanted) = @_;
	$wanted eq 'security' ?
		defined($powers{$wanted}) :
		(defined($powers{'root'}) || defined($powers{$wanted}));
}

package main;

