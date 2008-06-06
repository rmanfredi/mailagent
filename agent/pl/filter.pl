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
;# $Log: filter.pl,v $
;# Revision 3.0.1.11  2001/03/13 13:13:37  ram
;# patch71: changed SUBST/TR parameter parsing to support header fields
;#
;# Revision 3.0.1.10  1998/03/31  15:22:19  ram
;# patch59: when "vacfixed" is on, forbid any change of vacation message
;# patch59: new ON command to process commands on certain days only
;#
;# Revision 3.0.1.9  1997/09/15  15:15:04  ram
;# patch57: fixed ASSGINED -> ASSIGNED typo in log message
;# patch57: implemented new -t and -f flags for BEGIN and NOP
;# patch57: insert user e-mail address if no address for NOTIFY
;#
;# Revision 3.0.1.8  1996/12/24  14:51:51  ram
;# patch45: added initial logging of the SELECT command
;#
;# Revision 3.0.1.7  1995/08/07  16:18:57  ram
;# patch37: new BIFF command
;#
;# Revision 3.0.1.6  1995/01/25  15:20:39  ram
;# patch27: new commands BEEP and PROTECT
;#
;# Revision 3.0.1.5  1995/01/03  18:10:04  ram
;# patch24: commands now get a string with the command name chopped off
;# patch24: modified &alter_execution to accomodate new option parsing
;#
;# Revision 3.0.1.4  1994/10/04  17:50:24  ram
;# patch17: SERVER will now discard whole message on errors
;#
;# Revision 3.0.1.3  1994/09/22  14:20:43  ram
;# patch12: propagated change to the &queue_mail interface
;# patch12: added stubs for DO and AFTER commands
;#
;# Revision 3.0.1.2  1994/07/01  15:00:30  ram
;# patch8: new UMASK command
;#
;# Revision 3.0.1.1  1994/01/26  09:31:43  ram
;# patch5: added tags to UNIQUE and RECORD commands
;#
;# Revision 3.0  1993/11/29  13:48:46  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
;# There are a number of variables which are used by the filter commands and
;# which are in the dynamic scope when those functions are called. The calling
;# tree being: analyze_mail -> xeqte -> run_command -> run_*, where '*' stands
;# for the action we are currently executing.
;#
;# All the run_* commands are called from within an eval by run_command, so that
;# any otherwise fatal error can be trapped and reported in the log file. This
;# is only a precaution against possible typos or other unpredictable errors.
;#
;# The following variables are inherited from run_command:
;#  $mfile is the name of the mail file processed
;#  $cmd is the command to be run
;#  $cms is the same as $cmd but with options and command name chopped off
;#  $cmd_name is the command name (upper-cased)
;#  $ever_saved which states whether a saving/discarding action occurred
;#  $cont is the continuation status, modified by REJECT and friends
;#  $vacation which is a boolean stating whether vacation messages are allowed
;# The following variable is inherited from analyze_mail:
;#  $lastcmd is the failure status of the last command (among those to be kept)
;# The working mode is held in $wmode (comes from analyze_mail).
;#
;# All the commands return an exit status: 0 for ok, 1 for failure. This status
;# is normally recorded in $lastcmd by run_command, unless the executed action
;# belongs to the set of commands whose exit status is discarded (because they
;# can never fail).
;#
#
# Filter commands are run from here
#

# Run the PROCESS command
sub run_process {
	if (0 != &process) {
		&add_log("ERROR while processing [$mfile]--queing it") if $loglvl;
		&queue_mail($file_name, 'fm');
		return 1;
	}
	&add_log("PROCESSED [$mfile]") if $loglvl > 8;
	0;
}

# Run the SERVER command
sub run_server {
	&cmdenv'inituid;				# Initialize server session environment
	&cmdserv'trusted if $opt'sw_t;	# Server runs in trusted mode
	&cmdserv'disable($opt'sw_d) if $opt'sw_d;	# Disable commands for this run
	local(@body) = split(/\n/, $Header{'Body'});
	local($failed) = &cmdserv'process(*body);
	unless ($failed) {
		&add_log("SERVED [$mfile]") if $loglvl > 8;
	} else {
		&add_log("ERROR unable to serve [$mfile]--discarded") if $loglvl;
	}
	$failed;
}

