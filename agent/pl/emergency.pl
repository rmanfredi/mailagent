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
;# $Log: emergency.pl,v $
;# Revision 3.0.1.3  1999/01/13  18:13:18  ram
;# patch64: only use last two digits from year in logfiles
;# patch64: resync of agent.wait now more robust and uses locking
;#
;# Revision 3.0.1.2  1997/01/07  18:32:40  ram
;# patch52: now pre-extend memory by using existing message size
;#
;# Revision 3.0.1.1  1996/12/24  14:51:14  ram
;# patch45: don't dataload the emergency routine to avoid malloc problems
;# patch45: now log the signal trapping even when invoked manually
;#
;# Revision 3.0  1993/11/29  13:48:41  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Emergency situation routines
#

# Perload OFF
# (Better not be dynamically loaded as it is a signal handler)

# Emergency signal was caught
sub emergency {
	local($sig) = @_;			# First argument is signal name
	if ($has_option) {			# Mailagent was invoked "manually"
		&resync;				# Resynchronize waiting file if necessary
		&add_log("ERROR trapped SIG$sig") if $loglvl;
		exit 1;
	}
	&fatal("trapped SIG$sig");
}

# Perload ON

# In case something got wrong
sub fatal {
	local($reason) = shift;		# Why did we get here ?
	local($preext) = 0;
	local($added) = 0;
	local($curlen) = 0;

	# Make sure the lock file does not last. We don't need any lock now, as
	# we are going to die real soon anyway.
	unlink $lockfile if $locked;

	# Assume the whole message has not been read yet
	$fd = STDIN;				# Default input
	if ($file_name ne '') {
		$Header{'All'} = '';	# We're about to re-read the whole message
		open(MSG, $file_name);	# Ignore errors
		$fd = MSG;
		$preext = -s MSG;
	}
	if ($preext <= 0) {
		$preext = 100000;
		&add_log ("preext uses fixed value ($preext)") if $loglvl > 19;
	} else {
		&add_log ("preext uses file size ($preext)") if $loglvl > 19;
	}

	# We have to careful here, because when reading from STDIN
	# $Header{'All'} might not be empty
	$curlen = length($Header{'All'});
	&add_log ("pre-extended retaining $curlen old bytes") if $loglvl > 19;
	$Header{'All'} .= ' ' x $preext;
	substr($Header{'All'}, $curlen) = '';

	unless (-t $fd) {			# Do not get mail if connected to a tty
		while (<$fd>) {
			$added += length($_);
			if ($added > $preext) {
				$curlen = length($Header{'All'});
				&add_log ("extended after $curlen bytes") if $loglvl > 19;
				$Header{'All'} .= ' ' x $preext;
				substr($Header{'All'}, $curlen) = '';
				$added = $added - $preext;
			}
			$Header{'All'} .= $_;
		}
	}

	# It can happen that we get here before configuration file was read
	if (defined $loglvl) {
		&add_log("FATAL $reason") if $loglvl;
		-t STDIN && print STDERR "$prog_name: $reason\n";
	}

	# Try an emergency save, if mail is not empty
	if ($Header{'All'} ne '' && 0 == &emergency_save) {
		# The stderr should be redirected to some file
		$file_name =~ s|.*/(.*)|$1|;	# Keep only basename
		$file_name = "<stdin>" if $file_name eq '';
		print STDERR "**** $file_name not processed ($reason) ****\n";
		print STDERR $Header{'All'};
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
			localtime(time);
		$date = sprintf("%.2d/%.2d/%.2d %.2d:%.2d:%.2d",
			$year % 100,++$mon,$mday,$hour,$min,$sec);
		print STDERR "---- $date ----\n";
	}

	&resync;			# Resynchronize waiting file if necessary
	# Give an error exit status to filter
	exit 1;
}

