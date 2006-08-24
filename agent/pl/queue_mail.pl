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
;# $Log: queue_mail.pl,v $
;# Revision 3.0.1.5  1999/07/12  13:54:33  ram
;# patch66: logs now include filenames in 'quotes'
;#
;# Revision 3.0.1.4  1999/01/13  18:15:50  ram
;# patch64: writing to agent.wait is now more robust and uses locking
;#
;# Revision 3.0.1.3  1996/12/24  14:58:35  ram
;# patch45: add as many trailing 'x' as necessary for unique queue file
;#
;# Revision 3.0.1.2  1995/01/25  15:27:19  ram
;# patch27: ported to perl 5.0 PL0
;#
;# Revision 3.0.1.1  1994/09/22  14:34:16  ram
;# patch12: changed interface of &qmail and &queue_mail for wider usage
;#
;# Revision 3.0  1993/11/29  13:49:11  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
;# Queue a mail file. Needs add_log(). Calls fatal() in emergency situations.
;# Requires a parsed config file.
;# 
# Queue mail in a 'fm' file (or whatever is specified for type). The mail is
# held in memory, within an array passed via a type-glob.
# Returns the name of queued file if success, undef if failed. File name will
# be absolute only when queued outside of the regular queue.
sub qmail {
	local(*array, $type) = @_;	# In which array mail is located.
	local($queue_file);			# Where we attempt to save the mail
	local($failed) = 0;			# Be positive and look forward :-)
	local($name);				# Name of queued file
	$queue_file = "$cf'queue/Mqm$$";
	$queue_file = "$cf'queue/Mqmb$$" if -f "$queue_file";	# Paranoid
	unless (open(QUEUE, ">$queue_file")) {
		&add_log("ERROR unable to create $queue_file: $!") if $loglvl > 1;
		return 1;		# Failed
	}
	# Write mail on disk, making sure there is a first From line
	local($first_line) = 1;
	local($in_header) = 1;		# True while in mail header
	foreach $line (@array) {
		if ($first_line) {
			$first_line = 0;
			print QUEUE "$FAKE_FROM\n" unless $line =~ /^From\s+\S+/;
		}
		next if (print QUEUE $line, "\n");
		$failed = 1;
		&add_log("SYSERR write: $!") if $loglvl;
		last;
	}
	close QUEUE;
	unlink "$queue_file" if $failed;
	unless ($failed) {
		$type = 'fm' unless defined $type;	# Defaults to a 'fm' file
		$name = &queue_mail($queue_file, $type);
		$failed = defined $name ? 0 : 1;
	}
	$failed ? undef : $name;	# File path name, undef if failed
}

