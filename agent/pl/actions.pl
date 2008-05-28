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
;# $Log: actions.pl,v $
;# Revision 3.0.1.21  2001/03/17 18:10:47  ram
;# patch72: use the "email" config var verbatim in FORWARD
;# patch72: removed unused var in POST
;#
;# Revision 3.0.1.20  2001/03/13 13:13:15  ram
;# patch71: made fixup of header fields in POST be a warning
;# patch71: fixed RESYNC, copied continuation fix from parse_mail()
;# patch71: added support for SUBST/TR on mail headers
;#
;# Revision 3.0.1.19  2001/01/10 16:52:58  ram
;# patch69: replaced calls to fake_date() by mta_date()
;# patch69: rewrote the POST command, and added the -b switch
;#
;# Revision 3.0.1.18  1999/07/12  13:49:01  ram
;# patch66: use servshell instead of /bin/sh for commands
;# patch66: make sure that we do not get an empty header when filtering
;#
;# Revision 3.0.1.17  1999/01/13  18:12:18  ram
;# patch64: only use last two digits from year in logfiles
;#
;# Revision 3.0.1.16  1997/09/15  15:10:53  ram
;# patch57: don't blindly chop command error message, remove trailing \n
;# patch57: annotation was not performed for value "0"
;#
;# Revision 3.0.1.15  1997/02/20  11:42:06  ram
;# patch55: made 'perl -cw' clean and fixed a couple of typos
;#
;# Revision 3.0.1.14  1997/01/07  18:31:14  ram
;# patch52: allow for @SH help to be understood, whatever the case
;#
;# Revision 3.0.1.13  1996/12/24  14:46:16  ram
;# patch45: now reads 'help' as 'mailhelp' in command messages
;# patch45: locate and perform security checks on launched executables
;#
;# Revision 3.0.1.12  1995/09/15  14:01:17  ram
;# patch43: now escapes shell metacharacters for popen() on FORWARD and BOUNCE
;# patch43: will now make a note when delivering to an unlocked folder
;# patch43: saving will fail if mbox_lock returns an undefined value
;#
;# Revision 3.0.1.11  1995/08/07  16:16:44  ram
;# patch37: now use env::biff instead of cf:biff for dynamic configuration
;# patch37: added protection around &interface::reset calls for perl5
;#
;# Revision 3.0.1.10  1995/02/16  14:32:26  ram
;# patch32: now uses new header_append and header_prepend routines
;#
;# Revision 3.0.1.9  1995/02/03  17:58:11  ram
;# patch30: was wrongly biffing when delivering to a mail hook
;# patch30: avoid perl core dumps in &perl by localizing @_ on entry
;#
;# Revision 3.0.1.8  1995/01/25  15:19:45  ram
;# patch27: added support for NFS bug on remote read-only folders
;# patch27: destination address for PROCESS is now parsed correctly
;# patch27: added support for folder mode change, as defined by PROTECT
;#
;# Revision 3.0.1.7  1995/01/03  18:04:55  ram
;# patch24: removed a here-doc string to workaround a bug in perl 4.0 PL36
;# patch24: simplified action codes to use new opt'sw_xxx option vars
;# patch24: &execute_command no longer sleeps before resuming parent process
;#
;# Revision 3.0.1.6  1994/10/29  17:45:01  ram
;# patch20: added biffing support in &save
;#
;# Revision 3.0.1.5  1994/10/04  17:46:37  ram
;# patch17: now uses the email config parameter to send messages to user
;# patch17: new routine &trace_dump to dump messages in ~/agent.trace
;# patch17: PROCESS now ensures the return address is not hostile
;# patch17: shell commands receiving SIGPIPE now always mail trace back
;#
;# Revision 3.0.1.4  1994/09/22  14:07:26  ram
;# patch12: now updates new variable folder_saved with folder path
;# patch12: added various escapes in strings for perl5 support
;# patch12: create ~/agent.trace if unable to mail command trace back
;# patch12: interface change for &qmail allows for better log messages
;# patch12: implements new AFTER and DO filtering commands
;#
;# Revision 3.0.1.3  1994/07/01  14:57:49  ram
;# patch8: timeout for RUN commands now defined by runmax config variable
;# patch8: now systematically escape leading From if fromall is ON
;#
;# Revision 3.0.1.2  1994/04/25  15:16:53  ram
;# patch7: here and there fixes
;# patch7: global fix for From line escapes to make them configurable
;#
;# Revision 3.0.1.1  1994/01/26  09:30:03  ram
;# patch5: restored ability to use Cc: and Bcc: in message files
;#
;# Revision 3.0  1993/11/29  13:48:33  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Implementation of filtering commands
#

# The "LEAVE" command
# Leave a copy of the message in the mailbox. Returns (mbox, failed_status)
sub leave {
	local($mailbox) = &mailbox_name;	# Incomming mailbox filename
	&add_log("starting LEAVE") if $loglvl > 15;
	&save($mailbox);					# Propagate return status
}

# The "SAVE" command
# Save a message in a folder. Returns (mbox, failed_status). If the folder
# already exists and has the 'x' bit set, then is is understood as an external
# hook and mailhook is invoked. If the folder name begins with '+', it is
# handled as an MH folder. If the folder is actually a directory, then message
# is saved in an individual file, much like an MH folder.
sub save {
	local($mailbox) = @_;			# Where mail should be saved
	local($failed) = 0;				# Printing status
	if ($mailbox eq '') {			# Empty mailbox (e.g. SAVE %1 with no match)
		$mailbox = &mailbox_name;
		&add_log("WARNING empty folder name, using $mailbox") if $loglvl > 5;
	}
	local($biffing) = $env'biff =~ /ON/i;	# Whether we should biff or not
	local($type) = 'file';					# Folder type, for biffing macros
	&add_log("starting SAVE $mailbox") if $loglvl > 15;
	if ($mailbox =~ s/^\+//) {		# MH folder?
		$type = 'MH';
		$failed = &mh'save($mailbox);
	} elsif (-d $mailbox) {			# A directory hook
		$failed = &mh'savedir($mailbox);
		$type = 'dir';
	} elsif (-x $mailbox) {			# Folder hook
		$failed = &save_hook;		# Deliver to program
		$biffing = 0;				# No biffing for hooks
	} else {						# Saving to a normal folder
		# Uncompress folders if necessary. The restore routine will perform
		# the necessary checks and return immediately if no compression is
		# wanted for that particular folder. However, we can avoid the overhead
		# of calling this routine (and loading it when using dataloading) if
		# the 'compress' configuration parameter is missing.
		&compress'restore($mailbox) if $cf'compress;
		$failed = &save_folder($mailbox);
	}
	&add_log("ERROR could not save mail in $mailbox") if $failed && $loglvl;
	&emergency_save if $failed;

	# At this point, folder_saved has been updated to the path of the folder
	# where message has been saved, unless it was a hook but in that case we
	# do not biff anyway.
	&biff($folder_saved, $type) if $biffing && !$failed;

	($mailbox, $failed);			# Where save was made and failure status
}

# Called by &save when folder is a regular one (i.e. not a hook).
sub save_folder {
	local($mailbox) = @_;			# Where mail should be saved
	local($amount);					# Amount of bytes written
	local($failed);
	# Explicitely check for writable mailbox. I've seen an NFS between a SUN
	# and a file on DEC OSF/1 accept appending while file was read-only...
	# We may only perform the open if the file does not exist or is writable.
	local($exist) = -e $mailbox;	# Run chmod if PROTECT used and created
	local($mayopen) = !$exist || -w _;
	if ($mayopen && open(MBOX, ">>$mailbox")) {

		local($ret) = &mbox_lock($mailbox);	# Lock mailbox, get exclusive access
		return 1 unless defined $ret;		# Unable to lock, fail miserably
		local($size) = -s $mailbox;			# Initial mailbox size

		# It's still possible we did not get any lock on the mailbox, or just
		# a partial lock, but the user did tell us that was ok, via the
		# 'locksafe' variable setting. Simply emit a notice that we're
		# delivering without locking.
		
		&add_log("NOTICE saving to non-locked $mailbox")
			if !$ret && $loglvl > 6;

		# If MMDF-style mailboxes are allowed, then the saving routine will
		# try to determine what kind of folder it is delivering to and choose
		# the right format. Otherwise, standard Unix format is assumed.

		if ($cf'mmdf =~ /on/i) {	# MMDF-style allowed
			# Save to mailbox, selecting the right format (UNIX vs MMDF)
			($failed, $amount) = &mmdf'save(*MBOX, $mailbox);
		} else {
			# Save to UNIX folder
			($failed, $amount) = &mmdf'save_unix(*MBOX);
		}

		# Because we might write over NFS, and because we might have had to
		# force fate to get a lock, it is wise to make sure the folder has the
		# right size, which would tend to indicate the mail made it to the
		# buffer cache, if not to the disk itself.
		local($should) = $size + $amount;	# Computed new size for mailbox
		local($new_size) = -s $mailbox;		# Last write was flushed to disk
		&add_log("ERROR $mailbox has $new_size bytes (should have $should)")
			if $new_size != $should && $loglvl;
		$failed = 1 if $new_size != $should;

		# Finally, release the lock on the mailbox and close the file. If the
		# closing operation fails for whatever reason, the routine will return
		# a 1, so $failed will be set. Of course, "normally" it should not
		# fail at that point, since the mail was previously flushed.
		$failed |= &mbox_unlock($mailbox);	# Will close file

		# Now adjust permissions on the file, if created and PROTECT was used.
		&mmdf'chmod($env'protect, $mailbox) if !$exist && defined $env'protect;

	} else {
		local($msg) = $mayopen ? "$!" : 'Permission denied';
		&add_log("SYSERR open: $msg") if $loglvl;
		if (-f "$mailbox") {
			&add_log("ERROR cannot append to $mailbox") if $loglvl;
		} else {
			&add_log("ERROR cannot create $mailbox") if $loglvl;
		}
		$failed = 1;
	}
	$folder_saved = $mailbox;	# Keep track of last folder we save into
	$failed;					# Propagate failure status
}

