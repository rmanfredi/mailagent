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
;# $Log: dbr.pl,v $
;# Revision 3.0  1993/11/29  13:48:39  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This is a simple database. Items are sorted by key, and have a tag
;# associated with it. Both are necessary to access the database. Every record
;# also carries a time stamp and associated values.
;#
;# The hashing is done like that: If the key is shorter than two characters,
;# an X is appended. Then, let 'a' and 'b' be the first and second character of
;# the name. Then the file 'b' is stored under directory 'a', and in 'b' there
;# are entries with the following format (separtion is the TAB character).
;#
;#     key tag timestamp <values>
;#
package dbr;

# Compute the relative path under the once directory for a given name
sub hash_path {
	local($hname) = @_;
	# Ensure at least 2 characters. Fill in missing chars with 'X'.
	$hname .= "X" if (length($hname) < 2);
	$hname .= "X" if (length($hname) < 2);
	$hname =~ s/[^A-Za-z0-9_]/X/g;	# Don't want funny chars in path name
	# Get only the 2 first characters
	local(@chars) = split(//, substr($hname, 0, 2));
	'/' . join('/', @chars);
}

# Fetch the entry in a dbr file and return the value of the timestamp and
# the line number in the file. Return (0,0) if no previous record was found
# for the name/tag association. An error is signaled by (-1,0). A line number
# different from 0, as in (0, 10), indicates that an entry was found but the
# selection did not succeed. Note that the timestamp returned is > 0 iff the
# entry was found and the selection was done completely.
# All the attached values are returned at the end of the list. It is possible
# to filter among those values by specifying a list of regular expressions, at
# the end of the argument list. An empty regular expression means the item is
# not to be filtered on (equivalent of '/.*/'). Expressions provided are
# taken as exact values to be matched against unless they start with '/' or '&'.
# A '/' denotes a regular expression to be applied, whilst '&' denotes function
# to be called with the actual value argument: function should return zero
# for rejection or any other value for selection.
sub info {
	local($hname, $tag, @what) = @_;
	local($file);						# DBR file associated with '$hname'
	local(@values);						# Attached values to the item
	local($_);
	($hname, $tag) = &default($hname, $tag);
	$file = $cf'hashdir . &hash_path($hname);
	return (0,0) unless -f "$file";
	unless (open(DBR, $file)) {
		&'add_log("ERROR could not open dbr file $file: $!") if $'loglvl;
		return (-1, 0);
	}
	local($linenum) = 0;				# Value of line if found
	local($timestamp) = 0;				# Associated time stamp
	&'acs_rqst($file);					# Lock file (avoid concurrent updating)
	while (<DBR>) {
		if (s/^(\S+)\s([\w-]+)\s(\d+)\t*//) {
			next unless $1 eq $hname;
			next unless $2 eq $tag;
			$linenum = $.;				# Record line number
			$timestamp = int($3);		# And timestamp
			last if &match;				# Found it if matches @what filter
			$timestamp = 0;				# Not found yet
		} else {						# Invalid entry
			&'add_log("ERROR $file corrupted, line $.") if $'loglvl;
			$timestamp = -1;			# Signals error
			last;						# Abort processing
		}
	}
	&'free_file($file);					# Remove lock on file
	close DBR;							# Close file
	($timestamp, $linenum, @values);	# Return item information
}

# Apply match from @what, and fill in @values as a side effect if matched.
sub match {
	local(@target) = split(/\t|\n/);	# Get values from line
	local($idx) = -1;					# Index within @target
	local($matched) = 1;				# Assume selection will match
	local($res);						# Eval result
	local($@);							# Eval error report string
	foreach $what (@what) {
		$idx++;							# Advance in @target
		next if $what eq '';			# Skip empty selection
		if ($what =~ m|^/|) {			# Regular expression
			$res = eval '$target[$idx] =~ ' . $what;
			&'add_log("WARNING dbr error: $@") if $@ && $'loglvl > 5;
			next if $@;
			$matched = $res;
		} elsif ($what =~ m|^&|) {		# Function to apply
			$res = eval "$what('" . $target[$idx] . "')";
			&'add_log("WARNING dbr error: $@") if chop($@) && $'loglvl > 5;
			next if $@;
			$matched = $res;
		} else {						# Regular string comparaison
			$matched = $target[$idx] eq $what;
		}
		last unless $matched;
	}
	@values = @target if $matched;		# Fill in values if selection ok
	$matched;							# Return matching status
}

# Update the entry ($hname, $tag) in file to hold the current timestamp. If the
# $linenum parameter is non-null, we know we may copy the old file until that
# line (excluded), then replace the current line with the new timestamp.
# If $linenum is null, then we may safely append the entry in the file. If
# the $linenum parameter is 'undef', then the user does not have it precomputed
# or wishes to have the line number re-computed.
# The new values held in @values replace the old ones for the entry. If 'undef'
# is given instead, then the corresponding entry is deleted from the database.
sub update {
	local($hname, $tag, $linenum, @values) = @_;
	local($now) = time;					# Current time
	local($file);						# DBR file associated with '$hname'
	local($_);
	($hname, $tag) = &default($hname, $tag);
	$file = $cf'hashdir . &hash_path($hname);
	unless (-f "$file") {
		local($dirname) = $file =~ m|^(.*)/.*|;
		&'makedir($dirname);
	}
	$linenum = (&info($hname, $tag))[1] unless defined($linenum);
	if ($linenum == 0) {				# No entry previously recorded
		return unless @values;			# Nothing to delete
		unless(open(DBR, ">>$file")) {
			&'add_log("ERROR cannot append in $file: $!") if $'loglvl;
			return;
		}
		&'acs_rqst($file);				# Lock file (avoid concurrent updating)
		print DBR "$hname $tag $now\t";	# The name, command tag and timestamp
		print DBR join("\t", @values);	# Associated values
		print DBR "\n";
		close DBR;
		&'free_file($file);				# Remove lock on file
	} else {							# An entry existed already
		unless (open(DBR, ">$file.x")) {
			&'add_log("ERROR cannot create $file.x: $!") if $'loglvl;
			return;
		}
		unless (open(OLD, "$file")) {
			&'add_log("ERROR couldn't reopen $file: $!") if $'loglvl;
			close DBR;
			return;
		}
		&'acs_rqst($file);				# Lock file (avoid concurrent updating)
		while (<OLD>) {
			if ($. < $linenum) {		# Before line to update
				print DBR;				# Print line verbatim
			} elsif ($. == $linenum) {	# We reached line to be updated
				next unless @values;
				print DBR "$hname $tag $now\t";
				print DBR join("\t", @values);
				print DBR "\n";
			} else {					# Past updating point
				print DBR;				# Print line verbatim
			}
		}
		close OLD;
		close DBR;
		unless (rename("$file.x", "$file")) {
			&'add_log("ERROR cannot rename $file.x to $file: $!") if $'loglvl;
		}
		&'free_file($file);				# Remove lock on file
	}
}

# Delete entry. This is really a wrapper to the more general update routine
# and is provided as a convenience only.
sub delete {
	local($hname, $tag, $linenum) = @_;
	&update($hname, $tag, defined($linenum) ? $linenum : undef, undef);
}

# Make sure the hashing name and the tag are correct, or use default values.
sub default {
	local($hname, $tag) = @_;
	$hname =~ s/^\s+//;					# Leading blanks would perturb dbr
	$hname =~ s/\s/_/g;					# All other spaces replaced by _
	$hname = 'X' unless $hname;			# Hashing name cannot be empty
	$tag =~ s/\s/_/g;					# Tag has to be a single word
	$tag = 'UNKNOWN' unless $tag;		# Tag cannot be empty
	($hname, $tag);
}

# Cleaning operation. Remove all the entries in the file whose timestamp is
# older than the supplied date limit.
sub clean {
	local($agemax) = @_;
	local($limit) = time - $agemax;		# Everything newer is kept
	&recursive_clean($cf'hashdir);		# Recursively scan directory
}

# Recursively scan the direcroy and deal with each file
sub recursive_clean {
	local($dir) = @_;					# Directory to scan
	local(@contents);					# Contents of the directory
	unless (opendir(DIR, $dir)) {
		&'add_log("ERROR cannot open directory $dir: $!") if $'loglvl > 1;
		return;
	}
	@contents = readdir(DIR);			# Slurp the whole thing
	closedir DIR;						# And close dir, ready for recursion
	local($_);
	foreach (@contents) {
		next if $_ eq '.' || $_ eq '..';
		if (-d "$dir/$_") {
			&recursive_clean("$dir/$_");
			next;
		}
		&clean_file("$dir/$_");
	}
	unless (opendir(DIR, $dir)) {
		&'add_log("ERROR cannot re-open directory $dir: $!") if $'loglvl > 1;
		return;
	}
	@contents = readdir(DIR);			# Slurp the whole thing
	closedir DIR;
	unless (@contents > 2) {			# Has at least . and ..
		unless (rmdir($dir)) {			# Don't leave empty directories
			&'add_log("SYSERR rmdir: $!") if $'loglvl;
			&'add_log("ERROR could not remove directory $dir") if $'loglvl;
		}
	}
}

# Clean single dbr file, using $limit as the oldest allowed time stamp
sub clean_file {
	local($file) = @_;			# File to be cleaned
	&'add_log("processing $file") if $'loglvl > 18;
	unless (open(FILE, $file)) {
		&'add_log("ERROR cannot open file $file: $!") if $'loglvl > 1;
		return;
	}
	unless (open(NEW, ">$file.x")) {
		&'add_log("ERROR cannot create $file.x: $!") if $'loglvl > 1;
		close FILE;
		return;
	}
	&'acs_rqst($file);			# Lock file to prevent concurrent mods
	local($warns) = 0;			# Avoid cascade warnings
	local($_, $.);
	while (<FILE>) {
		if (/^(\S+)\s([\w-]+)\s(\d+)\t*/) {
			# Variable $limit was set in 'clean'
			if ($3 > $limit) {			# File new enough
				next if (print NEW);	# Copy line verbatim
				&'add_log("SYSERR write: $!") if $'loglvl;
				&'add_log("WARNING truncated $file at line $.") if $'loglvl > 5;
				last;
			}
		} else {
			# Skip bad lines, up to a maximum of 10
			if (++$warns > 10) {
				&'add_log("WARNING $file truncated at line $.") if $'loglvl > 5;
				last;
			} else {
				&'add_log("NOTICE $file corrupted, line $.") if $'loglvl > 6;
				next;
			}
		}
	}
	close FILE;
	close NEW;
	unless (rename("$file.x", $file)) {
		&'add_log("ERROR cannot rename $file.x to $file: $!") if $'loglvl;
	}
	unless (-s "$file") {
		unless (unlink($file)) {	# Don't leave empty files behind
			&'add_log("SYSERR unlink: $!") if $'loglvl;
			&'add_log("ERROR could not remove $file") if $'loglvl;
		}
	}
	&'free_file($file);				# Remove lock on file
}

package main;