# Queue mail in a queue file. There are three types of queued mails:
#   . qm: messages whose handling will be delayed by at most cf'queuehold secs
#   . fm: messages queued for immediate processing by next 'mailagent -q'
#   . cm: callout queue messages, meant for input by callout command
# The mail is supposed to be either on disk or is expected from standard input.
# In case mail comes from stdin, may not return at all but raise a fatal error.
# Returns the name of queued file if success, undef if failed. File name will
# be absolute only when queued outside of the regular queue.
sub queue_mail {
	local($file_name) = shift(@_);		# Where mail to-be-queued is
	local($type) = shift(@_);			# Type of mail message, must be known
	local($dirname);					# Directory name of processed file
	local($tmp_queue);					# Tempoorary storing of queued file
	local($queue_file);					# Final name of queue file
	local($ok) = 1;						# Print status
	local($_);
	&add_log("queuing mail ($type) for delayed processing") if $loglvl > 18;

	if ($file_name ne '' && $file_name !~ m|^/|) {
		local($cwd);
		chop($cwd = `pwd`);
		$file_name = "$cwd/$file_name"
	}
	chdir $cf'queue || &fatal("cannot chdir to $cf'queue");

	local(%known_type) = (				# Known queue message types
		'qm', 1,
		'fm', 1,
		'cm', 1,
	);
	unless ($known_type{$type}) {
		&add_log("ERROR unknown type $type, defaulting to qm") if $loglvl > 1;
		$type = 'qm';
	}

	# The following ensures unique queue mails. As the mailagent itself may
	# queue intensively throughout the SPLIT command, a queue counter is kept
	# and is incremented each time a mail is successfully queued.
	$queue_file = "$type$$";		# Append PID for uniqueness
	$queue_file = "$type${$}x" . $queue_count if -f "$queue_file";
	$queue_file = "${queue_file}x" while -f "$queue_file";	# Paranoid
	++$queue_count;					# Counts amount of queued mails
	&add_log("queue file is $queue_file") if $loglvl > 19;

	# Do not write directly in the fm file, otherwise the main
	# mailagent process could start its processing on it...
	$tmp_queue = "T$type$$";
	local($sender) = "<someone>";	# Attempt to report the sender of message
	if ($file_name) {				# Mail is already on file system
		# Mail already in a file
		$ok = 0 if &mv($file_name, $tmp_queue);
		if ($ok && open(QUEUE, $tmp_queue)) {
			while (<QUEUE>) {
				$Header{'All'} .= $_ unless defined $Header{'All'};
				if (1 .. /^$/) {		# While in header of message
					/^From:[ \t]*(.*)/ && ($sender = $1 );
				}
			}
			close QUEUE;
		}
	} else {
		# Mail comes from stdin or has already been stored in %Header
		unless (defined $Header{'All'}) {	# Only if mail was not already read
			$Header{'All'} = '';			# Needed in case of emergency
			if (open(QUEUE, ">$tmp_queue")) {
				while (<STDIN>) {
					$Header{'All'} .= $_;
					if (1 .. /^$/) {		# While in header of message
						/^From:[ \t]*(.*)/ && ($sender = $1);
					}
					(print QUEUE) || ($ok = 0);
				}
				close QUEUE;
			} else {
				$ok = 0;		# Signals: was not able to queue mail
			}
		} else {							# Mail already in %Header
			if (open(QUEUE, ">$tmp_queue")) {
				local($in_header) = 1;
				foreach (split(/\n/, $Header{'All'})) {
					if ($in_header) {		# While in header of message
						$in_header = 0 if /^$/;
						/^From:[ \t]*(.*)/ && ($sender = $1);
					}
					(print QUEUE $_, "\n") || ($ok = 0);
				}
				close QUEUE;
			} else {
				$ok = 0;		# Signals: was not able to queue mail
			}
		}
	}

	# If there has been some problem (like we ran out of disk space), then
	# attempt to record the temporary file name into the waiting file. If
	# mail came from stdin, there is not much we can do, so we panic.
	if (!$ok) {
		&add_log("ERROR could not queue message '$file_name'") if $loglvl;
		unlink $tmp_queue;
		if ($file_name) {
			# The file processed is already on the disk
			$dirname = $file_name;
			$dirname =~ s|^(.*)/.*|$1|;	# Keep only basename
			$cf'user = (getpwuid($<))[0] || "uid$<" if $cf'user eq '';
			$tmp_queue = "$dirname/$cf'user.$$";
			$tmp_queue = $file_name if &mv($file_name, $tmp_queue);
			&add_log("NOTICE mail held in $tmp_queue") if $loglvl > 4;
		} else {
			&fatal("mail may be lost");	# Mail came from filter via stdin
		}
		# If the mail is on the disk, add its name to the file $AGENT_WAIT
		# in the queue directory. This file contains the names of the mails
		# stored outside of the mailagent's queue and waiting to be processed.
		$ok = &waiting_mail($tmp_queue);
		return undef unless $ok;		# Queuing failed if not ok
		return $tmp_queue;
	}

	# We succeeded in writing the temporary queue mail. Now rename it so that
	# the mailagent may see it and process it.
	if (rename($tmp_queue, $queue_file)) {
		local($bytes) = (stat($queue_file))[7];	# Size of file
		local($s) = $bytes == 1 ? '' : 's';
		&add_log("QUEUED [$queue_file] ($bytes byte$s) from $sender")
			if $loglvl > 3;
	} else {
		&add_log("ERROR cannot rename $tmp_queue to $queue_file") if $loglvl;
		$ok = &waiting_mail($tmp_queue);
		$queue_file = $tmp_queue;
	}
	return undef unless $ok;			# Queuing failed if not ok
	$queue_file;						# Return file name for success
}

