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
;# $Log: callout.pl,v $
;# Revision 3.0.1.3  1997/02/20  11:42:52  ram
;# patch55: ensure %Header and $wmode are localized in the main package
;#
;# Revision 3.0.1.2  1995/02/03  18:01:12  ram
;# patch30: order of arguments was wrong when calling &spawn
;# patch30: could loop forever in &run when flushing the whole queue
;# patch30: value of first_callout time was not set right the first time
;# patch30: added more debugging information
;#
;# Revision 3.0.1.1  1994/09/22  14:13:07  ram
;# patch12: created
;#
;#
;# This package implements a callout queue for a limited "at" support in
;# mailagent commands. Since items in the callout queue can only be dispatched
;# by another call to the mailagent command, execution at an exact time cannot
;# be guaranteed; instead we say the action will be launched "after" a certain
;# date.
;#
;# It is quite admissible, however, to schedule a periodic cron job launching
;# a 'mailagent -q' command to actually force processing of the queue and also
;# of the callout queue, as a side effect... This is up to you, the user, to
;# ensure that, depending on the required accuracy for your AFTER commands.
;#
;# The callout queue is handled as a sorted list with a single text file:
;#
;#   <timestamp> <type> <filename> <command>
;#
;# where:
;#  - timestamp is the time in seconds elapsed since the Epoch, after which
;#    the job should be launched.
;#  - type is either 'agent' or 'shell' depending on whether the command is
;#    a shell command or a mailagent filtering command (which can be a possible
;#    mailagent call back to a perl routine via DO).
;#  - command is the command to be run. Everything up to the new line.
;#
;# When loaded in memory, the callout queue is held in three hash tables:
;#  %Calltype: associates a timestamp to a list of ^@-separated types
;#  %Callout: associates a timestamp to a list of ^@-separated actions
;#  %Callfile: associates a timestamp with a list of file names
;# This separation by means of ^@ is necessary since more than one event may
;# be associated to a single point in time.
;#
package callout;

#
# Callout queue handling
#

# Init constants -- must be called after mailagent context was loaded
sub init {
	$AGENT = 'agent';		# Action is a mailagent command
	$SHELL = 'shell';		# Action is a standalone shell command
	$CMD = 'cmd';			# Action is a shell command on a mail message
	$first_callout = &context'get('next-callout');	# undef if not there
	$callout_changed = 0;	# Records changes in callout queue
}

# Load callout queue file into memory. Before exiting, mailagent will flush
# it again to the disk if it has been modified in some way. It is not an error
# for the file not to exist: it means the callout queue has been emptied.
sub load {
	unless (open(CALLOUT, $cf'callout)) {
		&'add_log("WARNING unable to open callout queue file: $!")
			if -f $cf'callout && $'loglvl > 5;
		return;
	}
	&'add_log("loading mailagent callout queue") if $'loglvl > 15;
	local($_, $.);
	while (<CALLOUT>) {
		next if /^\s*#/;
		if (/^(\d+)\s+(\w+)\s+(\S+)\s+(.*)/) {
			$Calltype{$1} .= "$2\0";
			$Callfile{$1} .= "$3\0";
			$Callout{$1} .= "$4\0";
			next;
		}
		&'add_log("WARNING callout queue corrupted, line $.") if $'loglvl > 5;
		last;
	}
	close CALLOUT;
	return unless %Callout;		# Nothing loaded, empty file...

	local($next_callout) = (sort keys %Callout)[0];
	if ($next_callout != $first_callout) {
		&'add_log(
			"NOTICE next-callout is $first_callout, should be $next_callout"
		) if $'loglvl > 6;
		&'add_log("WARNING inconsistency in mailagent context (next-callout)")
			if $'loglvl > 5;
	}
	$first_callout = $next_callout;		# Trust callout queue over context
}

