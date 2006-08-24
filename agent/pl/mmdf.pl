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
;# $Log: mmdf.pl,v $
;# Revision 3.0.1.1  1995/01/25  15:26:57  ram
;# patch27: new routine &chmod for folder permission settting
;#
;# Revision 3.0  1993/11/29  13:49:02  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This set of routine handles MMDF-style mailboxes, which differ from the
;# traditional Unix-style boxes by encapsulating each message between 2 lines
;# of 4 ^A, one at the begining and one at the end. The leading From_ line is
;# consequently not needed and is removed.
;#
;# Note: this MMDF-style mailbox is also used by MH packed folders.
;#
#
# MMDF-style saving routines
#

package mmdf;

# Attempt to save in a possible MMDF mailbox. The routine opens the mailbox
# and tries to determine what kind of mailbox it is, then selects the
# appropriate saving routine.
sub save {
	local(*FD, $mailbox) = @_;	# File descriptor and mailbox name
	if (&is_mmdf($mailbox)) {	# Folder looks like an MMDF mailbox
		&save_mmdf(*FD, 'MDF');	# Use MMDF format then
	} else {
		&save_unix(*FD);		# Be conservative and use standard format
	}
}
	
# Save to a MMDF-style mailbox and return failure status with message length
# Can also be used to save MH messages if parameter $mmdf set to 'MH' (in which
# case the two ^A delimiter lines are ommitted).
sub save_mmdf {
	local(*FD, $mmdf) = @_;		# File descriptor, MH/MDF format
	local($amount) = 0;			# Amount of bytes saved
	local($failed);
	local($from);
	local(@head) = split(/\n/, $'Header{'Head'});
	$from = shift(@head);		# The first From_ line has to be skipped
	unless ($from =~ /^From\s/) {
		&'add_log("WARNING leading From line absent") if $'loglvl > 5;
		unshift(@head, $from);	# Put it back if not a From_ line
	}
	unless ($mmdf eq 'MH') {
		(print FD "\01\01\01\01\n") || ($failed = 1);
		$amount += 5;
	}
	foreach $line (@head) {
		(print FD $line, "\n") || ($failed = 1);
		$amount += length($line) + 1;
	}
	(print FD $'FILTER, "\n\n") || ($failed = 1);
	(print FD $'Header{'Body'}) || ($failed = 1);
	&force_flushing(*FD);
	unless ($mmdf eq 'MH') {
		(print FD "\01\01\01\01\n") || ($failed = 1);
		$amount += 5;
	}
	$amount +=
		length($'Header{'Body'}) +	# Message body
		length($'FILTER) + 2;		# X-Filter line plus two newlines
	($failed, $amount);
}

# Save to a Unix-style mailbox and return failure status with message length
sub save_unix {
	local(*FD) = @_;			# File descriptor
	local($amount) = 0;			# Amount of bytes saved
	local($failed);
	# First print the Header, then add the X-Filter: line, followed by body.
	(print FD $'Header{'Head'}) || ($failed = 1);
	(print FD $'FILTER, "\n\n") || ($failed = 1);
	(print FD $'Header{'Body'}) || ($failed = 1);
	&force_flushing(*FD);
	(print FD "\n") || ($failed = 1);		# Allow parsing by other tools
	$amount +=
		length($'Header{'Head'}) +	# Message header
		length($'Header{'Body'}) +	# Message body
		length($'FILTER) + 2 +		# X-Filter line plus two newlines
		1;							# Trailing new-line
	($failed, $amount);
}

# Force flushing on file descriptor, so that after next print, we may rest
# assured everything as been written on disk. That way, we may stat the file
# without closing it (since that would release any flock-style lock).
sub force_flushing {
	local(*FD) = @_;			# File descriptor we want to flush
	select((select(FD), $| = 1)[0]);
}

# Guess whether the folder we are writing to is MMDF-style or not.
sub is_mmdf {
	local($folder) = @_;		# The folder to be scanned
	open(FOLDER, "$folder") || return 0;	# Can't open -> not MMDF, say.
	local($_);					# First line from folder
	$_ = <FOLDER>;				# Can be empty
	close FOLDER;
	return 0 if /^From\s/;			# Looks like an Unix-style mailbox
	return 1 if /^\01\01\01\01\n/;	# This must be an MMDF-style mailbox
	# If we can't decide (most probably because $_ is empty), then choose
	# according to the 'mmdfbox' parameter.
	&'add_log("WARNING folder $folder may be corrupted")
		if $_ ne '' && $'loglvl > 5;
	$cf'mmdfbox =~ /on/i ? 1 : 0;	# Force MMDF if mmdfbox is ON
}

# Set permission on newly created folder message
sub chmod {
	local($mode, $file) = @_;
	local($cnt) = chmod($mode, $file);
	local($omode) = sprintf("0%o", $mode);
	$file = &'tilda($file);
	if ($cnt) {
		&'add_log("file mode on $file set to $omode") if $'loglvl > 6;
	} else {
		&'add_log("ERROR unable to set mode $omode on $file: $!") if $'loglvl;
	}
	$cnt;	# Return 1 on success, for them to further check
}

package main;

