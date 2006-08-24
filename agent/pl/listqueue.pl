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
;# $Log: listqueue.pl,v $
;# Revision 3.0.1.6  1999/07/12  13:51:28  ram
;# patch66: added one extra char for filename in queue listings
;#
;# Revision 3.0.1.5  1999/01/13  18:13:53  ram
;# patch64: there may be empty lines in the agent.wait file
;#
;# Revision 3.0.1.4  1997/09/15  15:15:40  ram
;# patch57: now clearly spot locked files in queue with a '*'
;#
;# Revision 3.0.1.3  1995/01/25  15:24:09  ram
;# patch27: avoid problems on slow machines in test mode for queue timestamps
;#
;# Revision 3.0.1.2  1994/09/22  14:26:00  ram
;# patch12: localized variables used by stat() and localtime()
;# patch12: now knows about callout queue messages
;#
;# Revision 3.0.1.1  1994/07/01  15:01:45  ram
;# patch8: now honours new queuehold and queuelost config variables
;#
;# Revision 3.0  1993/11/29  13:48:56  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# List the current mails held in the queue, if any at all.
# See also the pqueue subroutine for other comments about the queue.
sub list_queue {
	local(*DIR);
	unless (opendir(DIR, $cf'queue)) {
		&add_log("ERROR unable to open $cf'queue: $!");
		return;
	}
	local(@dir) = readdir DIR;		# Slurp the whole directory
	closedir DIR;
	local(@files) = grep(s!^(q|f|c)m!$cf'queue/${1}m! && !/$lockext$/o, @dir);
	undef @dir;
	if (-f $AGENT_WAIT) {
		if (open(WAITING, $AGENT_WAIT)) {
			while (<WAITING>) {
				chop;
				next unless length $_;	# Empty lines ignored
				push(@files, $_);
			}
			close WAITING;
		} else {
			&add_log("ERROR cannot open $AGENT_WAIT: $!") if $loglvl;
		}
	}
	# The @files array now contains the path name of all the queued mails
	# (at least those known to the mailagent).
	if (@files == 0) {
		print "Mailagent queue is empty.\n";
		return;
	}
	format STDOUT_TOP =
Filename      Size Queue time  Status    Sender / Recipient list
--------- -------- ----------- --------- --------------------------------------
.
	local($file);				# Base name of file (eventually stripped)
	local($directory);			# Directory where queued mail is stored
	local($queued);				# Queuing date
	local($status);				# Status of mail
	local($sender);				# Sender of mail
	local($star);				# The '*' identifies out of queue mails
	local($recipient);			# Recipient of mail
	local($buffer);				# Temporary buffer to build recipient list
	local($address);			# E-mail address candidate for recipient list
	local(%seen);				# Records addresses already seen
	$: = " ,";					# Break recipients on white space or colon
	format STDOUT =
@<<<<<<<<<@>>>>>>>@@<<<<<<<<<< @<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$file     $size $star $queued  $status   $sender
                                         ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                         $recipient
~                                        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                         $recipient
~                                        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                         $recipient
~                                        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                         $recipient
~                                        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                         $recipient
~                                        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
                                         $recipient
.
	local($n) = $#files + 1;
	local($s) = $n > 1 ? 's' : '';
	local($_);
	local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		$atime,$mtime,$ctime,$blksize,$blocks);
	local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

	print STDOUT "                   Mailagent Queue ($n request$s)\n";
	foreach (@files) {
		($directory, $file) = m|^(.*)/(.*)|;
		&parse_mail($_, 'head_only');
		next unless defined $Header{'All'};
		# Remove comments from all the addresses. The From field is used to
		# identify the (possibly forged) sender while the To and Cc fields
		# are concatenated to list the recipients;
		$sender = (&parse_address($Header{'From'}))[0];
		$buffer = $Header{'To'};
		$buffer .= ',' . $Header{'Cc'} if $Header{'Cc'};
		$recipient = '';
		undef %seen;
		while ($buffer =~ s/^(.*),(.*)/$1/) {
			$address = (&parse_address($2))[0];
			unless ($seen{$address}++) {
				$recipient .= ', ' if $recipient;
				$recipient .= $address;
			}
		}
		$address = (&parse_address($buffer))[0];
		unless ($seen{$address}++) {
			$recipient .= ', ' if $recipient;
			$recipient .= $address;
		}
		unless (-f $_) {
			&add_log("WARNING unable to stat $_");
			next;
		}
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			$atime,$mtime,$ctime,$blksize,$blocks) = stat(_);
		$status = '';

		# If file has 'mbox.' as part of its name, then it is an emergency
		# saving done by the mailagent. If it starts with 'logname', then it
		# is an emergency saving done by the filter.

		$file =~ s/^mbox\.// && ($status = 'Backup');
		$file =~ s/^$cf'user\.// && ($status = 'Backup');

		# Check for callout queue file. If it is a 'cm' file, or it is not in
		# the queue and is recorded in the callout queue, then it is marked
		# as a callout file and the queue time printed will be the trigger
		# time.

		if (
			$file =~ /^cm/ ||
			($directory ne $cf'queue && &callout'trigger($_))
		) {
			$mtime = &callout'trigger($_);	# May be called twice, that's ok.
			$status = 'Callout';
		} elsif ($file =~ /^qm/ && (time - $mtime) < $cf'queuehold) {
			# Queue mails starting with 'qm' have been queued by the filter
			# program. To avoid race conditions, those mails are skipped for
			# some time (cf to pqueue subroutine).
			$status = 'Skipped' unless $status;		# Filter queued mail
		} else {
			# Processing of mail allowed (mailagent -q would flush it)
			$status = 'Deferred' unless $status;
		}

		# Ensure we always print 'Now' for queue time in TEST mode
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
			localtime($mtime);
		$queued = sprintf("%.2d/%.2d-%.2d:%.2d", ++$mon,$mday,$hour,$min);
		$queued = 'Now' if &'abs(time - $mtime) < 60
			|| ($test_mode && $file !~ /^cm/);
		$star = '';
		$star = '*' if $directory ne $cf'queue;	# Spot out-of-queue mails
		if ($status ne 'Callout') {
			if ((time - $mtime) > $cf'queuelost) {	# Also spot old mails
				$star = '#';
				$star = '@' if $directory ne $cf'queue;
			}
		} elsif (time > $mtime) {	# Spot callouts that should have triggered
			$star = '#';
			$star = '@' if $directory ne $cf'queue;
		}

		$status .= '*' if -f ($_ . $lockext);	# Locked file

		write(STDOUT);
	}
}

