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
;# $Log: file_edit.pl,v $
;# Revision 3.0.1.1  1994/09/22  14:19:09  ram
;# patch12: typo prevented correct indexing in the @insert array
;#
;# Revision 3.0  1993/11/29  13:48:46  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Inplace file edition. The routine is called as follows:
;#
;#   &file_edit(name, description, search, replace)
;#
;# where
;#
;# name: the path to the file
;# description: a file description for logging purposes
;# search: pattern to search, line number or function, undef to append. A
;# pattern may be specified with // or with ??, in which case an insertion
;# will be done at the end of the file if the pattern was not found.
;# replace: string, undef to delete.
;#
;# To perform multiple edits simultaneously, use:
;#
;#	&file_edit(name, description, srch_1, rep_1, srch_2, rep_2, ...)
;#
;# followed by as many search/replace pairs as needed. The main advantage is
;# that the file is locked only once, then all the edits are performed.
;#
# Inplace file edition, with one letter backup file. The routine returns a
# success status, i.e. 1 if ok and 0 if anything went wrong.
sub file_edit {
	local($name, $desc, @pairs) = @_;
	local(@backup) = ('~', '#', '@', '%', '=');
	local($bak);		# File used for backup
	local(*OLD, *NEW);	# Localize filehandles
	local($error) = 0;	# Error flag

	return 1 unless @pairs;		# Nothing to do

	if (-d $name) {
		&add_log("ERROR cannot edit a directory!! ($name)") if $loglvl;
		return 0;		# Failed
	}

	# First, lock file to prevent concurrent access
	if (0 != &acs_rqst($name)) {
		&add_log("WARNING cannot lock $desc file $name") if $loglvl > 5;
	}

	# If no search pattern are provided at all, then we only need to do some
	# appending, and therefore need only the NEW file.
	local($i);
	local($need_editing) = 0;
	for ($i = 0; $i < @pairs; $i += 2) {			# Scan only search items
		$need_editing = 1 if defined $pairs[$i];	# Search pattern defined?
		last if $need_editing;
	}

	# Now try to find a suitable backup character, which is only needed when
	# we really need to search something for replacing. If we only append to
	# the file, no backup is necessary.
	if ($need_editing) {				# Not trying to append
		foreach $c (@backup) {			# Loop for suitable backup char
			unless (-e "$name$c") {		# No such file?
				$bak = "$name$c";		# Ok, grab this extension
				last;
			}
		}
		unless ($bak) {					# Nothing found?
			&add_log("ERROR cannot create backup for $desc file $name")
				if $loglvl;
			&free_file($name);			# Release lock
			return 0;					# Error
		}
	}

	# Open the necessary files, only NEW for appending, or OLD and NEW for
	# editing (when a search pattern is provided).
	if ($need_editing) {			# Not trying to append -> needs backup
		unless (open(OLD, $name)) {
			&add_log("ERROR cannot open $desc file $name: $!") if $loglvl;
			&free_file($name);		# Release lock
			return 0;				# Error
		}
		unless (open(NEW, ">$bak")) {
			&add_log("ERROR cannot create backup for $desc file as $bak: $!")
				if $loglvl;
			close OLD;				# We won't need it anymore
			&free_file($name);		# Release lock
			return 0;				# Error
		}
	} else {						# Merely trying to append to the old file
		unless (open(NEW, ">>$name")) {
			&add_log("ERROR cannot append to $desc file $name: $!")
				if $loglvl;
			&free_file($name);		# Release lock
			return 0;				# Error
		}
		for ($i = 1; $i < @pairs; $i += 2) {		# Scan only replace items
			next unless defined $pairs[$i];
			unless (print NEW $pairs[$i], "\n") {
				&add_log("SYSERR write: $!") if $loglvl;
				$error++;
			}
			last if $error;			# Abort immediately if error
		}
		unless (close NEW) {
			&add_log("SYSERR close: $!") if $loglvl;
			$error++;
		}
		&free_file($name);			# Release lock
		if ($error) {
			&add_log("WARNING $desc file $name may be corrupted")
				if $loglvl > 5;
		}
		return $error ? 0 : 1;		# Return success (1) if file not corrupted
	}

	local(@search);			# Searching patterns
	local(@replace);		# Replacing strings
	local(@insert);			# Insertion flag for ?? patterns
	local(@type);			# Type of searching pattern

	# Build the search and replacing arrays, a search/replace pair being
	# identified by entries at the same index
	for ($i = 0; $i < @pairs; $i++) {
		push(@search, $pairs[$i++]);
		push(@replace, $pairs[$i]);
	}

	# Here, we must go through the line by line scanning of the OLD file until
	# a match occurs, at which time the replacing string is written (or the
	# record skipped when the replacing string is not defined). The search
	# string can be a verbatim string, a pattern, a numeric value understood as
	# a line number or a function to call, giving the line as parameter, along
	# with the current line number and understanding a true value as a match.
	# If the search pattern is introduced by '?' instead of '/', then the
	# replacement value is inserted at the end if no match occurred.

	local($NUMBER, $STRING, $PATTERN, $SUB) = (0 .. 3);
	local($_);

	# Build type array and set up entries in @insert when ?? patterns are used
	foreach (@search) {
		unless (defined $_) {		# No search pattern means appending
			push(@type, undef);
			next;
		}
		if (/^\d+$/) {				# Plain value is a line number
			push(@type, $NUMBER);
			$_ = int($_);
		} elsif (m|^([/?])|) {		# Looks like a pattern
			push(@type, $PATTERN);
			$insert[$#type] = 1 if $1 eq '?';
			s|^[/?](.*)[/?]$|$1|;
		} elsif (m|^&|) {		# Function to apply
			push(@type, $SUB);
			s/^&//;
		} else {							# Must be a verbatim string then
			push(@type, $STRING);
		}
	}
	local($.);
	local($found);
	local($val);		# Searching value
	local($type);		# Current searching type
	local($replace);	# Replacing value
	local($studied);	# Was line studied?

	# Now loop over the OLD file and write into NEW
	while (<OLD>) {
		chop;
		$studied = @type < 3 ? 1 : 0;		# Do not study if small amount
		$found = 0;
		for ($i = 0; $i < @type; $i++) {
			$type = $type[$i];
			next unless defined $type;		# Already dealt with or no search
			$val = $search[$i];				# Searching value
			if ($type == $NUMBER && $. == $val) {
				$type[$i] = undef;			# Avoid further inspection
				$found++;
			} elsif ($type == $STRING && $_ eq $val) {
				$found++;
			} elsif ($type == $PATTERN) {
				study unless $studied++;	# Optimize pattern matching
				($found++, $insert[$i] = 0) if /$val/;
			} elsif ($type == $SUB && &$val($_, $.)) {
				$found++;
			}
			last if $found;
		}
		if ($found) {
			$replace = $replace[$i];
			if (defined $replace) {
				(print NEW $replace, "\n") || $error++;
			}
		} else {
			(print NEW $_, "\n") || $error++;
		}
		if ($error) {
			&add_log("SYSERR write: $!") if $loglvl;
			last;
		}
	}

	# If insertion was wanted on no-match, and no error has ever occurred, then
	# do the necessary insertions now. Also add all those replacing values
	# associated with an undefined search string.

	unless ($error) {
		for ($i = 0; $i < @type; $i++) {
			next unless $insert[$i] || !defined($type[$i]);
			next unless defined $replace[$i];
			(print NEW $replace[$i], "\n") || $error++;
		}
		&add_log("SYSERR write: $!") if $error && $loglvl;
	}

	# Edition is completed. Close files and make sure NEW is correctly flushed
	# to disk by checking the return value from close.

	close OLD;
	unless (close NEW) {
		&add_log("SYSERR close: $!") if $loglvl;
		$error++;
	}

	# If no error has occurred so far, rename backup file as the original file
	# name, in effect putting an end to the editing phase.

	if ($error == 0 && !rename($bak, $name)) {
		&add_log("SYSERR rename: $!") if $loglvl;
		$error++;
	}
	&free_file($name);			# Lock may now safely be released

	if ($error) {
		&add_log("ERROR cannot inplace edit $desc file $name") if $loglvl;
		unless (unlink $bak) {
			&add_log("SYSERR unlink: $!") if $loglvl;
			&add_log("ERROR cannot remove temporary file $bak") if $loglvl;
		}
		return 0;				# Editing failed
	}

	&add_log("edited $desc file $name") if $loglvl > 18;

	1;		# Success
}

