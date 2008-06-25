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
;# $Log: runcmd.pl,v $
;# Revision 3.0.1.8  2001/01/10 16:57:23  ram
;# patch69: new -b switch for POST to request biffing
;#
;# Revision 3.0.1.7  1998/03/31  15:27:18  ram
;# patch59: declared the new "ON" command
;#
;# Revision 3.0.1.6  1997/09/15  15:17:32  ram
;# patch57: NOP now returns a status
;# patch57: added -t and -f switches for BEGIN and NOP
;# patch57: $lastcmd now global from analyze_mail()
;#
;# Revision 3.0.1.5  1995/08/07  16:25:05  ram
;# patch37: new BIFF command
;#
;# Revision 3.0.1.4  1995/01/25  15:29:01  ram
;# patch27: new commands PROTECT and BEEP
;#
;# Revision 3.0.1.3  1995/01/03  18:18:01  ram
;# patch24: added generic option parsing code for easier extensions
;# patch24: chops off the action name and options before calling handler
;#
;# Revision 3.0.1.2  1994/09/22  14:37:08  ram
;# patch12: new DO and AFTER commands
;#
;# Revision 3.0.1.1  1994/07/01  15:04:58  ram
;# patch8: new UMASK command
;#
;# Revision 3.0  1993/11/29  13:49:15  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Execute the action enclosed in braces. The current working mode 'wmode' is
;# a local variable defined in analyze_mail. But this variable is visible when
;# 'xeqte' is called from within it. Thanks perl.
;#
;# The following commands are available (case is irrelevent):
;#  ABORT                    Aborts filtering right away
;#  AFTER time <cmd>         Records command in the callout queue
;#  ANNOTATE field <value>   Annotation in header a la MH
;#  APPLY rulefile           Apply an alternate rule file on message
;#  ASSIGN var <value>       Assign value to the user-defined variable
;#  BACK <cmd>               Execute <cmd> and eval its output
;#  BEEP amount              Change amount of beeps for %b escape while biffing
;#  BEGIN state              Enter in a new state for analysis
;#  BIFF on/off              Dynamically turns biffing on/off
;#  BOUNCE address(es)       As FORWARD but leave header intact
;#  DO routine(args)         Call perl routine
;#  DELETE                   Trash the mail away
;#  FEED program             Same as PASS, but the whole message is given
;#  FORWARD address(es)      Forwards mail to specified addresses
;#  GIVE program             Give the body of the message to a program
;#  KEEP header(s)           Lists the header fields we want to keep
;#  LEAVE                    Leave mail in incomming mailbox
;#  MACRO name = (val, type) Define a user macro
;#  MESSAGE vacation         Sends a vacation-like message back
;#  NOP                      No operation (useful only with ONCE)
;#  NOTIFY address message   Notifies address with a given message
;#  ON (days) <cmd>          Executes any other single command on specified days
;#  ONCE (period) <cmd>      Executes any other single command once per period
;#  PASS program             Pass body to program and get new body back
;#  PERL script              Run script to perform some filtering actions
;#  PIPE program             Pipes message to program
;#  POST newsgroup(s)        Post message on specified newsgroups
;#  PROCESS                  The mailagent processes the commands in body
;#  PROTECT mode             Set folder protection mode upon creation
;#  PURIFY program           Feed header to program and get new header back
;#  QUEUE                    Queue mail (counts as save if successful)
;#  RECORD                   Record message and REJECT in seen mode if present
;#  REJECT                   Abort execution and continue analysis
;#  REQUIRE file [package]   Load perl code from file
;#  RESTART                  Abort execution and restart analysis from scratch
;#  RESYNC                   Resynchronize header (useful only with FEED)
;#  RUN program              Run the specified program
;#  SAVE folder              Saves mail in folder for delayed reading
;#  SELECT (when) <cmd>      Run command only within certain time period
;#  SERVER                   Process server commands
;#  SPLIT folder             Split digest message into folder
;#  STORE folder             Same as SAVE folder; LEAVE
;#  STRIP header(s)          Removes the lines from the message's header
;#  SUBST var //             Apply a substitution on variable
;#  TR var //                Apply a translation on variable
;#  UMASK value              Set a new umask for the process
;#  UNIQUE                   Delete message if already in history and REJECT
;#  VACATION on/off          Allow/disallow vacation messages
;#  WRITE folder             Writes mail in folder (replaces, does not append)