# Run the LEAVE command
sub run_leave {
	local($mbox, $failed) = &leave;
	unless ($failed) {
		&add_log("LEFT [$mfile] in mailbox") if $loglvl > 2;
	}
	# Even if it failed, mark it as saved anyway, as the default action would
	# be a saving in mailbox and there is little chance another attempt would
	# succeed while this one failed.
	$ever_saved = 1;		# At least we tried to save it
	$failed;
}

# Run the SAVE command
sub run_save {
	local($folder) = @_;	# Folder where message should be saved
	&save_message($folder);
}

# Run the STORE command
sub run_store {
	local($folder) = @_;	# Folder where message should be saved
	local($mbox, $failed, $log_message) = &run_saving($folder, $FOLDER_APPEND);
	unless ($failed) {
		$ever_saved = 1;			# We were able to save it
		($mbox, $failed) = &leave;
		unless ($failed) {
			&add_log("STORED [$mfile] in $log_message") if $loglvl > 2;
		} else {
			&add_log("WARNING only SAVED [$mfile] in $log_message")
				if $loglvl > 1;
			return 1;
		}
	} else {
		($mbox, $failed) = &leave;
		unless ($failed) {
			$ever_saved = 1;			# We were able to save it
			&add_log("WARNING only LEFT [$mfile] in mailbox")
				if $loglvl > 1;
		}
	}
	$failed;
}

# Run the WRITE command
sub run_write {
	local($folder) = @_;	# Folder where message should be saved
	local($mbox, $failed, $log_message) = &run_saving($folder, $FOLDER_REMOVE);
	unless ($failed) {
		&add_log("WROTE [$mfile] in $log_message") if $loglvl > 2;
		$ever_saved = 1;			# We were able to save it
	}
	$failed;
}

# Run the DELETE command
sub run_delete {
	&add_log("DELETED [$mfile]") if $loglvl > 2;
	$ever_saved = 1;		# User chose to discard it, it counts as a save
	0;
}

# Run the MACRO command
sub run_macro {
	local($args) = @_;		# Get command arguments
	local($name, $action) = &macro($args);	# Perform the command
	&add_log("MACRO [$mfile] $name $action") if $loglvl > 7;
	0;	# Never fails
}

# Run the MESSAGE command
sub run_message {
	local($msg) = @_;		# Vacation message location
	$msg =~ s/~/$cf'home/g;					# ~ substitution
	local($failed) = &message($msg);
	unless ($failed) {
		$msg = &tilda($msg);				# Replace the home directory by ~
		&add_log("MESSAGE $msg for [$mfile]") if $loglvl > 2;
	}
	$failed;
}

# Run the NOTIFY command
sub run_notify {
	local($args) = @_;
	local(@args) = split(' ', $args);
	local($msg) = shift(@args);				# First argument is message text
	$msg =~ s/~/$cf'home/g;					# ~ substitution
	local($address) = join(' ', @args);		# Address list
	$address = $cf'email if $address eq '';	# No address, defaults to user
	local($failed) = &notify($msg, $address);
	unless ($failed) {
		$msg = &tilda($msg);				# Replace the home directory by ~
		&add_log("NOTIFIED $msg [$mfile] to $address") if $loglvl > 2;
	}
	$failed;
}

# Run the REJECT command
sub run_reject {
	local(*perform) = *do_reject;
	&alter_flow;		# Change control flow by calling &perform
}

# Run the RESTART command
sub run_restart {
	local(*perform) = *do_restart;
	&alter_flow;		# Change control flow by calling &perform
}

# Run the ABORT command
sub run_abort {
	local(*perform) = *do_abort;
	&alter_flow;		# Change control flow by calling &perform
}

# Run the RESYNC command
sub run_resync {
	&header_resync;				# Resynchronize the %Header array
	&add_log("RESYNCED [$mfile]") if $loglvl > 4;
	0;
}

# Run the BEGIN command
sub run_begin {
	local($newstate) = @_;		# New state wanted
	return 0 if $opt'sw_t && $lastcmd;		# -t means change only if true
	return 0 if $opt'sw_f && !$lastcmd;		# -f means change only if false
	$newstate = 'INITIAL' unless $newstate;
	$wmode = $newstate;			# $wmode comes from analyze_mail
	&add_log("BEGUN [$mfile] state $newstate") if $loglvl > 4;
	0;
}

