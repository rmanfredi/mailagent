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
;# $Log: mh.pl,v $
;# Revision 3.0.1.5  1996/12/24  14:56:37  ram
;# patch45: processing of MH profile is now case-insensitive
;#
;# Revision 3.0.1.4  1995/08/07  16:20:19  ram
;# patch37: now beware of filesystems with limited filename lengths
;#
;# Revision 3.0.1.3  1995/01/25  15:26:22  ram
;# patch27: added support for the Msg-Protect MH profile component
;# patch27: allows new PROTECT command to override default Msg-Protect
;# patch27: UNSEEN mark in log has the home directory stripped via &tilda
;#
;# Revision 3.0.1.2  1994/09/22  14:27:16  ram
;# patch12: now updates folder_saved variable with file pathname
;#
;# Revision 3.0.1.1  1993/12/15  09:04:12  ram
;# patch3: log mesages were not emitted correctly
;#
;# Revision 3.0  1993/11/29  13:49:02  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This set of routine handles MH-style folders, which differ from the
;# traditional Unix-style folders by being directories, individual messages
;# being stored in distinct files (numbers).
;#
;# Note: MH packed folders are simply MMDF-style mailboxes.
;#
#
# MH-style saving routines
#

package mh;

# Attempt to save in a MH directory folder. Note that the profile entry
# Msg-Protect is honored, unless overridden by a PROTECT command.
sub save {
	local($folder) = @_;		# MH folder name (without leading '+')
	&profile;					# Get MH profile, once and for all
	local($fmode);				# File protection mode
	$folder = "$cf'home/$Profile{'path'}/$folder";
	local($mode) = oct("0$Profile{'folder-protect'}" || '0700');
	$fmode = oct("0$Profile{'msg-protect'}") if defined $Profile{'msg-protect'};
	$fmode = $env'protect if defined $env'protect;
	&'makedir($folder, $mode);	# Create folder dir with right permissions
	&save_msg($folder, $fmode, 'MH');	# Propagate failure status
}
	
# Save in a directory, not really an MH folder.
# Message protection is adjusted if a PROTECT was issued.
sub savedir {
	local($folder) = @_;		# Directory folder name
	local($fmode);				# File protection mode
	$fmode = $env'protect if defined $env'protect;
	&save_msg($folder, $fmode, 'DIR');	# Propagate failure status
}

# Common subroutine to &save and &savedir
sub save_msg {
	local($folder, $fmode, $mh) = @_;
	unless (-d $folder) {
		&'add_log("ERROR $mh folder $folder is not a directory")
			if $'loglvl > 1;
		return 1;	# Failed
	}
	local($name) = &new_msg($folder);
	unless ($name) {
		&'add_log("ERROR cannot get message number in $mh folder $folder")
			if $'loglvl > 1;
		return 1;	# Failed
	}

	# Now initiate saving by opening file for appending, then calling the
	# MMDF-style saving routine with MH type (skips emission of ^A lines).

	unless (open(MHMSG, ">>$name")) {
		&'add_log("ERROR cannot reopen $name: $!") if $'loglvl > 1;
		return 1;	# Failed, don't unlink message
	}

	# There is no need to lock the file here, since MH will never select an
	# existing file when computing a new message number.

	local($failed, $amount) = &mmdf'save_mmdf(*MHMSG, 'MH');

	# Now the size of the message must be *exactly* the amount returned.
	close MHMSG;
	local($size) = -s $name;

	&'add_log("ERROR $name has $size bytes (should have $amount)")
		if $size != $amount && $'loglvl;

	$failed = 1 if $size != $amount;
	&mmdf'chmod($fmode, $name) if defined $fmode;	# Ignore chmod errors

	# Update the unseen sequence, if needed and saving succeeded. An entry
	# is also made in the logfile for easy grep'ing and locating of messages
	# saved in directories.

	&unseen($name)
		if $mh eq 'MH' && $Profile{'unseen-sequence'} ne '' && !$failed;

	# Mark as unseen in log when saved within a directory
	&'add_log("UNSEEN " . &'tilda($name)) if $'loglvl > 6;

	$'folder_saved = $name;		# Keep track of last folder we save into
	return $failed;				# Return failure status
}

#
# MH profile and sequence management.
#

# Read MH profile, fill in %Profile entries.
sub profile {
	return if defined %Profile;
	# Make sure there is at least a valid Path entry, in case they made a
	# mistake and asked for MH folder saving without a valid .mh_profile...
	local($dflt) = defined($'XENV{'maildir'}) ? $'XENV{'maildir'} : 'Mail';
	$dflt = &'tilda($dflt);		# Restore possible leading '~'
	$dflt =~ s|^~/||;			# Strip down (relative path under ~)
	$Profile{'path'} = $dflt;
	local($mhprofile) = &'tilda_expand($cf'mhprofile || '~/.mh_profile');
	unless (open(PROFILE, $mhprofile)) {
		&'add_log("ERROR cannot open MH profile '$mhprofile': $!")
			if $'loglvl > 1;
		return;
	}
	local($_);
	while (<PROFILE>) {
		next unless /^([^:]+):\s*(.*)/;
		$Profile{"\L$1"} = $2;
	}
	close PROFILE;
}

