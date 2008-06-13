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
;# $Log: pqueue.pl,v $
;# Revision 3.0.1.3  1999/01/13  18:15:07  ram
;# patch64: there may be empty lines in the agent.wait file
;#
;# Revision 3.0.1.2  1997/09/15  15:16:53  ram
;# patch57: messages in the queue are now locked before processing
;# patch57: new pmail() routine to factorize locking/processing code
;#
;# Revision 3.0.1.1  1994/07/01  15:04:20  ram
;# patch8: now honours new queuehold config variable
;#
;# Revision 3.0  1993/11/29  13:49:09  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Process the queue
sub pqueue {
	local($length);						# Length of message, in bytes
	undef %waiting;						# Reset waiting array
	local(*DIR);						# File descriptor to list the queue
	unless (opendir(DIR, $cf'queue)) {
		&add_log("ERROR unable to open $cf'queue: $!") if $loglvl;
		return 0;						# No file processed
	}
	local(@dir) = readdir DIR;			# Slurp the all directory contents
	closedir DIR;

	# The qm files are put there by the filter and left in case of error
	# Only files older than 30 minutes are re-parsed (because otherwise it
	# might have just been queued by the filter). The fm files are normal
	# queued file which may be processed immediately.

	# Prefix each file name with the queue directory path
	local(@files) = grep(s|^fm|$cf'queue/fm| && !/$lockext$/o, @dir);
	local(@filter_files) = grep(s|^qm|$cf'queue/qm| && !/$lockext$/o, @dir);
	undef @dir;							# Directory listing not need any longer

	foreach $file (@filter_files) {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
		if ((time - $mtime) > $cf'queuehold) {
			# More than queue timeout -- there must have been a failure
			push(@files, $file);		# Add file to the to-be-parsed list
		}
	}

	# In $AGENT_WAIT are stored the names of the mails outside the queue
	# directory, waiting to be processed. Empty lines (one being added by
	# &resync systematically) are skipped.
	if (-f $AGENT_WAIT) {
		local(*WAITING);
		local($_);
		if (open(WAITING, $AGENT_WAIT)) {
			while (<WAITING>) {
				chop;
				next unless length $_;	# Ignore empty lines
				push(@files, $_);		# Process this file too
				$waiting{$_} = 1;		# Record it comes from waiting file
			}
			close WAITING;
		} else {
			&add_log("ERROR cannot open $AGENT_WAIT: $!") if $loglvl;
		}
	}
	return 0 unless $#files >= 0;

	&add_log("processing the whole queue") if $loglvl > 11;
	$processed = 0;
	foreach $file (@files) {
		&add_log("dealing with $file") if $loglvl > 19;
		$file_name = $file;
		if ($waiting{$file} && ! -f $file) {
			# We may have already processed this file without having resynced
			# AGENT_WAIT or the file has been removed.
			&add_log ("WARNING could not find $file") if $loglvl > 4;
			$waiting{$file} = 0;	# Mark it as processed
			next;					# And skip it
		}
		local($ret) = &pmail($file, 1);
		if ($ret == 0) {
			++$processed;
			$waiting{$file} = 0 if $waiting{$file};
		} elsif ($ret != -1) {		# Not an error if mail was locked
			$file =~ s|.*/(.*)|$1|;	# Keep only basename
			&add_log("ERROR leaving [$file] in queue") if $loglvl > 0;
			unlink $lockfile;
			&resync;				# Resynchronize waiting file
			exit 0;					# Do not continue now
		}
	}
	if ($processed == 0) {
		&add_log("NOTICE was unable to process queue") if $loglvl > 5;
	}
	&resync;			# Resynchronize waiting file
	$processed;			# Return the number of files processed
}

# Process a single mail
sub pmail {
	local($filename, $can_unlink) = @_;
	local($file) = $filename;
	$file =~ s|.*/(.*)|$1|;	# Keep only basename
	$file = '<stdin>' if $file eq '';

	# If not dealing with stdin... lock the file to ensure only one
	# mailagent deals with it.
	unless ($file eq '<stdin>') {
		local($try) = &acs_locktry($filename);
		if ($try != 0) {
			local($reason) = $try == 1 ? "already locked" : "cannot lock it";
			&add_log("WARNING skipping $filename ($reason)") if $loglvl > 4;
			return -1;	# Failed for locking reasons
		} else {
			&add_log("locked $filename") if $loglvl > 17;
		}
	}

	local($result) = &analyze_mail($filename);		# Analyze & filter message
	
	if ($result == 0) {
		local($len) = $Header{'Length'};
		my $msize = mail_logsize($filename);
		&add_log("FILTERED [$file]$msize ($len bytes)") if $loglvl > 4;
	}

	# If message was not from stdin and was processed successfully, unlink it
	unless ($file eq '<stdin>') {
		if ($result == 0 && $can_unlink && !unlink($filename)) {
			&add_log("SYSERR unlink: $!") if $loglvl;
			&add_log("ERROR unable to unlink $filename") if $loglvl;
		}
		if (0 == &free_file($filename)) {
			&add_log("unlocked $filename") if $loglvl > 17;
		} else {
			&add_log("ERROR cannot unlock $filename") if $loglvl;
		}
	}

	return $result;		# 0 if OK, 1 for analyze errors
}