# Run the RECORD command
sub run_record {
	local($mode) = @_;
	local($tags);
	$mode =~ s|^(\w*)\s*\(([^()]*)\).*|$1| && ($tags = $2);
	local($failed) = 0;
	if (&history_tag($tags)) {	# Message already seen
		if ($mode eq '') {
			&add_log("NOTICE entering seen mode")
				if $loglvl > 5 && $wmode ne '_SEEN_';
			# Enter special mode ($wmode from analyze_mail)
			$wmode = '_SEEN_';
		}
		&alter_execution('x', $mode);
		$failed = 1;			# Make sure it "fails"
	}
	local($tagmsg) = $tags ne '' ? " ($tags)" : '';
	&add_log("RECORDED [$mfile]" . $tagmsg) if $loglvl > 4;
	$failed;
}

# Run the UNIQUE command
sub run_unique {
	local($mode) = @_;
	local($tags);
	$mode =~ s|^(\w*)\s*\(([^()]*)\).*|$1| && ($tags = $2);
	local($failed) = 0;
	if (&history_tag($tags)) {	# Message already seen
		&add_log("NOTICE message tagged as saved") if $loglvl > 5;
		$ever_saved = 1;		# In effect, runs a DELETE
		&alter_execution('x', $mode);
		$failed = 1;			# Make sure it "fails"
	}
	local($tagmsg) = $tags ne '' ? " ($tags)" : '';
	&add_log("UNIQUE [$mfile]" . $tagmsg) if $loglvl > 4;
	$failed;
}

# Run the FORWARD command
sub run_forward {
	local($addresses) = @_;		# Address(es)
	local($failed) = &forward($addresses);
	unless ($failed) {
		&add_log("FORWARDED [$mfile] to $addresses") if $loglvl > 2;
		$ever_saved = 1;		# Forwarding succeeded, counts as a save
	}
	$failed;
}

# Run the BOUNCE command
sub run_bounce {
	local($addresses) = @_;		# Address(es)
	local($failed) = &bounce($addresses);
	unless ($failed) {
		&add_log("BOUNCED [$mfile] to $addresses") if $loglvl > 2;
		$ever_saved = 1;		# Bouncing succeeded, counts as a save
	}
	$failed;
}

# Run the POST command
sub run_post {
	local($newsgroups) = @_;	# Newsgroup(s)
	local($failed) = &post($newsgroups);
	unless ($failed) {
		&add_log("POSTED [$mfile] to $newsgroups") if $loglvl > 2;
		$ever_saved = 1;		# Posting succeeded, counts as a save
	}
	$failed;
}

# Run the RUN command
sub run_run {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $NO_INPUT, $NO_FEEDBACK);
	unless ($failed) {
		&add_log("RAN '$program' for [$mfile]") if $loglvl > 4;
	}
	$failed;
}

# Run the PIPE command
sub run_pipe {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $MAIL_INPUT, $NO_FEEDBACK);
	unless ($failed) {
		&add_log("PIPED [$mfile] to '$program'") if $loglvl > 4;
	}
	$failed;
}

# Run the GIVE command
sub run_give {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $BODY_INPUT, $NO_FEEDBACK);
	unless ($failed) {
		&add_log("GAVE [$mfile] to '$program'") if $loglvl > 4;
	}
	$failed;
}

# Run the PASS command
sub run_pass {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $BODY_INPUT, $FEEDBACK);
	unless ($failed) {
		&add_log("PASSED [$mfile] through '$program'") if $loglvl > 4;
	}
	$failed;
}

# Run the FEED command
sub run_feed {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $MAIL_INPUT, $FEEDBACK);
	unless ($failed) {
		&add_log("FED [$mfile] through '$program'") if $loglvl > 4;
	}
	$failed;
}

# Run the PURIFY command
sub run_purify {
	local($program) = @_;		# Program to run
	local($failed) = &shell_command($program, $HEADER_INPUT, $FEEDBACK);
	unless ($failed) {
		&add_log("PURIFIED [$mfile] through '$program'") if $loglvl > 4;
	}
	$failed;
}