# Enqueue a new job to be performed after a certain time. If the job is to be
# launched before the first one in the queue, the next-callout value in the
# mailagent context is updated.
# Return the queued file name, or '-' if none, undef on errors.
sub queue {
	local($time, $action, $type, $no_input) = @_;
	&'add_log("queueing callout on $time ($action)") if $'loglvl > 15;
	$callout_changed++;
	&load unless %Callout;
	local($qname) = '-';			# File not queued by default
	if ($type ne $SHELL && !$no_input) {
		# 'agent' or 'cmd' callouts have input by default, unless $no_input
		# is specified in the arguments.
		local(@mail);				# Temporary mail storage
		@mail = split(/\n/, $'Header{'All'});
		$qname = &'qmail(*mail, 'cm');
		unless (defined $qname) {
			&'add_log("ERROR cannot record $type callout $action for $time")
				if $'loglvl > 1;
			return undef;
		}
	}
	$Callfile{$time} .= "$qname\0";	# Add queue name to the list
	$Calltype{$time} .= "$type\0";	# Add type to the list
	$Callout{$time} .= "$action\0";	# Add action at this time stamp
	$first_callout = $time
		if !defined($first_callout) || $time < $first_callout;
	&'add_log("first callout time is now $first_callout") if $'loglvl > 15;
	return $qname;
}

# Return trigger time for a callout, based on its file name. This is primarily
# used to list the callout queue. If no callout is found, returns 0.
sub trigger {
	local($file) = @_;
	local($directory, $base) = $file =~ m|(.*)/(.*)|;
	$file = $directory eq $cf'queue ? $base : $file;
	&load unless %Callout;
	local($time, $files);
	foreach $time (keys %Callfile) {
		$files = $Callfile{$time};
		next unless "\0$files" =~ /\0$file\0/;
		return $time;
	}
	return 0;
}

# Run the queue, by poping off the first set in the queue, and executing
# it. If by that time another timeout expires, loop again.
sub run {
	&'add_log("running callout queue") if $'loglvl > 15;
	$callout_changed++;
	&load unless %Callout;
	local(@type, @action, @file);
	local($type, $action, $file);
	do {
		chop($type = $Calltype{$first_callout});	# Remove trailing \0
		chop($action = $Callout{$first_callout});
		chop($file = $Callfile{$first_callout});
		@type = split(/\0/, $type);
		@action = split(/\0/, $action);
		@file = split(/\0/, $file);
		while ($type = shift(@type)) {
			$action = shift(@action);
			$file = shift(@file);
			&spawn($type, $action, $file);		# Spawn callout action
		}
		delete $Calltype{$first_callout};
		delete $Callout{$first_callout};
		delete $Callfile{$first_callout};
		$first_callout = (sort keys %Callout)[0];
	} while ($first_callout && time >= $first_callout);
	&'add_log("callout queue flushed") if $'loglvl > 15;
}

# Flush the callout queue to the disk. This operation launches the commands
# that have expired, then rewrites a new callout queue file to the disk if
# required. When all the jobs from the queue have been run, the callout file
# is removed and the next-callout value is deleted from the context.
# NOTE: this is called by &main'contextual_operations in pl/context.pl, before
# the new mailagent context is actually saved to the disk. Therefore, we are
# able to update next-callout for the next mailagent run.
sub flush {
	return unless defined $first_callout;
	&run if time >= $first_callout;		# Run queue if time reached
	return unless $callout_changed;		# Done if no change since &init
	&save;
	&context'set('next-callout', $first_callout);
}

# Save the callout queue on disk. If the %Callout table is empty, the
# callout file is removed.
sub save {
	local($count) = scalar(keys %Callout);
	unless ($count) {
		&'add_log("removing mailagent callout queue") if $'loglvl > 15;
		unlink($cf'callout);
		return;
	}
	&'add_log("saving $count entries in callout queue") if $'loglvl > 15;

	local($existed) = -f $cf'callout;
	&'acs_rqst($cf'callout) if $existed;	# Lock existing file

	unless (open(CALLOUT, ">$cf'callout")) {
		&'add_log("ERROR cannot overwrite callout queue $cf'callout: $!")
			if $'loglvl > 1;
		&'free_file($cf'callout) if $existed;
		return;
	}

	print CALLOUT "# Mailagent callout queue, last updated " .
		scalar(localtime()) . "\n";

	local(@type, @action, @file);
	local($type, $action, $file);

	# De-compile callout data structure back into a human-readable table
	foreach $time (sort keys %Callout) {
		chop($type = $Calltype{$time});		# Remove trailing \0
		chop($action = $Callout{$time});
		chop($file = $Callfile{$time});
		@type = split(/\0/, $type);			# Type and action lists per time
		@action = split(/\0/, $action);
		@file = split(/\0/, $file);
		while ($type = shift(@type)) {
			$action = shift(@action);
			$file = shift(@file);
			print CALLOUT "$time\t$type\t$file\t$action\n";
		}
	}

	close CALLOUT;
	&'free_file($cf'callout) if $existed;
}

#
# Spawning engine
#

# Spawn callout action given its type, and the mail file on which the action
# takes place. If the file name is '-', then no input, but only for shell
# commands.
sub spawn {
	local($type, $action, $file) = @_;
	local($sub) = 'spawn_' . $type;
	local($file_name) = $file;		# Where mail is held (within queue usually)
	local(%'Header);				# Where filtering information is stored
	&'add_log("spawning $action on $file ($type)") if $'loglvl > 14;
	# File name is absolute if not within mailagent's queue, otherwise it
	# is only a relative path name, as returned by &qmail. Shell commands
	# specify '-', meaning no input is to be taken.
	$file_name = $cf'queue . '/' . $file_name unless $file_name =~ m|^/|;
	if (defined &$sub) {
		&'add_log("setting up mailagent data structures for $file")
			if $'loglvl > 15;
		&'parse_mail($file_name) if $file ne '-';	# Fill in %Header
		&'add_log("spawning callout $type type on $file: $action")
			if $'loglvl > 15;
		local($failed);
		$failed = &$sub($action);		# Invoke call-out action
		$failed = $failed ? 'FAILED' : 'OK';
		&'add_log("$failed CALLOUT ($type) [$file] $action") if $'loglvl > 7;
	} else {
		&'add_log("ERROR unknown callout type $type -- skipping $action")
			if $'loglvl;
	}
	unlink $file_name unless $file eq '-';
}

# Spawn filtering command
sub spawn_agent {
	local($action) = @_;
	local($mode) = '_CALLOUT_';	# Initial working mode
	local($'wmode) = $mode;		# Needed for statistics routines
	umask($cf'umask);			# Reset default umask
	&'xeqte($action);			# Run action
	umask($cf'umask);			# Reset umask anyway
	return 0;
}

# Spawn command-on-mail, i.e. shell command with mail on stdin
sub spawn_cmd {
	local($action) = @_;
	return &'shell_command($action, $'MAIL_INPUT, $'NO_FEEDBACK);
}

# Spawn shell command
sub spawn_shell {
	local($action) = @_;
	return &'shell_command($action, $'NO_INPUT, $'NO_FEEDBACK);
}

package main;

