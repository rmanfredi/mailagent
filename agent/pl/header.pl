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
;# $Log: header.pl,v $
;# Revision 3.0.1.3  2001/03/13 13:14:01  ram
;# patch71: added rule to suppress () and {} in message ids
;#
;# Revision 3.0.1.2  2001/01/10 16:55:29  ram
;# patch69: new mta_date() routine replaces old fake_date()
;# patch69: added msgid_cleanup() and parsedate() routines
;#
;# Revision 3.0.1.1  1994/07/01  15:00:51  ram
;# patch8: fixed leading From date format (spacing problem)
;#
;# Revision 3.0  1993/11/29  13:48:49  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
package header;

# This package implements a header checker. To initialize it, call 'reset'.
# Then, call 'valid' with a header line and the function returns 0 if the
# line is not part of a header (which means all the lines seen since 'reset'
# are not part of a mail header). If the line may still be part of a header,
# returns 1. Finally, -1 is returned at the end of the header.

sub init {
	# Main header fields which should be looked at when parsing a mail header
	%Mailheader = (
		'From', 1,
		'To', 1,
		'Subject', 1,
		'Date', 1,
	);
}

# Reset header checking status
sub reset {
	&init unless $init_done++;		# Initialize private data
	$last_was_header = 0;			# Previous line was not a header
	$maybe = 0;						# Do we have a valid part of header?
	$line = 0;						# Count number of lines in header
}

# Is the current line still part of a valid header ?
sub valid {
	local($_) = @_;
	return 1 if $last_was_header && /^\s/;	# Continuation line
	return -1 if /^$/;						# End of header
	$last_was_header = /^([\w\-]+):/ ? 1 : 0;
	# Activate $maybe when essential parts of a valid mail header are found
	# Any client can check 'maybe' to see if what has been parsed so far would
	# be a valid RFC-822 header, even though syntactically correct.
	$maybe |= $Mailheader{$1} if $last_was_header;
	$last_was_header = /^From\s+\S+/
		unless $last_was_header || $line;	# First line may be special
	++$line;								# One more line
	$last_was_header;						# Are we still inside header?
}

# Produce a warning header field about a specific item
sub warning {
	local($field, $added) = @_;
	local($warning);
	local(@field) = split(' ', $field);
	$warning = 'X-Filter-Note: ';
	if ($added && @field == 1) {
		$warning .= "Header $field added at ";
	} elsif ($added && @field > 1) {
		$field = join(', ', @field);
		$field =~ s/^(.*), (.*)/$1 and $2/;
		$warning .= "Headers $field added at ";
	} else {
		$warning .= "Parsing error in original previous line at ";
	}
	$warning .= &main'domain_addr;
	$warning;
}