# Run the BACK command
# Manipulates dynamically bound variable $cont (output from xeqte)
sub run_back {
	local($command) = @_;
	# The BACK command is handled recursively. The local variable $Back will be
	# set by xeq_back() if any feedback is to ever occur. This routine will be
	# transparently called instead of the usual handle_output() because of the
	# dynamic aliasing done here.
	local($Back) = '';					# BACK may be nested
	local(*handle_output) = *xeq_back;	# Any output to be put in $Back
	local($failed) = 0;
	$command =~ s/%/%%/g;				# Protect against 2nd macro substitution
	# Calling run_command will position $lastcmd to be the return status of
	# the last meaningful command executed. However, we reset $lastcmd before
	# diving into the execution.
	$lastcmd = 0;						# Assume everything went fine
	&run_command($command);				# Run command (ignore return value)
	if ($Back ne '') {
		&add_log("got '$Back' back") if $loglvl > 11;
		$cont = &xeqte($Back);			# Get continuation status back
		$@ = '';						# Avoid cascade of (same) error report
		&add_log("BACK from '$command'") if $loglvl > 4;
	} else {
		&add_log("WARNING got nothing out of '$command'") if $loglvl > 5;
	}
	$lastcmd;			# Propage error status we got from the $command
}

# Run the ON command
sub run_on {
	local($_) = $cmd;					# The whole command line
	local(@days) = split(' ', 'Sun Mon Tue Wed Thu Fri Sat');
	local(%days);
	local($daynum) = 0;
	foreach $day (@days) {				# Initialize Sun => 0, Mon => 1, etc...
		$days{$day} = $daynum++;
	}
	local(@on);							# List of specified days
	local(%on);							# Hash '0' (for sunday) => 1 if selected
	if (s/^ON\s*\(([^\)]*)\)//) {		# List of days, like (Mon Tue)
		@on = split(/,?\s+/, $1);		# Allow (Mon Thu) and (Mon, Thu)
		local($non);
		foreach $on (@on) {
			$non = $on;					# New $on will be canonicalized
			$non =~ s/^(...).*/\u\L$1/;	# Keep only first 3 letters
			unless (defined $days{$non}) {
				&add_log("WARNING ignoring bad day $on in ON (@on)")
					if $loglvl > 5;
				next;
			}
			$on{$days{$non}}++;			# E.g sets $on{1} for Mon
		}
		&add_log("on (@on)") if $loglvl > 18;
	} else {
		&add_log("ERROR bad ON syntax (did not parse right)") if $loglvl > 1;
		return 1;
	}

	# Calling run_command will set $lastcmd to the status of the command. In
	# case we are running a command which does not alter this status, assume
	# everything is fine.

	$lastcmd = 0;						# Assume command will run correctly
	s/^\s*//;							# Remove leading spaces

	local($wday) = (localtime(time))[6];

	if (defined $on{$wday}) {
		&add_log("ON (@on) $_") if $loglvl > 7;
		s/%/%%/g;						# Protect against 2nd macro substitution
		$cont = &run_command($_);		# Run command and update control flow
	} else {
		&add_log("not a good day for $_") if $loglvl > 12;
	}

	$lastcmd;							# Propagates execution status
}

# Run the ONCE command
sub run_once {
	local($_) = $cmd;					# The whole command line
	local($hname);						# Hash name (e-mail address)
	local($tag);						# Tag associated with command
	local($raw_period);					# The period, as written
	if (s/^ONCE\s*\(([^,\)]*),\s*([^,;\)]*),\s*(\w+)\s*\)//) {
		($hname, $tag, $raw_period) = ($1, $2, $3);
		&add_log("tag is ($hname, $tag, $raw_period)") if $loglvl > 18;
	} else {
		&add_log("ERROR bad once syntax (invalid tag)") if $loglvl > 1;
		return 1;
	}
	s/^\s*//;							# Remove leading spaces
	local($period) = &seconds_in_period($raw_period);
	&add_log("period is $raw_period = $period seconds") if $loglvl > 18;

	# Calling run_command will set $lastcmd to the status of the command. In
	# case we are running a command which does not alter this status, assume
	# everything is fine.
	$lastcmd = 0;						# Assume command will run correctly

	if (&once_check($hname, $tag, $period)) {
		&add_log("ONCE ($hname, $tag, $raw_period) $_") if $loglvl > 7;
		&s_once($cmd_name, $wmode, $tag);
		s/%/%%/g;						# Protect against 2nd macro substitution
		$cont = &run_command($_);		# Run it, update continuation status
	} else {
		&add_log("retry time not reached for $_") if $loglvl > 12;
		&s_noretry($cmd_name, $wmode, $tag);
	}

	$lastcmd;							# Propagates execution status
}