# Emergency saving of message held in $Header{'All'}. If the 'emergdir'
# configuration parameter in ~/.mailagent is set to an existing directory, the
# first saving attempt is made there (each mail in a separate file).
sub emergency_save {
	return 0 unless (defined $cf'home);	# ~/.mailagent not processed
	return 1 if -d "$cf'emergdir" && &dump_mbox("$cf'emergdir/ma$$");
	return 1 if &dump_mbox(&mailbox_name);
	return 1 if &dump_mbox("$cf'home/mbox.urgent");
	return 1 if &dump_mbox("$cf'home/mbox.urg$$");
	return 1 if &dump_mbox("/usr/spool/uucppublic/mbox.$cf'user");
	return 1 if &dump_mbox("/var/spool/uucppublic/mbox.$cf'user");
	return 1 if &dump_mbox("/usr/tmp/mbox.$cf'user");
	return 1 if &dump_mbox("/var/tmp/mbox.$cf'user");
	return 1 if &dump_mbox("/tmp/mbox.$cf'user");
	&add_log("ERROR unable to save mail in any emergency mailbox") if $loglvl;
	0;
}

# Dump $Header{'All'} in emergency mailbox
sub dump_mbox {
	local($mbox) = shift(@_);
	local($ok) = 0;						# printing status
	local($existed) = 0;				# did the mailbox exist already ?
	local($old_size);					# Size the old mailbox had
	local($new_size);					# Size of the mailbox after saving
	local($should);						# Size it should have if saved properly
	$existed = 1 if -f $mbox;
	$old_size = $existed ? -s $mbox : 0;
	if (open(MBOX, ">>$mbox")) {
		(print MBOX $Header{'All'}) && ($ok = 1);
		print MBOX "\n";				# allow parsing by other mail tools
		close(MBOX) || ($ok = 0);
		$new_size = -s $mbox;			# Stat new mbox file, grab its size
		$should = $old_size +			# New ideal size is old size plus...
			length($Header{'All'}) +	# ... the length of the message saved
			1;							# ... the trailing new-line
		if ($should != $new_size) {
			&add_log("ERROR $mbox has $new_size bytes (should have $should)")
				if $loglvl;
			$ok = 0;					# Saving failed, sorry...
		}
		if ($ok) {
			&add_log("DUMPED in $mbox") if $loglvl > 5;
			return 1;
		} else {
			if ($existed) {
				&add_log("WARNING imcomplete mail appended to $mbox")
					if $loglvl > 5;
			} else {
				unlink "$mbox";			# remove incomplete file
			}
		}
	}
	0;
}

# Utility routine for resync() below: writes %waiting keys to opened file.
# The file is closed at the end of the operation.
# Returns true if OK.
sub write_waitkeys {
	local(*FILE, @extra) = @_;
	local($ok) = 1;					# Assume resync is ok
	local($_);
	foreach (keys %waiting) {
		if ($waiting{$_}) {
			(print FILE "$_\n") || ($ok = 0);
			unless ($ok) {
				&add_log("SYSERR write: $!") if $loglvl;
				last;
			}
		}
	}
	# Even if !$ok, try appending any extra file, in case it works
	foreach (@extra) {
		(print FILE "$_\n") || ($ok = 0);
		unless ($ok) {
			&add_log("SYSERR write: $!") if $loglvl;
			last;
		}
	}
	(print FILE "\n") || ($ok = 0);	# Trailing blank line
	close(FILE) || ($ok = 0);
	&add_log("SYSERR close: $!") if !$ok && $loglvl;
	return $ok;
}

# Resynchronizes the waiting file if necessary.
#
# In order to have the filesystem reserve at least a block, we systematically
# write an empty line at the end of the waiting file, to avoid it being
# empty. That way, even when the filesystem is otherwise full, there is some
# space reserved to store data.
sub resync {
	return if $cf'spool eq '';		# Agent wait is in spool directory
	&add_log("resynchronizing the waiting file") if $loglvl > 11;
	local *WAITING;
	local($ok) = 0;

	# We need to protect against concurrent accesses (by the C filter
	# or another mailagent), and also understand that those processes might
	# update the file WITHOUT locking. To guard as much as possible against
	# that, we read the file in and record keys that do not exist in our
	# own %waiting table.

	local($locked) = 0 == &acs_rqst($AGENT_WAIT);
	local(@extra) = ();

	&add_log("WARNING updating $AGENT_WAIT without lock")
		if !$locked && $loglvl > 5;

	open(WAITING, $AGENT_WAIT);
	local($_);
	while (<WAITING>) {
		chop;
		next unless length $_;
		push(@extra, $_) unless exists $waiting{$_};
	}
	close WAITING;

	local($amount) = 0 + @extra;
	local($s) = $amount == 1 ? '' : 's';
	&add_log("NOTICE found $amount unprocessed file$s in $AGENT_WAIT")
		if $amount && $loglvl > 6;

	# Try first to write a new copy of the file, and only rename it once
	# the copy has been written.

	if (open(WAITING, ">$AGENT_WAIT~")) {
		$ok = write_waitkeys(*WAITING, @extra);
		if (!$ok) {
			&add_log("ERROR could not update waiting file") if $loglvl;
			unlink "$AGENT_WAIT~";
		} elsif (rename("$AGENT_WAIT~", $AGENT_WAIT)) {
			&add_log("waiting file has been updated") if $loglvl > 18;
		} else {
			&add_log("ERROR cannot rename waiting file: $!") if $loglvl;
		}
	} else {
		&add_log("WARNING unable to write new waiting file: $!") if $loglvl > 5;
	}

	if ($ok || !-f $AGENT_WAIT) {
		&free_file($AGENT_WAIT) if $locked;
		return;
	}

	# If we could not create a new file, maybe the disk is full, or the write
	# permission bit on the file's directory was removed. Try to override
	# the existing file then.

	&add_log("NOTICE trying to write over existing $AGENT_WAIT") if $loglvl > 6;
	if (open(WAITING, ">$AGENT_WAIT")) {
		$ok = write_waitkeys(*WAITING, @extra);
		&add_log("ERROR mangled file $AGENT_WAIT") if !$ok && $loglvl;
	}

	&free_file($AGENT_WAIT) if $locked;
}