# Adds mail into the agent.wait file, if possible. This file records all the
# mails queued with a non-standard name or which are stored outside of the
# queue. Returns 1 if mail was successfully added to this list.
sub waiting_mail {
	local($tmp_queue) = @_;
	local($error) = 0;
	local($old_size) = -s $AGENT_WAIT;
	local($locked) = 0 == &acs_rqst($AGENT_WAIT);

	&add_log("WARNING updating $AGENT_WAIT without lock")
		if !$locked && $loglvl > 5;

	if (open(WAITING, ">>$AGENT_WAIT")) {
		unless (print WAITING "$tmp_queue\n") {
			&add_log("ERROR could not write in $AGENT_WAIT: $!") if $loglvl > 1;
			$error++;
		}
		unless (close WAITING) {
			&add_log("ERROR could not flush $AGENT_WAIT: $!") if $loglvl > 1;
			$error++;
		}
	} else {
		&add_log("ERROR unable to open $AGENT_WAIT: $!") if $loglvl > 0;
		$error++;
	}

	&free_file($AGENT_WAIT) if $locked;

	if (!error && defined $old_size) {
		local($size) = -s $AGENT_WAIT;
		local($expected) = $old_size + length($tmp_queue) + 1;
		if ($size != $expected) {
			&add_log("ERROR $AGENT_WAIT has $size bytes (expected $expected)")
				if $loglvl > 1;
			$error++;
		}
	}

	if ($error) {
		&add_log("ERROR has forgotten about $tmp_queue") if $loglvl;
	} else {
		&add_log("NOTICE processing deferred for $tmp_queue") if $loglvl > 3;
	}

	return $error ? 0 : 1;			# 1 means success
}

# Performs a '/bin/mv' operation, but without the burden of an extra process.
sub mv {
	local($from, $to) = @_;		# Original path and destination path
	# If the two files are on the same file system, then we may use the rename()
	# system call.
	if (&same_device($from, $to)) {
		&add_log("using rename system call") if $loglvl > 19;
		unless (rename($from, $to)) {
			&add_log("SYSERR rename: $!") if $loglvl;
			&add_log("ERROR could not rename $from into $to") if $loglvl;
			return 1;
		}
		return 0;
	}
	# Have to emulate a 'cp'
	&add_log("copying file $from to $to") if $loglvl > 19;
	unless (open(FROM, $from)) {
		&add_log("SYSERR open: $!") if $loglvl;
		&add_log("ERROR cannot open source '$from' to copy to '$to'")
			if $loglvl;
		return 1;
	}
	unless (open(TO, ">$to")) {
		&add_log("SYSERR open: $!") if $loglvl;
		&add_log("ERROR cannot create target '$to' to copy '$from' to it")
			if $loglvl;
		close FROM;
		return 1;
	}
	local($ok) = 1;		# Assume all I/O went all right
	local($_);
	while (<FROM>) {
		next if print TO;
		$ok = 0;
		&add_log("SYSERR write: $!") if $loglvl;
		last;
	}
	close FROM;
	close TO;
	unless ($ok) {
		&add_log("ERROR could not copy '$from' to '$to'") if $loglvl;
		unlink $to;
		return 1;
	}
	# Copy succeeded, remove original file
	unlink $from;
	0;					# Denotes success
}

# Look whether two paths refer to the same device.
# Compute basename and directory name for both files, as the file may
# not exist. However, if both directories are on the same file system,
# then so is it for the two files beneath each of them.
sub same_device {
	local($from, $to) = @_;		# Original path and destination path
	local($fromdir, $fromfile) = $from =~ m|^(.*)/(.*)|;
	($fromdir, $fromfile) = ('.', $fromdir) if $fromfile eq '';
	local($todir, $tofile) = $to =~ m|^(.*)/(.*)|;
	($todir, $tofile) = ('.', $todir) if $tofile eq '';
	local($dev1) = stat($fromdir);
	local($dev2) = stat($todir);
	$dev1 == $dev2;
}