# Run the SELECT command
sub run_select {
	local($_) = $cmd;					# The whole command line
	local($start, $end);				# Date strings for start and end
	if (s/^SELECT\s*\(([^.\)]*)\.\.\s*([^\)]*)\)//) {
		($start, $end) = ($1, $2);
		$start =~ s/\s*$//;				# Remove trailing spaces
		$end =~ s/\s*$//;
		&add_log("time is ($start .. $end)") if $loglvl > 18;
	} else {
		&add_log("ERROR bad select syntax (invalid time)") if $loglvl > 1;
		return 1;
	}
	local($now) = time;					# Current time
	local($sec_start, $sec_end);		# Start and end converted in seconds
	$sec_start = &getdate($start, $now);
	if ($sec_start == -1) {
		&add_log("ERROR in SELECT: 1st time '$start'") if $loglvl > 1;
		return 1;
	}
	$sec_end = &getdate($end, $now);
	if ($sec_end == -1) {
		&add_log("ERROR in SELECT: 2nd time '$end'") if $loglvl > 1;
		return 1;
	}
	if ($sec_start > $sec_end) {
		&add_log("WARNING time selection always impossible?") if $loglvl > 1;
		return 0;
	}

	# Calling run_command will set $lastcmd to the status of the command. In
	# case we are running a command which does not alter this status, assume
	# everything is fine.
	$lastcmd = 0;						# Assume command will run correctly

	&add_log("SELECT ($sec_start, $sec_end) at $now") if $loglvl > 11;

	s/^\s*//;							# Remove leading spaces
	if ($now >= $sec_start && $now <= $sec_end) {
		&add_log("SELECT ($start .. $end) $_") if $loglvl > 7;
		s/%/%%/g;						# Protect against 2nd macro substitution
		$cont = &run_command($_);		# Run command and update control flow
	} else {
		&add_log("time period not good for $_") if $loglvl > 12;
	}

	$lastcmd;							# Propagates execution status
}

# Run the NOP command
sub run_nop {
	local($what) = $opt'sw_f ? 'failure' : ($opt'sw_t ? 'success' : '');
	local($force) = $what ? " forcing $what" : '';
	&add_log("NOP [$mfile]$force") if $loglvl > 7;
	return 1 if $opt'sw_f;		# -f forces failure
	return 0 if $opt'sw_t;		# -t forces failure
	$lastcmd;					# Propagates curremt exec status
}

# Run the STRIP command
sub run_strip {
	local($headers) = @_;		# Headers to remove
	&alter_header($headers, $HD_STRIP);
	$headers = join(', ', split(/\s/, $headers));
	&add_log("STRIPPED $headers from [$mfile]") if $loglvl > 7;
	0;
}

# Run the KEEP command
sub run_keep {
	local($headers) = @_;		# Headers to keep
	&alter_header($headers, $HD_KEEP);
	$headers = join(', ', split(/\s/, $headers));
	&add_log("KEPT $headers from [$mfile]") if $loglvl > 7;
	0;
}

# Run the ANNOTATE command
sub run_annotate {
	local($field, $value) = $cms =~ m|([\w\-]+):?\s*(.*)|;
	local($failed) = &annotate_header($field, $value);
	unless ($failed) {
		local($msg) = $opt'sw_d ? ' (no date)' : '';
		&add_log("ANNOTATED [$mfile] with $field$msg") if $loglvl > 7;
	}
	$failed;
}

# Run the ASSIGN command
sub run_assign {
	local($var, $value) = $cms =~ m|^(:?\w+)\s+(.*)|;
	local($eval);						# Evaluated value for expression
	local($@);
	# An expression may be provided as a value. If the whole value is enclosed
	# within simple quotes, then those are stripped and no evaluation is made.
	unless ($value =~ s/^'(.*)'$/$1/) {
		eval "\$eval = $value";			# Maybe value is an expression?
		if ($@) {
			chop($@);
			&add_log("WARNINIG can't evaluate '$value': $@");
		} else {
			$value = $eval;
		}
	}
	if ($var =~ s/^://) {
		&extern'set($var, $value);		# Persistent variable is set
	} else {
		$Variable{$var} = $value;		# User defined variable is set
	}
	&add_log("ASSIGNED '$value' to '$var' [$mfile]") if $loglvl > 7;
	0;
}