# Make sure header contains vital fields. The header is held in an array, on
# a line basis with final new-line chopped. The array is modified in place,
# setting defaults from the %Header array (if defined, which is the case for
# digests mails) or using local defaults.
sub clean {
	local(*array) = @_;					# Array holding the header
	local($added) = '';					# Added fields

	$added .= &check(*array, 'From', $cf'user, 1);
	$added .= &check(*array, 'To', $cf'user, 1);
	$added .= &check(*array, 'Date', &mta_date(), 0);
	$added .= &check(*array, 'Subject', '<none>', 1);

	&push(*array, &warning($added, 1)) if $added ne '';
}

# Check presence of specific field and use value of %Header as a default if
# available and if '$use_header' is set, otherwise use the provided value.
# Return added field or a null string if nothing is done.
sub check {
	local(*array, $field, $default, $use_header) = @_;
	local($faked);						# Faked value to be used
	if ($use_header) {
		$faked = (defined $'Header{$field}) ? $'Header{$field} : $default;
	} else {
		$faked = $default;
	}

	# Try to locate field in header
	local($_);
	foreach (@array) {
		return '' if /^$field:/;
	}

	&push(*array, "$field: $faked");
	$field . ' ';
}

# Push header line at the end of the array, without assuming any final EOH line
sub push {
	local(*array, $line) = @_;
	local($last) = pop(@array);
	push(@array, $last) if $last ne '';	# There was no EOH
	push(@array, $line);				# Insert header line
	push(@array, '') if $last eq '';	# Restore EOH
}

# Compute a valid date field suitable for mail header:
#    Mon,  8 Jan 2001 05:14:00 +0100
# If optional $time arg is missing, use current time.
sub mta_date {
	my ($time) = @_;
	$time = time unless defined $time;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	my ($gmmin, $gmhour, $gmyday) = (gmtime($time))[1,2,7];
	my @days   = qw(Sun Mon Tue Wed Thu Fri Sat);
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

	# Compute delta in minutes between local time and GMT
	$yday = -1 if $gmyday == 0 && $yday >= 364;
	$gmyday = -1 if $yday == 0 && $gmyday >= 364;
	$gmhour += 24 if $gmyday > $yday;
	my $dhour = ($gmyday < $yday) ? $hour + 24 : $hour;
	my $dmin = ($dhour * 60 + $min) - ($gmhour * 60 + $gmmin);

	# Must convert delta into +/-HHMM format
	my $d = 100 * int($dmin / 60) + (abs($dmin) % 60) * ($dmin > 0 ? 1 : -1);

	sprintf "%s, %2d %s %4d %02d:%02d:%02d %+05d",
		$days[$wday], $mday, $months[$mon], 1900+$year, $hour, $min, $sec, $d;
}

# Normalizes header: every first letter is uppercase, the remaining of the
# word being lowercased, as in This-Is-A-Normalized-Header. Note that RFC-822
# does not impose such a formatting.
sub normalize {
	local($field_name) = @_;			# Header to be normalized
	$field_name =~ s/(\w+)/\u\L$1/g;
	$field_name;						# Return header name with proper case
}

# Clean-up message ID string passed as reference.
# Returns true if string was changed.
sub msgid_cleanup {
	my $mref = shift;
	local $_ = $$mref;
	my $fixup = 0;

	# Regexps are written to work on both a single <id> as found in Message-ID
	# lines, and on a space-separated list as found in References lines.

	s/>\s</>\01</g;				# Protect spaces between IDs for References
	$fixup++ if s/\s/-/g;		# No spaces
	$fixup++ if s/_/-/g;		# No _ in names
	$fixup++ if s/[(){}]//g;	# No () nor {} in names and ID
	$fixup++ if s/\.+>/>/g;		# No trailing dot(s)
	$fixup++ if s/\.\.+/./g;	# No consecutive dots
	s/>\01</> </g;				# Restore spaces between IDs
	$$mref = $_ if $fixup;
	return $fixup;
}

# Parse date from header and return its timestamp (seconds since the Epoch)
sub parsedate {
	my ($str) = @_;

	# Look for +/-HHMM adjustment wrt GMT time
	my ($sign, $hh_d, $mm_d) = $str =~ /\s([-+])(\d\d)(\d\d)\b/;
	my $dt = 0;
	$dt = (($sign eq '+') ? +1 : -1) * ($hh_d * 60 + $mm_d) if $sign ne '';

	# Parse date to compute timestamp since Jan 1, 1970 GMT.
	return main::getdate($str, time, -$dt);
}

# Format header field to fit into 78 columns, each continuation line being
# indented by 8 chars. Returns the new formatted header string.
sub format {
	local($field) = @_;			# Field to be formatted
	local($tmp);				# Buffer for temporary formatting
	local($new) = '';			# Constructed formatted header
	local($kept);				# Length of current line
	local($len) = 78;			# Amount of characters kept
	local($cont) = ' ' x 8;		# Continuation lines starts with 8 spaces
	# Format header field, separating lines on ',' or space.
	while (length($field) > $len) {
		$tmp = substr($field, 0, $len);		# Keep first $len chars
		$tmp =~ s/^(.*)([,\s]).*/$1$2/;		# Cut at last space or ,
		$kept = length($tmp);				# Amount of chars we kept
		$tmp =~ s/\s*$//;					# Remove trailing spaces
		$tmp =~ s/^\s*//;					# Remove leading spaces
		$new .= $cont if $new;				# Continuation starts with 8 spaces
		$len = 70;							# Account continuation for next line
		$new .= "$tmp\n";
		$field = substr($field, $kept, 9999);
	}
	$new .= $cont if $new;					# Add 8 chars if continuation
	$new .= $field;							# Remaining information on one line
}

# Scan the head of a file and try to determine whether there is a mail
# header at the beginning or not. Return true if a header was found.
sub main'header_found {
	local($file) = @_;
	local($correct) = 1;				# Were all the lines from top correct ?
	local($_);
	open(FILE, $file) || return 0;		# Don't care to report error
	&reset;								# Initialize header checker
	while (<FILE>) {					# While still in a possible header
		last if /^$/;					# Exit if end of header reached
		$correct = &valid($_);			# Check line validity
		last unless $correct;			# No, not a valid header
	}
	close FILE;
	$correct;
}

package main;