# Split the commands and execute them. This function is the main entry point
# for nesting level (e.g. execution of commands from BACK are driven by xeqte).
# We wish to keep track of the execution status of the last command, as does
# the shell with its $? variable. This is done by $lastcmd.
sub xeqte {
	local($line) = shift(@_);		# Commands to execute
	local(@cmd);					# The commands to be ran
	local($status) = $FT_CONT;		# Status returned by run_command
	local($_);

	# Normally, a ';' separates each action. However, an escaped one as in \;
	# must not be taken into account. We also need to escape a single \, in
	# case we want a \ followed by a ; grr...
	$line =~ s/\\\\/\02/g;			# \\ -> ^B
	$line =~ s/\\;/\01/g;			# \; -> ^A
	@cmd = split(/;/, $line);		# Put all commands in an array
	foreach (@cmd) {				# Now restore orginal escaped sequences
		s/\01/;/g;					# ^A -> ;
		s/\02/\\/g;					# ^B -> \
	}

	# Now run each command in turn
	foreach $cmd (@cmd) {
		$status = &run_command($cmd);
		last unless $status == $FT_CONT;
	}

	# Remap $FT_ABORT on $FT_CONT. In effect, we just skipped the remaining
	# commands on the line and act as if they had been executed. This indeed
	# achieves the ABORT command.
	$status = $FT_CONT if $status == $FT_ABORT;
	$status;
}

# Executes a filter command and return continuing status:
#  FT_CONT to continue
#  FT_REJECT if a reject was found
#  FT_RESTART if a restart was found
#  FT_ABORT if an abort was found
sub run_command {
	local($cmd) = @_;				# Command to be run (passed to subroutines)
	local($cmd_name);				# Command name
	local($cont) = $FT_CONT;		# Continue by default
	local($mfile) = mail_logname($file_name);
	&macros_subst(*cmd);			# Macros substitutions
	$cmd =~ s/^\s*//;				# Remove leading spaces
	$cmd =~ s/\s*$//;				# And trailing ones
	return $cont unless $cmd;		# Ignore null instructions
	($cmd_name) = $cmd =~ /^(\w+)/;
	$cmd_name =~ tr/a-z/A-Z/;		# In uppercase from now on
	# In the special mode _SEEN_, only a restricted set of action are allowed
	if ($wmode eq '_SEEN_') {
		if ($Rfilter{$cmd_name}) {
			&add_log("WARNING command $cmd_name not allowed") if $loglvl > 5;
			return $cont;
		}
	}
	&add_log("XEQ ($cmd)") if $loglvl > 10;
	print ">> $cmd\n" if $track_all;		# Option -t
	local($routine) = $Filter{$cmd_name};

	# Unknown commands default to LEAVE if no save have ever been done.
	# Otherwise, they are simply ignored.
	unless ($routine) {
		local($what) = 'defaults to LEAVE';
		$what = 'ignored' if $ever_saved;
		&add_log("ERROR unknown command $cmd_name ($what)")
			if $loglvl > 1;
		$routine = $Filter{'LEAVE'};		# Default action
		return $cont if $ever_saved;		# Command ignored
	}

	# Argument parsing within package opt, defining $opt'sw_i if -i for
	# instance. We first reset previous instances from a former command,
	# then parse it for arguments (if any specified in %Option), updating
	# the command string as needed to remove the options as they are found.
	local($opt) = $Option{$cmd_name};
	local($cms) = $cmd;
	if ($opt) {
		&opt'reset;
		$cms = &opt'parse($cmd, $opt);
	}

	# Call routine to handle the action, passing it a string containing
	# the command arguments, as adjusted by a possible option parsing.
	$cms =~ s/^\w+\s*//;						# Comamnd name stripped
	local($failed) = eval("&$routine(\$cms)");	# Eval traps all fatal errors
	$failed = 1 if &eval_error;					# Make sure eval worked

	&opt'restore if $opt;		# Restore options, in case of recursion

	# If command does not belong to the set of those who do not modify the
	# last execution status recorded, then update $lastcmd with the failure
	# status.
	$lastcmd = $failed unless $Nostatus{$cmd_name};

	# Update statistics
	unless ($failed) {
		&s_action($cmd_name, $wmode);
	} else {
		&s_failed($cmd_name, $wmode);
	}
	$cont;				# Continue status
}