# Compute new message number/name.
# If true MH folder, get next available number. If directory, see if there is
# a .msg_prefix file to use as a basename. Otherwise, select an MH message
# number.
sub new_msg {
	local($dir) = @_;
	unless (opendir(DIR, $dir)) {
		&'add_log("ERROR unable to open dir $dir: $!") if $'loglvl > 1;
		return 0;		# Marks failure
	}
	if (0 != &'acs_rqst($dir)) {
		&'add_log("WARNING could not lock dir $dir") if $'loglvl > 5;
	}
	local(@dir) = readdir DIR;		# Slurp it as a whole
	closedir DIR;

	# See if we have to use message prefix
	local($prefix) = $cf'msgprefix || '.msg_prefix';
	local($msg) = "$dir/$prefix";
	local($msg_prefix) = '';
	if (-f $msg) {					# Not an MH folder it would seem
		unless (open(PREFIX, $msg)) {
			&'add_log("ERROR can't open msg prefix $msg: $!") if $'loglvl > 1;
			# Continue, will use MH-style numbering then
		} else {
			chop($msg_prefix = <PREFIX>);	# First line gives prefix
			close PREFIX;
		}
	}

	# If prefix is used, keep only those messages starting with that prefix.
	# Otherwise, keep only numbers.
	local($pat) = $msg_prefix eq '' ? '/^\d+$/' : "s/^$msg_prefix(\\d+)\$/\$1/";
	eval '@dir = grep(' . $pat . ', @dir)';

	# Now sort in ascending order and get highest number
	@dir = sort { $a <=> $b; } @dir;
	local($highest) = pop(@dir) || 0;		# Ensure numeric default value

	# Now create new message before unlocking the directory. Use appending
	# instead of plain creation in case our lock was not honoured for some
	# reason.
	$highest++;
	local($new) = "$dir/$msg_prefix$highest";
	unless (open(NEW, ">>$new")) {
		&'add_log("ERROR cannot create $new: $!") if $'loglvl > 1;
		$new = 0;	# Signal no creation (directory still locked)
	} else {
		close NEW;	# File is now created
	}

	&'free_file($dir);		# Unlock directory
	return $new;			# Return message name, or 0 if error
}

# Mark MH message as unseen by adding it to the sequences listed in the
# profile entry Unseen-Sequence.
sub unseen {
	local($name) = @_;		# Full path of unseen mail message
	local($dir, $num) = $name =~ m|(.*)/(\d+)|;
	unless ($num) {
		&'add_log("WARNING cannot mark $name as unseen (not an MH message)")
			if $'loglvl > 5;
		return;
	}
	
	# Lock the .mh_sequences file first. It's a pity MH does not itself lock
	# this file when syncing it... (routine m_sync() in MH 6.8).

	local($seqfile) = "$dir/.mh_sequences";
	if (0 != &'acs_rqst($seqfile)) {
		&'add_log("WARNING could not lock MH sequence in $dir")
			if $'loglvl > 5;
	}

	# Create new .mh_sequences file
	local($seqnew) = $'long_filenames ? "$seqfile.x" : "${seqfile}X";
	unless (open(MHSEQ, ">$seqnew")) {
		&'add_log("ERROR cannot create new MH sequence file in $dir: $!")
			if $'loglvl > 1;
		&'free_file($seqfile);
		return;
	}

	open(OLDSEQ, $seqfile);	# May not exist yet, so no error check

	# Get the name of the sequences we need to update, save in %seq.
	local(%seq);
	foreach $seq (split(/,/, $Profile{'unseen-sequence'})) {
		$seq =~ s/^\s*//;	# Remove leading and trailing spaces
		$seq =~ s/\s*$//;
		$seq{$seq}++;		# Record unseen sequence
	}

	# Now loop over the existing sequences in the old .mh_sequences file
	# and update them. If some unseen sequences were not present yet, create
	# them.

	local($_);
	local($seqname);

	while (<OLDSEQ>) {
		if (s/^(\S+)://) {	# Found a sequence
			$seqname = $1;
			unless (defined $seq{$seqname}) {
				print MHSEQ "$seqname:", $_;
				next;
			}
			# Ok, it's an useen sequence and we need to update it
			chop;
			print MHSEQ "$seqname: ", &seqadd($_, $num), "\n";
			delete $seq{$seqname};
		} else {
			print MHSEQ $_;	# Whatever it was, propagate it
		}
	}
	close OLDSEQ;

	foreach $seq (keys %seq) {	# Create remaining sequences
		print MHSEQ "$seq: $num\n";
	}
	close MHSEQ;

	unless (rename($seqnew, $seqfile)) {
		&'add_log("ERROR cannot rename $seqnew as $seqfile: $!")
			if $'loglvl > 1;
	}

	&'free_file($seqfile);
}

# Add a message to an MH sequence (sorted on input).
sub seqadd {
	local($seq, $num) = @_;
	local(@seq) = split(' ', $seq);
	local($min, $max);	# Ranges in sequences are min-max
	local($i);
	local(@new);		# New sequence we are building
	local($item);		# Current item
	for ($i = 0; $i < @seq; $i++) {
		$item = $seq[$i];
		if ($num == 0) {	# Message already inserted
			push(@new, $item);
			next;			# Flush sequence
		}
		if ($item =~ /-/) {
			($min, $max) = $item =~ /(\d+)-(\d+)/;
		} else {
			$min = $max = $item;
		}
		if ($num > $max) {	# New message has to be inserted later on
			if ($num == $max + 1) {
				push(@new, "$min-$num");
				$num = 0;	# Signals: inserted
			} else {
				push(@new, $item);
			}
			next;
		}
		# Here, $num <= $max
		if ($num < $min) {	# Item to be inserted before
			if ($num == $min - 1) {
				push(@new, "$num-$max");
			} else {
				push(@new, $num);
				push(@new, $item);
			}
		} else {
			push(@new, $item);	# Item already within that range !?
		}
		$num = 0;				# Item was inserted
	}
	push(@new, $num) if $num;	# At sequence's tail if not inserted yet
	return join(' ', @new);		# Return new sequence
}

package main;