# Called by &save when folder is a hook.
# Note that as opposed to other folder saving routines, we do not update the
# $folder_saved variable when saving into a hook. This is because the hook
# might be another set of filtering rules or a perl escape taking care of its
# own saving, in which case we do not want to corrupt the saved location.
# Return command failure status.
sub save_hook {
	local($failed) = &hook'process($mailbox);
	&add_log("HOOKED [$mfile]") if !$failed && $loglvl > 2;
	$failed;				# Propagate failure status
}

# The "PROCESS" command
# The body of the message is expected to be in $Header{'Body'}
sub process {
	local($subj) =			$Header{'Subject'};
	local($msg_id) =		$Header{'Message-Id'};
	local($sender) =		$Header{'Reply-To'};
	local($to) =			$Header{'To'};
	local($bad) = "";		# No bad commands
	local($pack) = "auto";	# Default packing mode for sending files
	local($ncmd) = 0;		# Number of valid commands we have found
	local($dest) = "";		# Destination (where to send answers)
	local(@cmd);			# Array of all commands
	local(%packmode);		# Records pack mode for each command
	local($error) = 0;		# Error report code
	local(@body);			# Body of message

	&add_log("starting PROCESS") if $loglvl > 15;

	# If no @PATH directive was found, use $sender as a return path
	$dest = $Userpath;				# Set by an @PATH
	$dest = $sender unless $dest;
	# Remove the <> if any (e.g. path derived from Return-Path)
	$dest = (&parse_address($dest))[0];

	# Debugging purposes
	&add_log("\@PATH was '$Userpath' and sender was '$sender'")
		if $loglvl > 18;
	&add_log("computed destination: $dest") if $loglvl > 15;

	# Make sure address is not hostile. Since a transcript is sent to the
	# sender computed in $dest, we cannot inform the user if the address
	# turns out to be really hostile.

	unless (&addr'valid($dest)) {
		&add_log("ERROR $dest is an hostile sender address") if $loglvl > 1;
		&add_log("NOTICE discarding whole command mail") if $loglvl > 6;
		return 0;	# An error would requeue message
	}

	# Copy body of message in an array, one line per entry
	@body = split(/\n/, $Header{'Body'});

	# The command file contains the authorized commands
	if ($#command < 0) {			# Command file not processed yet
		open(COMMAND, "$cf'comfile") || &fatal("No command file!");
		while (<COMMAND>) {
			chop;
			$command{$_} = 1;
		}
		close(COMMAND);
	}

	line: foreach (@body) {
		# Built-in commands
		if (/^\@PACK\s*(.*)/) {		# Pack mode
			$pack = $1 if $1 ne '';
			$pack = "" if ($pack =~ /[=$^&*([{}`\\|;><?]/);
		}
		s/^[ \t]\@SH/\@SH/;	# allow one blank only
		if (/^\@SH/) {
			s/\\!/!/g;		# if uucp address, un-escape `!'
			if (/[=\$^&*([{}`\\|;><?]/) {
				s/^\@SH/bad command:/;	# space after ":" will be added
				$bad .= $_ . "\n";
				next line;
			}
			# Some useful substitutions
			s/\@SH[ \t]*//;				# Allow leading blanks
			s/ PATH/ $dest/; 			# PATH is a macro
			s/^mial(\w*)/mail$1/;		# Common mis-spellings
			s/^mailpath/mailpatch/;
			s/^mailist/maillist/;
			s/^help/mailhelp/i;
			# Now fetch command's name (first symbol)
			if (/^([^ \t]+)[ \t]/) {
				$first = $1;
			} else {
				$first = $_;
			}
			if (!$command{$first}) {	# if un-authorized cmd
				s/^/unknown cmd: /;		# needs a space after ":"
				$bad .= $_ . "\n";
				next line;
			}
			$packmode{$_} = $pack;		# packing mode for this command
			push(@cmd, $_);				# record command
		}
	}

	# ************* Check with authoritative file ****************

	# Do not continue if an error occurred, in which case the mail will remain
	# in the queue and will be processed later on.
	return $error if $error || $dest eq '';

	# Now we are sure the mail we proceed is for us
	$sender = "<someone>" if $sender eq '';
	$ncmd = $#cmd + 1;
	if ($ncmd > 1) {
		&add_log("$ncmd commands for $sender") if $loglvl > 11;
	} elsif ($ncmd == 1) {
		&add_log("1 command for $sender") if $loglvl > 11;
	} else {
		&add_log("no command for $sender") if $loglvl > 11;
	}
	foreach $fullcmd (@cmd) {
		$cmdfile = "/tmp/mess.cmd$$";
		open(CMD,">$cmdfile");
		# For our children
		print CMD "jobnum=$jobnum export jobnum\n";
		print CMD "fullcmd=\"$fullcmd\" export fullcmd\n";
		print CMD "pack=\"$packmode{$fullcmd}\" export pack\n";
		print CMD "path=\"$dest\" export path\n";
		print CMD "sender=\"$sender\" export sender\n";
		print CMD "set -x\n";
		print CMD "$fullcmd\n";
		close CMD;
		$fullcmd =~ /^[ \t]*(\w+)/;		# extract first word
		$cmdname = $1;		# this is the command name
		$trace = "$cf'tmpdir/trace.cmd$$";

		# For HPUX-10.x, grrr... have to use our own shell otherwise that
		# silly posix /bin/sh dumps core when fed the $cmdfile we built above.
		local($shell) = &cmdserv'servshell;

		$pid = fork;						# We fork here
		$pid = -1 unless defined $pid;

		if ($pid == 0) {
			open(STDOUT, ">$trace");		# Where output goes
			open(STDERR, ">&STDOUT");		# Make it follow pipe
			exec $shell, "$cmdfile";		# Don't use sh -c
		} elsif ($pid == -1) {
			# Set the error report code, and the mail will remain in queue
			# for later processing. Any @RR in the message will be re-executed
			# but it is not really important. In fact, this is going to be
			# a feature, not a bug--RAM.
			$error = 1;
			&add_log("ERROR cannot fork: $!") if $loglvl > 0;
			unless (open(MAILER,"|$cf'sendmail $cf'mailopt $dest $cf'email")) {
				&add_log("SYSERR fork: $!") if $loglvl;
				&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
			}
			print MAILER <<EOM;
To: $dest
Subject: $cmdname not executed
$MAILER

Your command was: $fullcmd

It was not executed because I could not fork. Sigh !
(Kernel report: $!)

The command has been left in a queue and will be processed again
as soon as possible, so it is useless to resend it.

-- mailagent speaking for $cf'user
EOM
			close MAILER;
			if ($?) {
				&add_log("ERROR cannot report failure") if $loglvl;
			}
			return $error;		# Abort processing now--mail remains in queue
		} else {
			wait();
			if ($?) {
				unless (
					open(MAILER,"|$cf'sendmail $cf'mailopt $dest $cf'email")
				) {
					&add_log("SYSERR fork: $!") if $loglvl;
					&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
				}
				print MAILER <<EOM;
To: $dest
Subject: $cmdname returned a non-zero status
$MAILER

Your command was: $fullcmd
It produced the following output and failed:

EOM
				if (open(TRACE, $trace)) {
					while (<TRACE>) {
						print MAILER;
					}
					close TRACE;
				} else {
					print MAILER "** SORRY - NOT AVAILABLE **\n";
					&add_log("ERROR cannot dump trace") if $loglvl;
				}
				print MAILER "\n-- mailagent speaking for $cf'user\n";
				close MAILER;
				if ($?) {
					&add_log("ERROR cannot report failure") if $loglvl;
					&trace_dump($trace, "failed $fullcmd");
				}
				&add_log("FAILED $fullcmd") if $loglvl > 1;
			} else {
				&add_log("OK $fullcmd") if $loglvl > 5;
			}
		}
		unlink $cmdfile, $trace;
	}

	if ($bad) {
		unless (open(MAILER,"|$cf'sendmail $cf'mailopt $dest $cf'email")) {
			&add_log("SYSERR fork: $!") if $loglvl;
			&add_log("ERROR cannot launch $cf'sendmail") if $loglvl;
		}
		chop($bad);			# Remove trailing new-line
		# For unknown reasons, perl 4.0 PL36 chokes here when a here-document
		# syntax is used. Although it compiles fine, no output seems to be
		# sent on the MAILER descriptor. Use a string then... That's funny
		# though becase here-document syntax is used elsewhere without problems.
		print MAILER
"To: $dest
Subject: the following commands were not executed
$MAILER

$bad

If $cf'name can figure out what you wanted, he may do it anyway.

-- mailagent speaking for $cf'user
";
		close MAILER;
		if ($?) {
			&add_log("ERROR unable to mail back bad commands from $sender")
				if $loglvl;
		}
		&add_log("bad commands from $sender") if $loglvl > 5;
	}

	&add_log("all done for $sender") if $loglvl > 11;
	$error;		# Return error report (0 for ok)
}

# The "MACRO" command
sub macro {
	local($args) = @_;				# name = (value, type)
	local($replace) = $opt'sw_r;	# Replace existing macro
	local($delete) = $opt'sw_d;		# Delete macro
	local($pop) = $opt'sw_p;		# Pop macro
	local($name);					# Macro's name
	if ($delete || $pop) {			# Macro is to be deleted or popped
		($name) = $args =~ /(\S+)/;	# Get first "word"
		&usrmac'pop($name) if $pop;	# Pop last value, delete if last
		&usrmac'delete($name) if $delete;
		return ($name, $pop ? 'popped' : 'deleted');	# Propagate action
	}
	# There are two formats for the macro command. The first format uses the
	# 'name = (val, type)' template and can be used to specify any kind of
	# macro (see usrmac.pl). The other form is name ..., where ... is any
	# kind of string --including spaces-- which will be used as a SCALAR
	# value. Of course, that string cannot take the '= (val, type)' format.
	local($val);					# Macro's value
	local($type) = 'SCALAR';		# Assume scalar type
	if ($args =~ /(\S+)\s*=\s*\(\s*(.*),\s*(\w+)\s*\)\s*/) {
		($name, $val, $type) = ($1, $2, $3);
	} else {
		($name, $val) = $args =~ /(\S+)\s+(.*)/;	# SCALAR type assumed
	}
	&usrmac'new($name, $val, $type) if $replace;
	&usrmac'push($name, $val, $type) unless $replace;
	($name, $replace ? 'replaced' : 'pushed');		# Propagate action
}

# The "MESSAGE" command
sub message {
	local($msg) = @_;			# Vacation message to be sent back
	local(@head) = (
		"To: %r (%N)",
		"Subject: Re: %R"
	);
	local($to) = '%r';				# Recipient is macro %r
	&macros_subst(*to);				# Evaluate it so we can give it to mailer
	&send_message($msg, *head, $to);
}

# The "NOTIFY" command
sub notify {
	local($msg, $address) = @_;
	# Any address included withing "" means addresses are stored in a file
	$address = &complete_list($address, 'address');
	$address =~ s/%/%%/g;	# Protect all '%' (subject to macro substitution)
	local($to) = $address;	# For the To: line...
	$to =~ s/\s+/, /g;		# Addresses separated by ',' on the To: line
	local(@head) = (
		"To: $to",
		"Subject: %s (notification)"
	);
	&send_message($msg, *head, $address);
}

# Send a given message to somebody, as specified in the given header
# The message and the header are subject to macro substitution.
# Usually, when using sendmail, the -t option could be used to parse header
# and obtain the recipients. However, the mailer being configurable, we cannot
# assume it will understand -t. Therefore, the recipients must be specified.
sub send_message {
	local($msg, *header, $recipients) = @_;	# Message to send, header, where
	unless (-f "$msg") {
		&add_log("ERROR cannot find message $msg") if $loglvl > 0;
		return 1;
	}
	unless (open(MSG, "$msg")) {
		&add_log("ERROR cannot open message $msg") if $loglvl > 0;
		return 1;
	}

	# Construction of value for the %T macro
	local($macro_T);			# Default value of macro %T is overwritten
	local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime, $mtime,
		$ctime,$blksize,$blocks) = stat($msg);
	local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
			localtime($mtime);
	local($this_year) = (localtime(time))[5];
	# Do not put the year in %T if it is the same as the current one.
	++$mon;						# Month in the range 1-12
	if ($this_year != $year) {
		$macro_T = sprintf("%.2d/%.2d/%.2d", $year % 100, $mon, $mday);
	} else {
		$macro_T = sprintf("%.2d/%.2d", $mon, $mday);
	}

	# Header construction. If the file contains a header at the top, it is
	# added to the one we already have by default. Identical fields are
	# overwritten with the one found in the file.
	# BUG: Multiple line headers are incorrectly overridden by the grep()
	# below: only the first line is taken into account!
	if (&header_found($msg)) {	# Top of message is a header
		local(@newhead);		# New header is constructed here
		local($cc) = '';		# Carbon copy recipients
		local($collect) = 0;	# True when collecting recipients
		local($field);
		local($_);
		while (<MSG>) {			# Read the header then
			last if /^$/;		# End of header
			chop;
			push(@newhead, $_);
			if (/^([\w\-]+):(.*)/) {
				$field = $1;
				$_ = $2;
				@head = grep(!/^$field:/, @head);	# Field is overwritten

				# The following used to be done directly by sendmail -t.
				# However, mailagent does not make use of that option any
				# longer since $cf'sendmail might not be sendmail and the
				# mailer used might therefore not understand this -t option.

				$collect = ($field =~ /^b?cc$/i);
				$cc .= &macros_subst(*_) if $collect;
			} else {
				$cc .= &macros_subst(*_) if $collect;	# Continuation lines
			}
		}
		foreach (@newhead) {
			push(@head, $_);
		}

		# Now update the recipient line by parsing $cc and extracting the
		# e-mail addresses, discarding the comments. Note that this code
		# will fail if ',' is used in address comments.

		local(@addr) = split(/,/, $cc);
		foreach $addr (@addr) {
			$recipients .= ' ' . (&parse_address($addr))[0];
		}
	}

	# Remove duplicate e-mail addresses in the recipient list. Again,
	# mailagent used to rely on sendmail to do this, but we can't assume
	# any user-defined mailer will do it.
	local(%seen);
	foreach $addr (split(' ', $recipients)) {
		$seen{$addr}++;
	}
	$recipients = join(' ', sort keys %seen);
	undef %seen;

	unless (open(MAILER,"|$cf'sendmail $cf'mailopt $recipients")) {
		&add_log("ERROR cannot run $cf'sendmail to send message: $!")
			if $loglvl;
		close MSG;
		return 1;
	}

	push(@head, $FILTER);		# Avoid loops: replying to ourselves or whatever
	foreach $line (@head) {
		&macros_subst(*line);	# In-place macro substitutions
		print MAILER "$line\n";	# Write header
	}
	print MAILER "\n";			# Header separated from body
	# Now write the body
	local($tmp);				# Because of a bug in perl 4.0 PL19
	while (defined ($tmp = <MSG>)) {
		next if $tmp =~ /^$/ && $. == 1;	# Escape sequence to protect header
		&macros_subst(*tmp);		# In-place macro substitutions
		print MAILER $tmp;			# Write message line
	}

	# Close pipe and check status
	close MSG;
	close MAILER;
	local($status) = $?;
	unless ($status) {
		if ($loglvl > 2) {
			local($dest) = $head[0];	# The To: header line
			($dest) = $dest =~ m|^To:\s+(.*)|;
			&add_log("SENT message to $dest");
		}
	} else {
		&add_log("ERROR could not mail back $msg") if $loglvl > 1;
	}
	$status;		# 0 for success
}

# The "FORWARD" command
sub forward {
	local($addresses) = @_;			# Address(es) mail should be forwarded to
	local($address) = $cf'email;	# Address of user
	# Any address included withing "" is in fact a file name where actual
	# forwarding addresses are found.
	$addresses =
		&complete_list($addresses, 'address');	# Process "include-requests"
	local($saddr);					# Address list for shell command
	($saddr = $addresses) =~ s/([()'"<>$;])/\\$1/g;
	unless (open(MAILER,"|$cf'sendmail $cf'mailopt $saddr")) {
		&add_log("ERROR cannot run $cf'sendmail to forward message: $!")
			if $loglvl;
		return 1;
	}
	local(@addr) = split(' ', $addresses);
	print MAILER &header'format("Resent-From: $address"), "\n";
	local($to) = "Resent-To: " . join(', ', @addr);
	print MAILER &header'format($to), "\n";
	# Protect Sender: and Resent-: lines in the original message
	foreach (split(/\n/, $Header{'Head'})) {
		next if /^From\s+(\S+)/;
		s/^Sender:\s*(.*)/Prev-Sender: $1/;
		s/^Resent-([\w\-]+):\s*(.*)/Prev-Resent-$1: $2/;
		print MAILER $_, "\n";
	}
	print MAILER $FILTER, "\n";
	print MAILER "\n";
	print MAILER $Header{'Body'};
	close MAILER;
	local($failed) = $?;		# Status of forwarding
	if ($failed) {
		&add_log("ERROR could not forward to $addresses") if $loglvl > 1;
	}
	$failed;		# 0 for success
}

# The "BOUNCE" command
sub bounce {
	local($addresses) = @_;			# Address(es) mail should be bounced to
	# Any address included withing "" is in fact a file name where actual
	# bouncing addresses are found.
	$addresses =
		&complete_list($addresses, 'address');	# Process "include-requests"
	local($saddr);					# Address list for shell command
	($saddr = $addresses) =~ s/([()'"<>$;])/\\$1/g;
	unless (open(MAILER,"|$cf'sendmail $cf'mailopt $saddr")) {
		&add_log("ERROR cannot run $cf'sendmail to bounce message: $!")
			if $loglvl;
		return 1;
	}
	# Protect Sender: lines in the original message
	foreach (split(/\n/, $Header{'Head'})) {
		next if /^From\s+(\S+)/;
		s/^Sender:\s*(.*)/Prev-Sender: $1/;
		print MAILER $_, "\n";
	}
	print MAILER $FILTER, "\n";
	print MAILER "\n";
	print MAILER $Header{'Body'};
	close MAILER;
	local($failed) = $?;		# Status of forwarding
	if ($failed) {
		&add_log("ERROR could not bounce to $addresses") if $loglvl > 1;
	}
	$failed;		# 0 for success
}

# The "POST" command
sub post {
	local($newsgroups) = @_;		# Newsgroup(s) mail should be posted to
	local($localdist) = $opt'sw_l;	# Local distribution if POST -l
	local($wantbiff) = $opt'sw_b;	# Biffing activated upon success
	unless (open(NEWS,"|$cf'sendnews $cf'newsopt -h")) {
		&add_log("ERROR cannot run $cf'sendnews to post message: $!")
			if $loglvl;
		return 1;
	}
	&add_log("distribution of posting is local")
		if $loglvl > 18 && $localdist;

	# The From: header we're generating in the news is correctly formatted
	# and escaped, to avoid rejects by the news server.
	# We'll let any Reply-To header through, since RFC-1036 defines them
	# for this purpose (i.e. the same as for mail), but we don't reformat
	# the Reply-To since it's not a required header.
	my ($faddr, $fcom) = &parse_address($Header{'From'});
	$fcom = '"' . $fcom . '"' if $fcom =~ /[@.\(\)<>,:!\/=;]/;
	if ($fcom ne '') {
		print NEWS "From: $fcom <$faddr>\n";	# One line
	} else {
		print NEWS "From: $faddr\n";
	}

	# The Date: field must be parseable by INN, and not be in the future
	# or the article would be rejected.  Articles too far in the past (outside
	# the history range) are also rejected, but we don't know what is
	# configured.  As a precaution, dates older than 14 days (the default INN
	# setting) are patched.
	unless (defined $Header{'Date'} && $Header{'Date'} ne '') {
		&add_log("WARNING no Date, faking one") if $loglvl > 5;
		my $date = &header'mta_date();
		print NEWS "Date: $date\n";
	} else {
		my $str = $Header{'Date'};
		my $when = &header'parsedate($str);
		my $now = time;
		my $date;
		my $AGEMAX = 10 * 86400;		# 10 days
		my $THRESH = 86400;				# 1 day
		my $WARN_THRESH = 600;			# 10 minutes
		if ($when < 0) {
			&add_log("WARNING can't parse Date field '$str', adjusting")
				if $loglvl > 5;
			$date = &header'mta_date($now);
		} elsif ($when > $now) {
			my $rel = &relative_age($when - $now);
			my $adjusting = '';
			my $stamp = $when;
			my $delta = $when - $now;
			if ($delta >= $THRESH) {	# More than a day, adjust!
				$stamp = $now;
				$adjusting = ", adjusting";
			}
			&add_log("WARNING Date field is $rel in the future$adjusting")
				if $loglvl > 5 && $delta >= $WARN_THRESH;
			$date = &header'mta_date($stamp);
		} elsif (($now - $when) >= $AGEMAX) {
			my $rel = &relative_age($now - $when);
			&add_log("WARNING Date field too ancient ($rel), adjusting")
				if $loglvl > 5;
			$date = &header'mta_date($now - $AGEMAX + 3600);
		} else {
			$date = &header'mta_date($when);	# Regenerate properly
		}
		print NEWS "Date: $date\n";
		print NEWS "X-Orig-Date: $str\n" if lc($date) ne lc($str);
	}

	# If no Subject is present, fake one to make inews happy
	unless (defined($Header{'Subject'}) && $Header{'Subject'} ne '') {
		&add_log("WARNING no Subject, faking one") if $loglvl > 5;
		print NEWS "Subject: <none>\n";
	} else {
		my $subject = $Header{'Subject'};
		$subject =~ tr/\n/ /;				# Multiples instances collapsed
		print NEWS "Subject: $subject\n";
	}

	# If no proper Message-ID is present, generate one
	# If one is present, perform sanity fixups because INN is really picky
	my $msgid;
	unless (defined($Header{'Message-Id'}) && $Header{'Message-Id'} ne '') {
		&add_log("WARNING no Message-Id, faking one") if $loglvl > 5;
		$msgid = &gen_message_id;
	} else {
		($msgid) = $Header{'Message-Id'} =~ /(<[^>]+@[^>]+>)/;
		if ($msgid ne '') {
			# Fixups are always the same, therefore they don't prevent proper
			# duplicate detection provided all feeds are done from mailagent
			# But we also need to fix places using those message IDs, i.e.
			# the References line, to preserve correct threading (see below).
			my $fixup = &header'msgid_cleanup(\$msgid);
			&add_log("WARNING fixed Message-Id line for news")
				if $loglvl > 5 && $fixup;
		} else {
			&add_log("WARNING bad Message-Id line, faking one") if $loglvl > 5;
			$msgid = &gen_message_id;
		}
	}
	print NEWS "Message-ID: $msgid\n";

	# Protect Sender: lines in the original message and clean-up header
	local($last_was_header);		# Set to true when header is skipped

	# Need at most one of the following headers, lest article might be rejected
	my %single = map { lc($_) => 0 } qw(
		Mime-Version
		Content-Transfer-Encoding
		Content-Type
		Reply-To
	);

	foreach (split(/\n/, $Header{'Head'})) {
		s/^Sender:/Prev-Sender:/i;
		s/^(To|Cc):/X-$1:/i;				# Keep distribution info
		s/^(Resent-\w+):/X-$1:/i;
		next if /^From\s/;					# First From line...
		if (
			/^From:/i				||		# This one was cleaned up above
			/^Subject:/i			||		# This one handled above
			/^Message-Id:/i			||		# idem
			/^Date:/i				||		# idem
			/^In-Reply-To:/i		||
			/^References:/i			||		# One will be faked if missing
			/^Apparently-To:/i		||
			/^Distribution:/i		||		# No mix-up, please
			/^Control:/i			||
			/^X-Server-[\w-]+:/i	||
			/^Xref:/i				||
			/^NNTP-Posting-.*:/i	||		# Cleanup for NNTP server
			/^Originator:/i			||		# Probably from news->mail gateway
			/^X-Loop:/i				||		# INN does not like this field
			/^X-Trace:/i			||		# idem
			/^Newsgroups:/i			||		# Reply from news reader
			/^Return-Receipt-To:/i	||		# Sendmail's acknowledgment
			/^Received:/i			||		# We want to remove received
			/^Precedence:/i			||
			/^X-Complaints-To:/i	||		# INN2 does not like this field
			/^Errors-To:/i					# Error report redirection
		) {
			$last_was_header = 1;			# Mark we discarded the line
			next;							# Line is skipped
		}
		if (/^([\w-]+):/ && exists $single{"\L$1"}) {
			my $field = lc($1);
			if ($single{$field}++) {
				my $nfield = &header'normalize($field);
				&add_log("WARNING stripping dup $nfield header")
					if $loglvl > 5 && $single{$field} == 2;
				$last_was_header = 1;		# Mark we discarded the line
				next;						# Line is skipped
			}
		}
		next if /^\s/ && $last_was_header;	# Skip removed header continuations
		$last_was_header = 0;				# We decided to keep header line
		# Ensure that we always put a single space after the field name
		# (before possibly emitting a newline for the continuation)
		s/^([\w-]+):(\S)/$1: $2/ || s/^([\w-]+):$/$1: /;
		print NEWS $_, "\n";
	}

	# For correct threading, we need a References: line.
	my $refs = $Header{'References'};		# Will probably be missing
	$refs =~ tr/\n/ /;						# Must be ONE line
	my $inreply = $Header{'In-Reply-To'};	# Should not be missing for replies
	my ($replyid) = $inreply =~ /(<[^>]+>)/;

	# Warn only when there's no message ID in the In-Reply-To header and
	# there is no References line: this will prevent correct threading.
	# We assume the References line was correctly setup when it is present.
	&add_log("WARNING In-Reply-To header did not contain any message ID")
		if $loglvl > 5 && $inreply ne '' && $replyid eq '' && $refs =~ /^\s*$/;

	if ($replyid ne '' && $refs ne '' && $refs !~ /\Q$replyid/) {
		$refs .= " $replyid";
		&add_log("NOTICE added missing In-Reply-To ID to References")
			if $loglvl > 6;
	}
	$refs = $replyid unless $refs ne '';
	if ($refs ne '') {
		my $fixup = &header'msgid_cleanup(\$refs);
		&add_log("WARNING fixed References line for news")
			if $loglvl > 5 && $fixup;
		print NEWS "References: $refs\n";	# One big happy line
	}

	# Any address included withing "" means addresses are stored in a file
	$newsgroups = &complete_list($newsgroups, 'newsgroup');
	$newsgroups =~ s/\s/,/g;	# Cannot have spaces between them
	$newsgroups =~ tr/,/,/s;	# Squash down consecutive ','
	print NEWS "Newsgroups: $newsgroups\n";
	print NEWS "Distribution: local\n" if $localdist;
	print NEWS $FILTER, "\n";	# Avoid loops: inews may forward to sendmail
	print NEWS "\n";
	print NEWS $Header{'Body'};
	close NEWS;
	local($failed) = $?;		# Status of forwarding
	if ($failed) {
		&add_log("ERROR could not post to $newsgroups") if $loglvl > 1;
	} else {
		&biff($newsgroups, "news") if $wantbiff;
	}
	$failed;		# 0 for success
}

# The "APPLY" command
sub apply {
	local($rulefile) = @_;
	# Prepare new environment for apply_rules
	local($ever_saved) = 0;
	local($ever_matched) = 0;
	# Now call apply_rules, with no statistics recorded, propagating the
	# current mode we are in and using an alternate rule file.
	local($saved, $matched) =
		&rules'alternate($rulefile, 'apply_rules', $wmode, 0);
	if (!defined($saved)) {
		&add_log("ERROR could not apply rule file $rulefile") if $loglvl > 1;
		return (1, 0);	# Notify failure
	}
	# Since APPLY will fail when no save, warn the user
	if (!$matched) {
		&add_log("NOTICE no match in $rulefile") if $loglvl > 6;
	} else {
		&add_log("NOTICE no save in $rulefile") if !$saved && $loglvl > 6;
	}
	(0, $saved);		# Mail was correctly filtered, but was it saved?
}

# The "SPLIT" command
# This routine is RFC-934 compliant and will correctly burst digests produced
# with this RFC in mind. For instance, MH produces RFC-934 style digest.
# However, in order to reliably split non RFC-934 digest, some extra work is
# performed to ensure a meaningful output.
sub split {
	local($folder) = @_;		# Folder to save messages into
	# Option parsing: a -i splits "inplace", i.e. acts as a saving if the split
	# is fully successful. A -d discards the leading part. Queues messsages
	# instead of filling them into a folder if the folder name is empty.
	local($inplace) = $opt'sw_i;	# Inplace (original marked saved)
	local($discard) = $opt'sw_d;	# Discard digest leading part
	local($empty) = $opt'sw_e;		# Discard leading digest only if empty
	local($watch) = $opt'sw_w;		# Watch digest closely
	local($annotate) = $opt'sw_a;	# Annotate items with X-Digest-To: field
	local(@leading);			# Leading part of the digest
	local(@header);				# Looked ahead header
	local($found_header) = 0;	# True when header digest was found
	local($look_header) = 0;	# True when we are looking for a mail header
	local($found_end) = 0;		# True when end of digest found
	local($valid);				# Return value from header checking package
	local($failed) = 0;			# Queuing status for each mail item
	local(@body);				# Body of extracted mail
	local($item) = 0;			# Count digest items found
	local($not_rfc934) = 0;		# Is digest RFC-934 compliant?
	local($digest_to);			# Value of the X-Digest-To: field
	local($_);
	# If item annotation is requested, then each item will have a X-Digest-To:
	# field added, which lists both the To: and Cc: fields of the original
	# digest message.
	if ($annotate) {			# Annotation requested
		$digest_to = $Header{'Cc'};
		$digest_to = ', ' . $digest_to if $digest_to;
		$digest_to = 'X-Digest-To: ' . $Header{'To'} . $digest_to;
		$digest_to = &header'format($digest_to);
	}
	# Start digest parsing. According to RFC-934, we could only look for a
	# single '-' as encapsulation boundary, but for safety we look for at least
	# three consecutive ones.
	foreach (split(/\n/, $Header{'All'})) {
		push(@leading, $_) unless $found_header;
		push(@body, $_) if $found_header;
		if (/^---/) {			# Start looking for mail header
			$look_header = 1;	# Focus on mail headers now
			# We are withing the body of a digest and we've just reached
			# what may be the end of a message, or the end of the leading part.
			@header = ();		# Reset look ahead buffer
			&header'reset;		# Reset header checking package
			next;
		}
		next unless $look_header;
		# Record lines we find, but skip possible blank lines after dash.
		# Note that RFC-934 does not make spaces compulsory after each
		# encapsulation boundary (EB) but they are allowed nonetheless.
		next if /^\s*$/ && 0 == @header;
		$found_end = 0;			# Maybe it's not garbage after all...
		$valid = &header'valid($_);
		if ($valid == 0) {		# Not a valid header
			$look_header = 0;	# False alert
			$found_end = 1;		# Garbage after last EB is to be ignored
			if ($watch) {
				# Strict RFC-934: if an EB is followed by something which does
				# not prove to be a valid header but looked like one, enough
				# to have some lines collected into @header, then signal it.
				++$not_rfc934 unless 0 == @header;
			} else {
				# Don't be too scrict. If what we have found so far *may be* a
				# header, then yes, it's not RFC-934. Otherwise let it go.
				++$not_rfc934 if $header'maybe;
			}
			next;
		} elsif ($valid == 1) {	# Still in header
			push(@header, $_);	# Record header lines
			next;
		}
		# Coming here means we reached the end of a valid header
		push(@header, $digest_to) if $annotate;
		push(@header, '');		# Blank header line
		if (!$found_header) {
			if ($empty) {
				$failed |= &save_mail(*leading, $folder)
					unless &empty_body(*leading) || $discard;
			} else {
				$failed |= &save_mail(*leading, $folder) unless $discard;
			}
			undef @leading;		# Not needed any longer
			$item++;			# So that 'save_mail' starts logging items
		}
		# If there was already a mail being collected, save it now, because
		# we are sure it is followed by a valid mail.
		$failed |= &save_mail(*body, $folder) if $found_header;
		$found_header = 1;		# End of header -> this is truly a digest
		$look_header = 0;		# We found our header
		&header'clean(*header);	# Ensure minimal set of header
		@body = @header;		# Copy headers in mail body for next message
	}

	return -1 unless $found_header;	# Message was not in digest format

	# Save last message, making sure to add a final dash line if digest did
	# not have one: There was one if $look_header is true. There was also
	# one if $found_end is true.
	push(@body, '---') unless $look_header || $found_end;

	# If the -w option was used, we look closely at the supposed trailing
	# garbage. If the length is greater than 100 characters, then maybe we
	# are missing something here...
	if ($watch) {
		local($idx) = $#body;
		$_ = $body[$idx];			# Get last line
		@header = ();				# Reset "garbage collector"
		unless (/^---/) {			# Do not go on if end of digest truly found
			for (; $idx >= 0; $idx--) {
				$_ = $body[$idx];
				last if /^---/;		# Reached end of presumed trailing garbage
				unshift(@header, $_);
			}
		}
	}

	# Now save last message
	$failed |= &save_mail(*body, $folder);

	# If we collected something into @header and if it is big enough, save it
	# as a trailing message.
	if ($watch && length(join('', @header)) > 100) {
		&add_log("NOTICE [$mfile] has trailing garbage...") if $loglvl > 6;
		@body = @header;			# Copy saved garbage
		@header = ();				# Now build final garbage headers
		$header[0] = 'Subject: ' . $Header{'Subject'} . ' (trailing garbage)';
		$header[1] = $digest_to if $annotate;
		&header'clean(*header);		# Build other headers
		unshift(@body, '') unless $body[0] =~ s/^\s*$//;	# Ensure EOH
		foreach (@body) {
			push(@header, $_);
		}
		push(@header, '---');
		$failed |= &save_mail(*header, $folder);
	}

	$failed + 0x2 * $inplace + 0x4 * ($folder =~ /^\s*$/)
		+ 0x8 * ($not_rfc934 > 0);
}

# The "RUN" command and its friends
# Start a shell command and mail any output back to the user. The program is
# invoked from within the home directory.
sub shell_command {
	local($program, $input, $feedback) = @_;
	unless (chdir $cf'home) {
		&add_log("WARNING cannot chdir to $cf'home: $!") if $loglvl > 5;
	}
	$program =~ s/^\s*~/$cf'home/;	# ~ substitution
	$program =~ s/\b~/$cf'home/g;	# ~ substitution as first letter in word
	$SIG{'PIPE'} = 'popen_failed';	# Protect against naughty program
	$SIG{'ALRM'} = 'alarm_clock';	# Protect against loops
	alarm $cf'runmax;				# At most that amount of processing
	eval '&execute_command($program, $input, $feedback)';
	alarm 0;						# Disable alarm timeout
	$SIG{'PIPE'} = 'emergency';		# Restore initial value
	$SIG{'ALRM'} = 'DEFAULT';		# Restore default behaviour
	local($msg) = $@;
	$@ = '';						# Clear this global for our caller
	if ($msg =~ /^failed/) {		# Something went wrong?
		&add_log("ERROR couldn't run '$program'") if $loglvl > 0;
		return 1;					# Failed
	} elsif ($msg =~ /^aborted/) {	# Writing to program failed
		&add_log("WARNING pipe closed by '$program'") if $loglvl > 5;
		return 1;					# Failed
	} elsif ($msg =~ /^feedback/) {	# Feedback failed
		&add_log("WARNING no feedback occurred") if $loglvl > 5;
		return 1;					# Failed
	} elsif ($msg =~ /^alarm/) {	# Timeout
		&add_log("WARNING time out received ($cf'runmax seconds)")
			if $loglvl > 5;
		return 1;					# Failed
	} elsif ($msg =~ /^non-zero/) {	# Program returned non-zero status
		&add_log("WARNING program returned non-zero status") if $loglvl > 5;
		return 1;
	} elsif ($msg) {
		$msg =~ s/\n$//;			# Not sure it's there... don't chop!
		&add_log("ERROR $msg") if $loglvl > 0;
		return 1;					# Failed
	}
	0;			# Everything went fine
}

# Abort execution of command when popen() fails or program dies abruptly
sub popen_failed {
	local($status) = 'died abruptly';	# Status for &mail_back
	&mail_back;			# Let the user know about a possible error message
	unlink "$trace" if -f "$trace";
	die "$error\n";
}

# When an alarm call is received, we should be in the 'execute_command'
# routine. The $pid variable holds the pid number of the process to be killed.
sub alarm_clock {
	if ($trace ne '' && -f "$trace") {		# We come from execute_command
		local($status) = "terminated";		# Process was terminated
		if (kill "SIGTERM", $pid) {			# We could signal our child
			sleep 30;						# Give child time to die
			unless (kill "SIGTERM", $pid) {	# Child did not die yet ?
				unless (kill "SIGKILL", $pid) {
					&add_log("ERROR could not kill process $pid: $!")
						if $loglvl > 1;
				} else {
					$status = "killed";
					&add_log("KILLED process $pid") if $loglvl > 4;
				}
			} else {
				&add_log("TERMINATED process $pid") if $loglvl > 4;
			}
		} else {
			$status = "unknown";	# Process died ?
			&add_log("ERROR coud not signal process $pid: $!")
				if $loglvl > 1;
		}
		&mail_back;					# Mail back any output we have so far
		unlink "$trace";			# Remove output of command
	}
	die "alarm call\n";				# Longjmp to shell_command
}

# Execute the command, ran in an eval to protect against SIGPIPE signals
sub execute_command {
	local($program, $input, $feedback) = @_;

	local($location) = &locate_program($program);
	die "can't locate $location in PATH\n" unless $location =~ m|/|;
	die "unsecure $location\n" unless &exec_secure($location);

	local($trace) = "$cf'tmpdir/trace.run$$";	# Where output goes
	local($error) = "failed";				# Error reported by popen_failed
	pipe(READ, WRITE);						# Open a pipe
	local($pid) = fork;						# We fork here
	$pid = -1 unless defined $pid;

	if ($pid == 0) {						# Child process
		alarm 0;
		close WRITE;						# The child reads from pipe
		open(STDIN, "<&READ");				# Redirect stdin to pipe
		close READ if $input == $NO_INPUT;	# Close stdin if needed
		unless (open(STDOUT, ">$trace")) {	# Where output goes
			&add_log("WARNING couldn't create $trace: $!") if $loglvl > 5;
			if ($feedback == $FEEDBACK) {	# Need trace if feedback
				kill 'SIGPIPE', getppid;	# Parent still waiting
				exit 1;
			}
		}
		open(STDERR, ">&STDOUT");			# Make it follow pipe
		# Using a sub-block ensures exec() is followed by nothing
		# and makes mailagent "perl -cw" clean, whatever that means ;-)
		{ exec $program }					# Run the program now
		&add_log("ERROR couldn't exec '$program': $!") if $loglvl > 1;
		exit 1;
	} elsif ($pid == -1) {
		&add_log("ERROR couldn't fork: $!") if $loglvl;
		return;
	}

	close READ;								# The parent writes to its child
	$error = "aborted";						# Error reported by popen_failed
	select(WRITE);
	$| = 1;									# Hot pipe wanted
	select(STDOUT);

	# Now feed the program with the mail
	if ($input == $BODY_INPUT) {			# Pipes body
		print WRITE $Header{'Body'};
	} elsif ($input == $MAIL_INPUT) {		# Pipes the whole mail
		print WRITE $Header{'All'};
	} elsif ($input == $HEADER_INPUT) {		# Pipes the header
		print WRITE $Header{'Head'};
	}
	close WRITE;							# Close input, before waiting!

	wait();									# Wait for our child
	local($status) = $? ? "failed" : "ok";
	if ($?) {
		# Log execution failure and return to shell_command via die if some
		# feedback was to be done.
		&add_log("ERROR execution failed for '$program'") if $loglvl > 1;
		if ($feedback == $FEEDBACK) {		# We wanted feedback
			&mail_back;						# Mail back any output
			unlink "$trace";				# Remove output of command
			die "feedback\n";				# Longjmp to shell_command
		}
	}

	&handle_output;			# Take appropriate action with command output
	unlink "$trace";		# Remove output of command
	die "non-zero status\n" unless $status eq 'ok';
}

# If no feedback is wanted, simply mail the output of the commands to the
# user. However, in case of feedback, we have to update the values of
# %Header in the entries 'All', 'Body' and 'Head'. Note that the other
# header fields are left untouched. Only a RESYNC can synchronize them
# (this makes sense only for a FEED command, of course).
# Uses $feedback from execute_command
sub handle_output {
	if ($feedback == $NO_FEEDBACK) {
		&mail_back;						# Mail back any output
	} elsif ($feedback == $FEEDBACK) {
		&feed_back;						# Feed result back into %Header
	}
}

# Mail back the contents of the trace file (output of program), if not empty.
# Uses some local variables from execute_command
sub mail_back {
	local($size) = -s "$trace";				# Size of output
	return unless $size;					# Nothing to be done if no output
	local($std_input);						# Standard input used
	$std_input = "none" if $input == $NO_INPUT;
	$std_input = "mail body" if $input == $BODY_INPUT;
	$std_input = "whole mail" if $input == $MAIL_INPUT;
	$std_input = "header" if $input == $HEADER_INPUT;
	local($program_name) = $program =~ m|^(\S+)|;
	unless (open(MAILER,"|$cf'sendmail $cf'mailopt $cf'email")) {
		&add_log("SYSERR fork: $!") if $loglvl;
	}
	print MAILER <<EOM;
To: $cf'email
Subject: Output of your '$program_name' command ($status)
$MAILER

Your command was: $program
Input: $std_input
Status: $status

It produced the following output:

EOM
	unless (open(TRACE, "$trace")) {
		&add_log("ERROR couldn't reopen $trace") if $loglvl > 1;
		print MAILER "*** SORRY -- NOT AVAILABLE ***\n";
	} else {
		while (<TRACE>) {
			print MAILER;
		}
		close TRACE;
	}
	close MAILER;
	unless ($?) {
		&add_log("SENT output of '$program_name' to $cf'email ($size bytes)")
			if $loglvl > 2;
	} else {
		&add_log("ERROR couldn't send $size bytes to $cf'email") if $loglvl;
		&trace_dump($trace, "$program_name output ($status)");
	}
}

# Feed back output of a command in the %Header data structure.
# Uses some local variables from execute_command
sub feed_back {
	unless (open(TRACE, "$trace")) {
		&add_log("ERROR couldn't feed back from $trace: $!") if $loglvl > 1;
		unlink "$trace";				# Maybe I should leave it around
		die "feedback\n";				# Return to shell_command
	}
	local($temp) = ' ' x 2000;			# Temporary storage (pre-extended)
	$temp = '';
	local($last_was_nl) = 1;			# True when previous line was blank
	if ($input == $BODY_INPUT) {		# We have to feed back the body only
		while (<TRACE>) {
			# Protect potentially dangerous lines. If fromall is ON, then we
			# don't care whether From is within a paragraph, i.e. not preceded
			# by a blank line. This is only required with "broken" User Agents.
			s/^From(\s)/>From$1/ if $last_was_nl && $cf'fromesc =~ /on/i;
			$last_was_nl = /^$/ || $cf'fromall =~ /on/i;
			$temp .= $_;
		}
	} else {
		local($head) = ' ' x 500;		# Pre-extend header
		$head = '';
		while (<TRACE>) {
			if (1../^$/) {
				$head .= $_ unless /^$/;
			} else {
				# Protect potentially dangerous lines
				s/^From(\s)/>From$1/ if $last_was_nl && $cf'fromesc =~ /on/i;
				$last_was_nl = /^$/ || $cf'fromall =~ /on/i;
				$temp .= $_;
			}
		}
		if ($head =~ /^\s*$/s) {			# A perl5 construct
			&add_log("ERROR got empty header from $trace") if $loglvl > 1;
			unlink "$trace";				# Maybe I should leave it around
			die "feedback\n";				# Return to shell_command
		}
		$Header{'Head'} = $head;
	}
	close TRACE;
	$Header{'Body'} = $temp unless $input == $HEADER_INPUT;
	$Header{'All'} = $Header{'Head'} . "\n" . $Header{'Body'};
}

# Feed output back into $Back variable (used by BACK command). Typically, the
# BACK command is used with RUN, though any other command is allowed (but does
# not always make sense).
# NB: This routine:
#  - Is never called explicitely but via a type glob through *handle_output
#  - Uses some local variables from execute_command
sub xeq_back {
	unless (open(TRACE, "$trace")) {
		&add_log("ERROR couldn't feed back from $trace: $!") if $loglvl > 1;
		unlink "$trace";				# Maybe I should leave it around
		die "feedback\n";				# Return to shell_command
	}
	while (<TRACE>) {
		chop;
		next if /^\s*$/;
		$Back .= $_ . '; ';				# Replace \n by ';' separator
	}
	close TRACE;
}

# The "RESYNC" command
# Resynchronizes the %Header entries by reparsing the 'All' entry
sub header_resync {
	# Clean up all the non-special entries
	foreach $key (keys %Header) {
		next if $Pseudokey{$key};		# Skip pseudo-header entries
		delete $Header{$key};
	}
	# There is some code duplication with parse_mail()
	local($lines) = 0;
	local($first_from);						# First From line records sender
	local($last_header);					# Current normalized header field
	local($in_header) = 1;					# Bug in the range operator
	local($value);							# Value of current field
	foreach (split(/\n/, $Header{'All'})) {
		if ($in_header) {					# Still in header of message
			if (/^$/) {						# End of header
				$in_header = 0;
				next;
			}
			if (/^\s/) {					# It is a continuation line
				s/^\s+/ /;					# Swallow multiple spaces
				$Header{$last_header} .= $_ if $last_header ne '';
			} elsif (/^([\w-]+):\s*(.*)/) {	# We found a new header
				$value = $2;				# Bug in perl 4.0 PL19
				$last_header = &header'normalize($1);
				# Multiple headers like 'Received' are separated by a new-
				# line character. All headers end on a non new-line.
				if ($Header{$last_header} ne '') {
					$Header{$last_header} .= "\n$value";
				} else {
					$Header{$last_header} .= $value;
				}
			} elsif (/^From\s+(\S+)/) {		# The very first From line
				$first_from = $1;
			} else {
				# Did not identify a header field nor a continuation
				# Maybe there was a wrong header split somewhere?
				if ($last_header eq '') {
					&add_log("ERROR ignoring header garbage: $_")
						if $loglvl > 1;
				} else {
					&add_log("ERROR missing continuation for $last_header")
						if $loglvl > 1;
					$Header{$last_header} .= " " . $_;
				}
			}
		} else {
			$lines++;						# One more line in body
		}
	}
	&header_check($first_from, $lines);	# Sanity checks
}

# The "STRIP" and "KEEP" commands (case insensitive)
# Removes or keeps some headers and update the Header structure
sub alter_header {
	local($headers, $action) = @_;
	$headers =
		&complete_list($headers, 'header');	# Process "file-inclusion"
	local(@list) = split(/\s/, $headers);
	local(@head) = split(/\n/, $Header{'Head'});
	local(@newhead);				# The constructed header
	local($last_was_altered) = 0;	# Set to true when header is altered
	local($matched);				# Did any header matched ?
	local($line);					# Original header line

	foreach $h (@list) {			# Prepare patterns
		$h =~ s/:$//;				# Remove trailing ':' if any
		$h = &perl_pattern($h);		# Headers specified by shell patterns
	}

	foreach (@head) {
		if (/^From\s/) {			# First From line...
			push(@newhead, $_);		# Keep it anyway
			next;
		}
		$line = $_;					# Save original
		# Make sure header field name is normalized before attempting a match
		s/^([\w-]+):/&header'normalize($1).':'/e;
		unless (/^\s/) {			# If not a continuation line
			$last_was_altered = 0;	# Reset header alteration flag
			$matched = 0;			# Assume no match
			foreach $h (@list) {	# Loop over to-be-altered lines
				if (/^$h:/i) {		# We found a line to be removed/kept
					$matched = 1;
					last;
				}
			}
			$last_was_altered = $matched;
			next if $matched && $action == $HD_SKIP;
			next if !$matched && $action == $HD_KEEP;
		}
		if ($action == $HD_SKIP) {
			next if /^\s/ && $last_was_altered;		# Skip header continuations
		} else {									# Action is $HD_KEEP
			next if /^\s/ && !$last_was_altered;	# Header was not kept
		}
		push(@newhead, $line);		# Add line to the new header
	}
	$Header{'Head'} = join("\n", @newhead) . "\n";
	$Header{'All'} = $Header{'Head'} . "\n" . $Header{'Body'};
}

# The "ANNOTATE" command
sub annotate_header {
	local($field, $value) = @_;			# Field, value
	if ($opt'sw_u) {					# -u means "unique": no anno if present
		local($normalized) = &header'normalize($field);
		return 1 if defined $Header{$normalized} && $Header{$normalized} ne '';
	}
	if ($value eq '' && $opt'sw_d) {	# No date and no value for field!
		&add_log("WARNING no value for '$field' annotation") if $loglvl > 5;
		return 1;
	}
	if ($field eq '') {				# No field specified!
		&add_log("WARNING no field specified for annotation") if $loglvl > 5;
		return 1;
	}
	local($annotation) = '';		# Annotation made
	$annotation = "$field: " . &header'mta_date() . "\n" unless $opt'sw_d;
	$annotation .= &header'format("$field: $value") . "\n" if $value ne '';
	&header_append($annotation);	# Add field into %Header
	0;
}


# Utilitity routine for alter_field()
# Performs $op on $bufref, the value of the header field $header, and insert
# result in the head (pointed to by $headref), or the original raw buffer if
# there was no change.
# Returns whether there was a change or not, undef on eval() error.
sub runop_on_field {
	my ($header, $op, $bufref, $raw_bufref, $headref) = @_;

	&add_log("running $op for $header: " . $$bufref) if $loglvl > 19;
	my $changed = eval "\$\$bufref =~ $op";
	if ($@) {
		&add_log("ERROR operation $op failed: $@") if $loglvl > 1;
		return undef;		# Abort further processing
	}
	&add_log("changed buffer: " . $$bufref) if $changed && $loglvl > 19;
	$$headref .= $changed ?
		&header'format("$header: " . $$bufref) :
		("$header: " . $$raw_bufref);
	$$headref .= "\n";

	return $changed ? 1 : 0;
}

# The "TR" and "SUBST" commands targetted to header field.
# The operation (s/// or tr//) is performed on the header field.
# If a match occurrs, the whole header is reformatted.
# Returns failure status (0 means OK)
sub alter_field {
	my ($header_field, $op) = @_;
	$header_field = &header'normalize($header_field);

	my $head = ' ' x length $Header{'Head'};
	$head = '';
	my $last_header = '';		# Non-empty indicates header field to process
	my $buffer;					# Holds value of field to process
	my $raw_buffer;				# Holds raw lines of field to process
	my $ever_changed = 0;

	foreach (split(/\n/, $Header{'Head'})) {
		if (/^\s/) {
			if ($last_header eq '') {
				$head .= $_ . "\n";
			} else {
				$raw_buffer .= "\n$_";		# In case there's no change
				s/^\s+/ /;
				$buffer .= $_;				# What we'll run $op on
			}
		} elsif (my ($field, $value) = /^([\w-]+)\s*:\s*(.*)/) {

			# Perform operation on $buffer if previous header matched.
			if ($last_header ne '') {
				my $changed = runop_on_field($last_header, $op,
					\$buffer, \$raw_buffer, \$head);
				return 1 unless defined $changed;	# Abort, because $op failed
				$ever_changed++ if $changed;
				$last_header = '';
			}

			if (&header'normalize($field) eq $header_field) {
				$last_header = $field;			# Indicates a match
				$raw_buffer = $buffer = $value;
			} else {
				$head .= $_ . "\n";
			}
		} else {
			$head .= $_ . "\n";
		}
	}

	# Perform operation on $buffer if last header seen matched.
	if ($last_header ne '') {
		my $changed = runop_on_field($last_header, $op,
			\$buffer, \$raw_buffer, \$head);
		return 1 unless defined $changed;	# Abort, because $op failed
		$ever_changed++ if $changed;
	}

	# Resynchronize pseudo-headers if there was any change
	if ($ever_changed) {
		$Header{'All'} = $head . "\n" . $Header{'Body'};
		$Header{'Head'} = $head;
	}

	&add_log("changed $ever_changed $header_field line" .
		($ever_changed == 1 ? '' : 's') . " with $op") if $loglvl > 6;
}

# The "TR" and "SUBST" commands -- main entry point
sub alter_value {
	local($variable, $op) = @_;	# Variable and operation to performed
	local($lvalue);				# Perl variable to be modified
	local($extern);				# Lvalue used for persistent variables

	# We may modify a variable or a backreference (not read-only as in perl)
	if ($variable =~ s/^#://) {
		$extern = &extern'val($variable);	# Fetch external value
		$lvalue = '$extern';				# Modify this variable
	} elsif ($variable =~ s/^#//) {
		$lvalue = '$Variable{\''.$variable.'\'}';
	} elsif ($variable =~ /^\d\d?$/) {
		$variable = int($variable) - 1;
		$lvalue = '$Backref[' . $variable . ']';
	} elsif ($variable =~ /^([\w-]+):?$/) {
		my $field = $1;						# Dataloading will change $1
		return alter_field($field, $op);	# More complex, handle separately
	} else {
		&add_log("ERROR incorrect variable name '$variable'") if $loglvl > 1;
		return 1;
	}

	# Let perl do the work
	&add_log("running $lvalue =~ $op") if $loglvl > 19;
	eval $lvalue . " =~ $op";
	&add_log("ERROR operation $op failed: $@") if $@ && $loglvl > 1;

	# If an external (persistent) variable was used, update its value now,
	# unless the operation failed, in which case the value is not modified.
	&extern'set($variable, $extern) if $@ eq '' && $lvalue eq '$extern';

	$@ eq '' ? 0 : 1;			# Failure status
}

# The "PERL" command
sub perl {
	local($script) = @_;	# Location of perl script
	local($failed) = '';	# Assume script did not fail
	local(@_);				# No visible args for functions in script

	unless (chdir $cf'home) {
		&add_log("WARNING cannot chdir to $cf'home: $!") if $loglvl > 5;
	}

	$script =~ s/^\s*~/$cf'home/;	# ~ substitution
	$script =~ s/\b~/$cf'home/g;	# ~ substitution as first letter in word

	# Set up the @ARGV array, by parsing the $script variable with &shellwords.
	# Note that the @ARGV array is held in the main package, but since the
	# mailagent makes no use of it at this point, there is no need to save its
	# value before clobbering it.
	require 'shellwords.pl';
	eval '@ARGV = &shellwords($script)';
	if (chop($@)) {				# There was an unmatched quote
		$@ =~ s/^U/u/;
		&add_log("ERROR $@") if $loglvl > 1;
		&add_log("ERROR cannot run PERL $script") if $loglvl > 2;
		return 1;
	}

	unless (open(PERL, $ARGV[0])) {
		&add_log("ERROR cannot open perl script $ARGV[0]: $!") if $loglvl > 1;
		return 1;
	}

	# Fetch the perl script in memory, within a block to really localize $/
	local($body) = ' ' x (-s PERL);
	{
		local($/) = undef;
		$body = <PERL>;		# Slurp whole file into pre-extended variable
	}
	close(PERL);
	local(@saved) = @INC;	# Save INC array (perl library location path)
	local(%saved) = %INC;	# Save already required files

	# Run the perl script in special package
	unshift(@INC, $privlib);	# Files first searched for in mailagent's lib
	package mailhook;			# -- entering in mailhook --
	&interface'new;				# Signal new script being loaded
	&hook'initvar('mailhook');	# Initialize convenience variables
	eval $'body;				# Load, compile and execute within mailhook
	local($saved) = $@;			# If perl5, interface::reset will use an eval!
	&interface'reset;			# Clear the mailhook package if no more pending
	$@ = $saved;				# Restore old $@ (useful only for perl5)
	package main;				# -- reverting to main --
	@INC = @saved;				# Restore INC array
	%INC = %saved;				# In case script has required some other files

	# If the script died with an 'OK' error message, then it meant 'exit 0'
	# but also wanted the exit to be trapped. The &exit function is provided
	# for that purpose.
	if (chop($@)) {
		if ($@ =~ /^OK/) {
			$@ = '';
			&add_log("script exited with status 0") if $loglvl > 18;
		}
		elsif ($@ =~ /^Exit (\d+)/) {
			$@ = '';
			$failed = "exited with status $1";
		}
		elsif ($@ =~ /^Status (\d+)/) {		# A REJECT, RESTART or ABORT
			$@ = '';
			$cont = $1;						# This will modify control flow
			&add_log("script ended with a control '$cont'") if $loglvl > 18;
		}
		else {
			$@ =~ s/ in file \(eval\)//;
			&add_log("ERROR $@") if $loglvl;
			$failed = "execution aborted";
		}
		&add_log("ERROR perl failed ($failed)") if $loglvl > 1 && $failed;
	}
	$failed ? 1 : 0;
}

# The "REQUIRE" command
sub require {
	local($file, $package) = @_;	# File to load, package to put it in
	$package = 'newcmd' if $package eq '';	# Use newcmd if no package
	$file =~ s/^\s*~/$cf'home/;		# ~ substitution
	# Note that the dynload package records files being loaded into a H table,
	# and "requiring" two times the same file in the *same* package will be
	# a no-op, returning the same status as the first time.
	local($ok) = &dynload'load($package, $file);
	$file = &tilda($file);			# Replace home directory with a nice ~
	unless (defined $ok) {
		&add_log("ERROR cannot load $file in package $package");
		return 1;		# Require failed
	}
	unless ($ok) {
		&add_log("ERROR cannot parse $file into package $package");
		return 1;		# Require failed
	}
	0;		# Success
}

# The "DO" command
# The routine name can be one of pack'routine, COMMAND:pack'routine or
# /some/path:pack'routine. The following parsing duplicates the one done
# in &dynload'do, so beware, should the interface change.
sub do {
	local($something, $routine, $args) = @_;
	$routine = $what if $something eq '';
	unless (&dynload'do($what)) {
		local($under);
		$under = " under $something" if $something ne '';
		&add_log("ERROR couldn't locate routine $routine$under") if $loglvl > 1;
		return 1;	# Failed
	}
	$args = '()' unless $args;
	&add_log("calling routine $routine$args") if $loglvl > 15;
	eval "package main; &$routine$args;";

	# I want to allow people to call mailhook commands from a DO routine call.
	# However, commands modifying the filtering control flow are performing a
	# die() with 'Status x' as the error message where 'x' defines the new
	# continuation value for run_command. This is trapped specially here.
	# Note however that convenience variables typically set for PERL escapes
	# are not available via a DO.

	if (chop($@)) {
		local($_) = $@;
		$@ = '';				# Avoid cascades: we're within an eval already
		if (/^Status (\d+)$/) {	# Filter automaton continuation status
			$cont = $1;			# Propagate status ($cont from &run_command)
			&add_log("NOTICE $routine shifted automaton to status $cont")
				if $loglvl > 1;
		} else {
			&add_log("ERROR cannot call $routine$args: $_") if $loglvl > 1;
			return 1;
		}
	}
	0;		# Success
}

# The "AFTER" command
sub after {
	local($time, $action) = @_;
	local($no_input) = $opt'sw_n;
	local($shell_cmd) = $opt'sw_s;
	local($agent_cmd) = $opt'sw_a || !($opt'sw_n || $opt'sw_s || $opt'sw_c);
	local($now) = time;					# Current time
	local($start);						# Action's starting time
	$start = &getdate($time, $now);
	if ($start == -1) {
		&add_log("ERROR in AFTER: time '$time' is incorrect") if $loglvl > 1;
		return (1,undef);
	}
	if ($start < $now) {
		&add_log("NOTICE time '$time' ($start) is before now ($now)")
			if $loglvl > 5;
		&add_log("ERROR in AFTER: command should have run already!")
			if $loglvl > 1;
		return (1,undef);
	}
	local($atype) = $agent_cmd ? $callout'AGENT :
		($shell_cmd ? $callout'SHELL : $callout'CMD);
	local($qfile) = &callout'queue($start, $action, $atype, $no_input);
	unless (defined $qfile) {
		&add_log("ERROR in AFTER: cannot queue action $action") if $loglvl > 1;
		return (1,undef);
	}
	(0, $qfile);		# Success
}

# Modify control flow within automaton by calling a non-existant function
# &perform, which has been dynamically bound to one of the do_* functions.
# The REJECT, RESTART and ABORT actions share the following options and
# arguments. If followed by -t (resp. -f), then the action only takes place
# when the last recorded command status is true (resp. false, i.e. failure).
# If a mode is present as an argument, the the state of the automaton is
# changed to that mode prior alteration of the control flow.
sub alter_flow {
	local($mode) = @_;				# New mode we eventually change to
	&add_log("last cmd status is $lastcmd") if $loglvl > 11;
	# Variable $lastcmd comes from xeqte(), $wmode comes from analyze_mail().
	return 0 if $opt'sw_t && $lastcmd != 0;
	return 0 if $opt'sw_f && $lastcmd == 0;
	if ($mode ne '') {
		$wmode = $mode;
		&add_log("entering new state $wmode") if $loglvl > 6;
	}
	&perform;						# This was dynamically bound
}

# Perform a "REJECT"
sub do_reject {
	$cont = $FT_REJECT;			# Reject ($cont defined in run_command)
	&add_log("REJECTED [$mfile] in state $wmode") if $loglvl > 4;
	0;
}

# Perform a "RESTART"
sub do_restart {
	$cont = $FT_RESTART;		# Restart ($cont defined in run_command)
	&add_log("RESTARTED [$mfile] in state $wmode") if $loglvl > 4;
	0;
}

# Perform an "ABORT"
sub do_abort {
	$cont = $FT_ABORT;			# Abort filtering ($cont defined in run_command)
	&add_log("ABORTED [$mfile] in state $wmode") if $loglvl > 4;
	0;
}

# Given a list of items separated by white spaces, return a new list of
# items, but with "include-request" processed.
sub complete_list {
	local(@addr) = split(' ', $_[0]);	# Original list
	local($type) = $_[1];				# Type of item (header, address, ...)
	local(@result);						# Where result list is built
	local($filename);					# Name of include file
	local($_);
	foreach $addr (@addr) {
		if ($addr !~ /^"/) {			# Item not enclosed within ""
			push(@result, $addr);		# Kept as-is
		} else {
			# Load items from file whose name is given between "quotes"
			push(@result, &include_file($addr, $type));
		}
	}
	join(' ', @result);		# Return space separated items
}

# Save digest mail into a folder, or queue it if no folder is provided
# Uses the variable '$item' from 'split' to log items.
sub save_mail {
	local(*array, $folder) = @_;	# Where mail is and where to put it
	local($length) = 0;				# Length of the digest item
	local($mbox, $failed, $log_message);
	local($_);
	# Go back to the previous dash line, removing it from the body part
	# (it's only a separator). In the process, we also remove any looked ahead
	# header which belongs to the next digest item.
	do {
		$_ = pop(@array);			# Remove what belongs to next digest item
	} while !/^---/;
	# It is recommended in RFC-934 that all leading EB be escaped by a leading
	# '- ' sequence, to allow nested forwarding. However, since the message
	# we are dealing with might not be RFC-934 compliant, we are only removing
	# the leading '- ' if it is followed by a '-'. We also use the loop to
	# escape all potentially dangerous From lines.
	local($last_was_space);
	foreach (@array) {
		# Protect potentially dangerous lines
		s/^From\s+(\S+)/>From $1/ if $last_was_space && $cf'fromesc =~ /on/i;
		s/^- -/-/;					# This is the EB escape in RFC-934
		# From is dangerous after blank line, but everywhere if fromall is ON.
		$last_was_space = /^$/ || $cf'fromall =~ /on/i;
	}
	# Now @array holds the whole digest item
	if ($folder =~ /^\s*$/) {		# No folder means we have to queue message
		local($name) = &qmail(*array);
		$failed = defined $name ? 0 : 1;
		$log_message = $name =~ m|/| ? "file [$name]" : "queue [$name]";
		foreach (@array) {
			$length += length($_) + 1;	# No trailing new-lines
		}
	} else {
		# Looks like we have to save the message in a folder. I cannot really
		# ask for a local variable named %Header because emergency routines
		# use it to save mail (they expect the whole mail in $Header{'All'}).
		# However, if something goes wrong, we'll get back to the filter main
		# loop and a LEAVE (default action) will be executed, taking the
		# current values from 'Head' and 'Body'. Hence the following:

		local(%NHeader);
		$NHeader{'All'} = $Header{'All'};
		local(*Header) = *NHeader;	# From now on, we really work on %NHeader
		local($in_header) = 1;		# True while in message header
		local($first_from);			# First From line

		# Fill in %Header strcuture, which is expected by save(): header in
		# entry 'Head' and body in entry 'Body'.
		foreach (@array) {
			if ($in_header) {
				$in_header = 0 if /^$/;
				next if /^$/;
				$Header{'Head'} .= $_ . "\n";
				$first_from = $_ if /^From\s+\S+/;
				next;
			}
			$Header{'Body'} .= $_ . "\n";
		}
		&header_prepend("$FAKE_FROM\n") unless $first_from;

		# Now save into folder
		($mbox, $failed, $log_message) = &run_saving($folder, $FOLDER_APPEND);

		# Keep track in the logfile of the length of the digest item.
		$length = length($Header{'Head'}) + length($Header{'Body'}) + 1;
	}
	if ($failed) {
		if ($loglvl > 2) {
			local($s) = $length == 1 ? '' : 's';
			&add_log("ERROR unable to save #$item ($length byte$s)") if $item;
			&add_log("ERROR unable to save preamble ($length byte$s)")
				unless $item;
		}
	} else {
		if ($loglvl > 7) {
			local($s) = $length == 1 ? '' : 's';
			&add_log("SPLIT #$item in $log_message ($length byte$s)") if $item;
			&add_log("SPLIT preamble in $log_message ($length byte$s)")
				unless $item;
		}
	}
	++$item if $item;		# Count items, but not preamble (done by 'split')
	$failed;				# Propagate failure status
}

# Check body message (typically head of digest message) and return 1 if its
# body is empty, 0 otherwise.
sub empty_body {
	local(*ary) = @_;
	local(@array) = @ary;		# Work on a copy
	local($_);
	local($is_empty) = 1;
	do {
		$_ = pop(@array);		# Remove what belongs to next digest item
	} while !/^---/;
	do {
		$_ = shift(@array);		# Remove the whole header
	} while !/^$/;
	foreach (@array) {
		$is_empty = 0 unless /^\s*$/;
		last unless $is_empty;
	}
	$is_empty;
}

# Dump trace in ~/agent.trace
sub trace_dump {
	local($trace, $what) = @_;
	local($ok) = 1;
	open(DUMP, ">>$cf'home/agent.trace") || ($ok = 0);
	print DUMP "--- Trace for $what ---\n";
	print DUMP "--- (was unable to mail it back) ---\n";
	open(TRACE, $trace) || ($ok = 0);
	while (<TRACE>) { print DUMP; }
	print DUMP "--- End of trace for $what ---\n";
	close DUMP;
	&add_log("DUMPED trace in ~/agent.trace") if $ok && $loglvl > 2;
}