# Each filter command is handled by a specific function. The Filter array
# maps an action name to a subroutine, while the Rfilter array lists the
# authorized actions in the special mode _SEEN_ (used when a mail already
# filtered is processed).
# The %Nostatus array records the commands which do not modify the execution
# status recorded by the last command. Typically, those are commands which can
# never fail.
sub init_filter {
	%Filter = (
		'ABORT', 'run_abort',		# Aborts application of filtering rules
		'AFTER', 'run_after',		# Records callout action
		'ANNOTATE', 'run_annotate',	# Add new field into header
		'APPLY', 'run_apply',		# Apply alternate rule file on message
		'ASSIGN', 'run_assign',		# Assign value to variable
		'BACK', 'run_back',			# Eval feedback
		'BEEP', 'run_beep',			# Change value of %b escape when biffing
		'BEGIN', 'run_begin',		# Enter in a new state
		'BIFF', 'run_biff',			# Turn biffing on/off dynamically
		'BOUNCE', 'run_bounce',		# Bounce message
		'DO', 'run_do',				# Call perl routine directly
		'DELETE', 'run_delete',		# Throw mail away, explicitely
		'FEED', 'run_feed',			# Feed back mail through program
		'FORWARD', 'run_forward',	# Forward mail
		'GIVE', 'run_give',			# Give body to command
		'KEEP', 'run_keep',			# Keep only the listed header fields
		'LEAVE', 'run_leave',		# Saving in incomming mailbox
		'MACRO', 'run_macro',		# Define a user macro
		'MESSAGE', 'run_message',	# Send a vacation-like file
		'NOP', 'run_nop',			# No operation
		'NOTIFY', 'run_notify',		# Notify reception of message
		'ON', 'run_on',				# On day control
		'ONCE', 'run_once',			# Once control
		'PASS', 'run_pass',			# Pass body to program with feedback
		'PERL', 'run_perl',			# Perform actions from within a perl script
		'PIPE', 'run_pipe',			# Pipe message to specified command
		'POST', 'run_post',			# Post mail to the net
		'PROCESS', 'run_process',	# Mailagent processing
		'PROTECT', 'run_protect',	# Change default folder protection mode
		'PURIFY', 'run_purify',		# Purify header through a program
		'QUEUE', 'run_queue',		# Queue mail
		'RECORD', 'run_record',		# Record message in history
		'REJECT', 'run_reject',		# Reject
		'REQUIRE', 'run_require',	# Load perl code
		'RESTART', 'run_restart',	# Restart
		'RESYNC', 'run_resync',		# Resynchronizes the header
		'RUN', 'run_run',			# Run specified program
		'SAVE', 'run_save',			# Save in a folder
		'SELECT', 'run_select',		# Time selection control
		'SERVER', 'run_server',		# Server processing
		'SPLIT', 'run_split',		# Split digest message
		'STORE', 'run_store',		# Save and leave copy in mailbox
		'STRIP', 'run_strip',		# Strip some header lines
		'SUBST', 'run_subst',		# Substitution on variable
		'TR', 'run_tr',				# Translation on variable
		'UMASK', 'run_umask',		# Set new umask
		'UNIQUE', 'run_unique',		# Delete message if already in history
		'VACATION', 'run_vacation',	# Allow or forbid vacation messages
		'WRITE', 'run_write',		# Write mail in folder
	);
	# Option string for &opt'get parsing (syntax similar to getopt)
	%Option = (
		'ABORT',	'ft',
		'AFTER',	'acns',
		'ANNOTATE',	'du',
		'BEEP',		'l',
		'BEGIN',	'ft',
		'BIFF',		'l',
		'FEED',		'be',
		'MACRO',	'rdp',
		'NOP',		'tf',
		'PIPE',		'b',
		'POST',		'lb',
		'PROTECT',	'lu',
		'RECORD',	'acr',
		'REJECT',	'ft',
		'RESTART',	'ft',
		'SERVER',	'd:t',
		'SPLIT',	'adeiw',
		'UMASK',	'l',
		'UNIQUE',	'acr',
		'VACATION',	'l',
	);
	# Restricted filter actions: the commands listed below cannot be
	# executed in the special seen mode (in order to avoid loops).
	%Rfilter = (
		'BACK', 1,
		'BOUNCE', 1,
		'DO', 1,
		'FEED', 1,
		'FORWARD', 1,
		'GIVE', 1,
		'NOTIFY', 1,
		'PASS', 1,
		'PIPE', 1,
		'POST', 1,
		'PURIFY', 1,
		'QUEUE', 1,
		'RUN', 1,
	);
	# The following commands do not modify the last status recorded.
	%Nostatus = (
		'ABORT', 1,
		'ASSIGN', 1,
		'BEEP', 1,
		'BIFF', 1,
		'BEGIN', 1,
		'KEEP', 1,
		'MACRO', 1,
		'PROTECT', 1,
		'REJECT', 1,
		'RESTART', 1,
		'RESYNC', 1,
		'STRIP', 1,
		'UMASK', 1,
		'VACATION', 1,
	);
}