# Run the TR command
sub run_tr {
	local($variable, $tr) = $cms =~ m|^(\S+)\s+(.*)|;
	&alter_value($variable, "tr$tr");
}

# Run the SUBST command
sub run_subst {
	local($variable, $s) = $cms =~ m|^(\S+)\s+(.*)|;
	&alter_value($variable, "s$s");
}

# Run the SPLIT command
sub run_split {
	local($folder) = @_;			# Folder where split occurs
	local($failed) = &split($folder);
	if (0 == $failed % 2) {			# Message was in digest format
		if ($failed & 0x4) {
			&add_log("SPLIT [$mfile] in mailagent's queue") if $loglvl > 2;
		} else {
			&add_log("SPLIT [$mfile] in $folder") if $loglvl > 2;
		}
		# If digest was not in RFC-934 style, there is a chance the split
		# was not correctly performed. To avoid any accidental loss of
		# information, the original digest message is also saved if SPLIT
		# had a folder argument, or it is not tagged saved.
		if ($failed & 0x8) {		# Digest was not RFC-934 compliant
			&add_log("NOTICE [$mfile] not RFC-934 compliant") if $loglvl > 6;
			if ($folder ne '') {
				&add_log("NOTICE saving original [$mfile] in $folder")
					if $loglvl > 6;
				&save_message($folder);
			} else {
				&add_log("NOTICE [$mfile] not tagged as saved")
					if $loglvl > 6 && ($failed & 0x2);
			}
		} else {
			$ever_saved = 1 if $failed & 0x2;	# Split -i succeeded
		}
		$failed = 0;
	}
	# If message was not in digest format and a folder was specified, save
	# message in that folder.
	if ($failed < 0 && $folder ne '') {
		&add_log("NOTICE [$mfile] not in digest format") if $loglvl > 6;
		$failed = &save_message($folder);
	}
	$failed ? 1 : 0;	# Failure status from split can be negative
}

# Run the VACATION command
sub run_vacation {
	return 0 unless $cf'vacation =~ /on/i;	# Ignore if vacation mode off
	local($mode, $period) = $cms =~ m|^(\S+)(\s+\S+)?|;
	local($l) = $opt'sw_l ? ' locally' : '';
	local($allowed) = ($mode =~ /off/i) ? 0 : 1;
	&env'local('vacation', $allowed) if $opt'sw_l;
	$env'vacation = $allowed;			# Won't hurt given the above local call
	if ($allowed && $mode !~ /^on$/i) {	# New vacation path given
		if ($cf'vacfixed =~ /on/i) {	# Not allowed if vacfixed is ON
			&add_log("WARNING no message change allowed by 'vacfixed'")
				if $loglvl > 5;
		} else {
			$mode =~ s/^~/$cf'home/;		# ~ substitution
			&env'local('vacfile', $mode) if $opt'sw_l;
			$env'vacfile = $mode;
			&add_log("vacation message in file $mode$l") if $loglvl > 7;
		}
	}
	if ($allowed && $period) {
		&env'local('vacperiod', $period) if $opt'sw_l;
		$env'vacperiod = $period;
		&add_log("vacation period is now $period$l") if $loglvl > 7;
	}
	$mode = $env'vacation ? 'on' : 'off';
	&add_log("vacation message turned $mode$l") if $loglvl > 7;
	0;
}

# Run the QUEUE command
sub run_queue {
	# Mail is saved as a 'qm' file, to avoid endless loops when mailagent
	# processes the queue. This means the mail will be deferred for at
	# least half an hour.
	local($name) = &queue_mail('', 'qm');	# No file name, mail in %Header
	$ever_saved = 1 if defined $name;		# Queuing counts as saving
	defined $name ? 0 : 1;					# Failed if $name is undef
}

# Run the PERL command
sub run_perl {
	local($script) = @_;	# Script to be loaded
	local($failed) = &perl($script);
	unless ($failed) {
		$script = &tilda($script);			# Replace the home directory by ~
		&add_log("PERLED [$mfile] through $script") if $loglvl > 7;
	}
	$failed;
}

# Run the REQUIRE command
sub run_require {
	local($file, $package) = $cms =~ m|^(\S+)\s*(.*)|;
	local($failed) = &require($file, $package);
	unless ($failed) {
		$file = &tilda($file);		# Replace the home directory by ~
		local($inpack) = $file;		# Loaded in a package?
		$inpack .= " in package $package" if $package ne '';
		&add_log("REQUIRED [$mfile] $inpack") if $loglvl > 7;
	}
	$failed;
}

# Run the APPLY command
sub run_apply {
	local($rulefile) = @_;	# Rule file to be applied
	local($failed, $saved) = &apply($rulefile);
	unless ($failed) {
		$rulefile = &tilda($rulefile);		# Replace the home directory by ~
		&add_log("APPLIED [$mfile] rules $rulefile") if $loglvl > 7;
	}
	$ever_saved = 1 if $saved;		# Mark mail as saved if appropriate
	$saved ? $failed : 1;			# Force failure if never saved
}

# Run the UMASK command
sub run_umask {
	local($mask) = @_;
	$mask = oct($mask) if $mask =~ /^0/;
	&env'local('umask', $mask) if $opt'sw_l;	# Restored when leaving rule
	$env'umask = $mask;		# Permanent change, unless changed locally already
	umask($env'umask);
	local($omask) = sprintf("0%o", $mask);	# Octal string, for logging
	local($local) = $opt'sw_l ? ' locally' : '';
	&add_log("UMASK [$mfile] set to ${omask}$local") if $loglvl > 7;
	0;	# Ok
}

# Run the AFTER command
sub run_after {
	local($time, $action) = $cms =~ m|^\((.*)\)(.*)|;
	local($failed, $queued) = &after($time, $action);
	unless ($failed) {
		local(@msg);
		push(@msg, 'shell') if $opt'sw_s;
		push(@msg, 'command') if $opt'sw_c;
		push(@msg, 'no input') if $opt'sw_n;
		push(@msg, 'agent') if $opt'sw_a || 0 == @msg;
		local($type) = join(', ', @msg);
		local($qmsg) = $queued ne '-' ? "-> $queued" : '';
		&add_log("AFTER [$mfile$qmsg] $time {$action} ($type)") if $loglvl > 3;
	}
	$failed;	# Failure status
}

# Run the DO command
sub run_do {
	local($what, $args) = $cms =~ m|^([^()\s]*)(.*)|;
	local($something, $routine) = $what =~ m|^([^:]*):(.*)|;
	$routine = $what if $something eq '';
	local($failed) = &do($something, $routine, $args);
	&add_log("DONE [$mfile] $routine$args") if $loglvl > 7 && !$failed;
	$failed;	# Failure status
}

# Run the BEEP command
sub run_beep {
	local($beep) = @_;
	&env'local('beep', $beep) if $opt'sw_l;	# Restored when leaving rule
	$env'beep = $beep;		# Permanent change, unless changed locally already
	local($local) = $opt'sw_l ? ' locally' : '';
	&add_log("BEEP [$mfile] set to ${beep}$local") if $loglvl > 7;
	0;	# Ok
}

# Run the PROTECT command
sub run_protect {
	local($mode) = @_;
	local($local) = $opt'sw_l ? ' locally' : '';
	if ($opt'sw_u) {
		&env'undef('protect');
		&env'unset('protect') unless $opt'sw_l;
		&add_log("PROTECT [$mfile] reset to default$local") if $loglvl > 7;
		return 0;	# Ok
	}
	$mode = oct($mode) if $mode =~ /^0/;
	&env'local('protect', $mode) if $opt'sw_l;	# Restored when leaving rule
	$env'protect = $mode;	# Permanent change, unless changed locally already
	local($omode) = sprintf("0%o", $mode);	# Octal string, for logging
	&add_log("PROTECT [$mfile] mode set to ${omode}$local") if $loglvl > 7;
	0;	# Ok
}

# Run the BIFF command
sub run_biff {
	local($mode) = $cms =~ m|^(\S+)|;
	local($l) = $opt'sw_l ? ' locally' : '';
	local($allowed) = ($mode =~ /off/i) ? 0 : 1;	# New boolean setting
	local($was) = ($env'biff =~ /off/i) ? 0 : 1;	# Old boolean setting
	local($setting) = $allowed ? 'ON' : 'OFF';
	&env'local('biff', $setting) if $opt'sw_l;
	$env'biff = $setting;				# Won't hurt given the above local call
	if ($allowed && $mode !~ /^on$/i) {	# New biff template format path given
		$mode =~ s/^~/$cf'home/;		# ~ substitution
		&env'local('biffmsg', $mode) if $opt'sw_l;
		$env'biffmsg = $mode;
		&add_log("biff template in file $mode$l") if $loglvl > 7;
	}
	&add_log("biffing turned $setting$l") if $loglvl > 7 && $was != $allowed;
	0;
}

# For SAVE, STORE or WRITE, the job is the same
# If the name is not an absolute path, the folder directory is taken
# in the "maildir" environment variable. If none, defaults to ~/Mail.
# A folder whose name begins with a '+' is taken as an MH folder.
sub run_saving {
	local($folder, $remove) = @_;				# Shall we remove folder first?
	local($folddir) = $XENV{'maildir'};			# Folder directory location
	unless ($folder =~ /^\+/) {					# Not an MH folder
		$folder = "~/mbox" unless $folder;		# No folder -> save in mbox
		$folder =~ s/~/$cf'home/g;				# ~ substitution
		$folddir =~ s/~/$cf'home/g;				# ~ substitution
		$folddir = "$cf'home/Mail" unless $folddir;	# Default folders in ~/Mail
		$folder = "$folddir/$folder" unless $folder =~ m|^/|;
		local($dir) = $folder =~ m|(.*)/.*|;	# Get directory name
		unless (-d "$dir") {
			&makedir($dir);
			unless (-d "$dir") {
				&add_log("ERROR couldn't create directory $dir")
					if $loglvl > 0;
			} else {
				&add_log("created directory $dir") if $loglvl > 7;
			}
		}
	}
	# Cannot use WRITE with an MH folder, it behaves like a SAVE. Same thing
	# when attempting to save in a directory...
	if ($remove == $FOLDER_REMOVE && $folder !~ /^\+/) {
		# Folder has to be removed before writting into it. However, if it
		# is write protected, do not unlink it (save will fail later on anyway).
		# Note that this makes it a candidate for hooks via WRITE, if the
		# folder has its 'x' bit set with its 'w' bit cleared. This is an
		# undocumented feature however (WRITE is not supposed to trigger hooks).
		unlink "$folder" if -f "$folder" && -w _;
	}
	local($mbox, $failed) = &save($folder);
	local($log_message);				# Log message to be issued
	unless ($failed) {
		local($file) = $folder;			# Work on a copy to detect leading dir
		$folddir =~ s/(\W)/\\$1/g;		# Escape possible meta-characters
		$file =~ s|^$folddir/||;		# Preceded by folder directory?
		if ($file =~ s/^\+//) {
			$log_message = "MH folder $file";
		} elsif ($file ne $folder) {
			$log_message = "folder $file";
		} else {
			$log_message = &tilda($folder);	# Replace the home directory by ~
		}
	}

	# Return the status of the save command and a part of the logging message
	# to be issued. That way, we get a nice contextual log.
	($mbox, $failed, $log_message);
}

# Perform the appropriate continuation status, depending on the option:
# When 'x' is given as the option string, then the current options in the
# opt package are used instead of -c, -r or -a.
sub alter_execution {
	local($option, $mode) = @_;	# Option, mode we have to change to
	if ($mode ne '') {
		&add_log("entering new state $mode") if $loglvl > 6 && $wmode ne $mode;
		$wmode = $mode;
	}
	if ($option eq 'x') {		# Backward compatibility at 3.0 PL24
		$option = '-c' if $opt'sw_c;
		$option = '-a' if $opt'sw_a;
		$option = '-r' if $opt'sw_r;
		$option = '' if $option eq 'x';
	}
	&add_log("altering execution in mode '$wmode', option '$option'")
		if $loglvl > 18;
	if ($option eq '-c') {		# Continue execution
		0;
	} elsif ($option eq '-r') {	# Asks for RESTART
		&do_restart;
	} elsif ($option eq '-a') {	# Asks for ABORT
		&do_abort;
	} else {					# Default is to REJECT
		&do_reject;
	}
	# Propagate return status.
}

# Save message in specified folder
sub save_message {
	local($folder) = @_;
	local($mbox, $failed, $log_message) = &run_saving($folder, $FOLDER_APPEND);
	unless ($failed) {
		&add_log("SAVED [$mfile] in $log_message") if $loglvl > 2;
		$ever_saved = 1;			# We were able to save it
	}
	$failed;
}

