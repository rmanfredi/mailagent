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
;# $Log: matching.pl,v $
;# Revision 3.0.1.5  2001/03/17 18:12:50  ram
;# patch72: fixed longstanding lie in man; "To: gue@eiffel.fr" now works
;#
;# Revision 3.0.1.4  1999/07/12  13:52:50  ram
;# patch66: specialized <3> to mean <3,3> in mrange()
;#
;# Revision 3.0.1.3  1996/12/24  14:56:12  ram
;# patch45: new Envelope and Relayed selectors
;# patch45: protect all un-escaped @ in patterns, for perl5
;#
;# Revision 3.0.1.2  1994/07/01  15:02:33  ram
;# patch8: allow macro substitution on patterns if rulemac is ON
;#
;# Revision 3.0.1.1  1994/04/25  15:17:49  ram
;# patch7: fixed selector combination logic and added some debug logs
;#
;# Revision 3.0  1993/11/29  13:49:00  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Matching functions
#

# List of special header selector, for which a pattern without / is to be
# taken as an equality with the login name of the address. If there are some
# metacharacters, then a match will be attempted on that name. For each of
# those special headers, we record the name of the subroutine to be called.
# If a matching function is not specified, the default is 'match_var'.
# The %Amatcher gives the name of the fields which contains an address.
sub init_matcher {
	%Matcher = (
		'Envelope',			'match_single',
		'From',				'match_single',
		'To',				'match_list',
		'Cc',				'match_list',
		'Apparently-To',	'match_list',
		'Newsgroups',		'match_list',
		'Sender',			'match_single',
		'Resent-From',		'match_single',
		'Resent-To',		'match_list',
		'Resent-Cc',		'match_list',
		'Resent-Sender',	'match_single',
		'Reply-To',			'match_single',
		'Relayed',			'match_list',
	);
	%Amatcher = (
		'From',				1,
		'Envelope',			1,
		'To',				1,
		'Cc',				1,
		'Apparently-To',	1,
		'Sender',			1,
		'Resent-From',		1,
		'Resent-To',		1,
		'Resent-Cc',		1,
		'Resent-Sender',	1,
		'Reply-To',			1,
	);
}

# Transform a shell-style pattern into a perl pattern
sub perl_pattern {
	local($_) = @_;		# The shell pattern
	s/\./\\./g;			# Escape .
	s/\*/.*/g;			# Transform * into .*
	s/\?/./g;			# Transform ? into .
	$_;					# Perl pattern
}

# Take a pattern as written in the rule file and make it suitable for
# pattern matching as understood by perl. If the pattern starts with a
# leading /, nothing is done. Otherwise, a set of / are added.
# match (1st case).
sub make_pattern {
	local($_) = shift(@_);
	unless (m|^/|) {				# Pattern does not start with a /
		$_ = &perl_pattern($_);		# Simple words specified via shell patterns
		$_ = "/^$_\$/";				# Anchor pattern
	}
	# The whole pattern is inserted within () to make at least one
	# backreference. Otherwise, the following could happen:
	#    $_ = '1 for you';
	#    @matched = /^\d/;
	#    @matched = /^(\d)/;
	# In both cases, the @matched array is set to ('1'), with no way to
	# determine whether it is due to a backreference (2nd case) or a sucessful
	# match. Knowing we have at least one bracketed reference is enough to
	# disambiguate.
	s|^/(.*)/|/($1)/|;		# Enclose whole pattern within ()
	$_;						# Pattern suitable for eval'ed matching
}

# ### Main matching entry point ###
# ### (called from &apply_rules in pl/analyze.pl)
# Attempt a match of a set of pattern, for each possible selector. The selector
# string given can contain multiple selectors separated by white spaces.
sub match {
	local($selector) = shift(@_);	# The selector on which pattern applies
	local($pattern) = shift(@_);	# The pattern or script to apply
	local($range) = shift(@_);		# The range on which pattern applies
	local($matched) = 0;			# Matching status returned
	# If the pattern is held within double quotes, it is assumed to be the name
	# of a file from which patterns may be found (one per line, shell comments
	# being ignored).
	if ($pattern !~ /^"/) {
		$matched = &apply_match($selector, $pattern, $range);
	} else {
		# Load patterns from file whose name is given between "quotes"
		# All un-escaped @ in patterns are escaped for perl5.
		local(@filepat) = &include_file($pattern, 'pattern');
		grep(s/([^\\](\\\\)*)@/$1\\@/g && undef, @filepat);
		# Now do the match for all the patterns. Stop as soon as one matches.
		foreach (@filepat) {
			$matched = &apply_match($selector, $_, $range);
			last if $matched;
		}
	}
	$matched ? 1 : 0;		# Return matching status (guaranteed numeric)
}

# Attempt a pattern match on a set of selectors, and set the special macro %&
# to the name of the regexp-specified fields which matched.
sub apply_match {
	local($selector) = shift(@_);	# The selector on which pattern applies
	local($pattern) = shift(@_);	# The pattern or script to apply
	local($range) = shift(@_);		# The range on which pattern applies
	local($matched) = 0;			# True when a matching occurred
	local($inverted) = 0;			# True whenever all '!' match succeeded
	local($invert) = 1;				# Set to false whenever a '!' match fails
	local($match);					# Matching status reported
	local($not) = '';				# Shall we negate matching status?
	if ($selector eq 'script') {	# Pseudo header selector
		$matched = &evaluate(*pattern);
	} else {						# True header selector

		# There can be multiple selectors separated by white spaces. As soon as
		# one of them matches, we stop and return true. A selector may contain
		# metacharacters, in which case a regular pattern matching is attempted
		# on the true *header* fields (i.e. we skip the pseudo keys like Body,
		# Head, etc..). For instance, Return.* would attempt a match on the
		# field Return-Receipt-To:, if present. The special macro %& is set
		# to the list of all the fields on which the match succeeded
		# (alphabetically sorted).

		foreach $select (split(/ /, $selector)) {
			$not = '';
			$select =~ s/^!// && ($not = '!');
			# Allowed metacharacters are listed here (no braces wanted)
			if ($select =~ /\.|\*|\[|\]|\||\\|\^|\?|\+|\(|\)/) {
				$match = &expr_selector_match($select, $pattern, $range);
			} else {
				$match = &selector_match($select, $pattern, $range);
			}
			if ($not) {								# Negated test
				$invert = !$match if $invert;		# '!' tests AND'ed
				$inverted = $invert;				# Meaningful from now on
			} else {
				$matched = $match;					# Normal tests OR'ed
			}
			last if $matched;		# Stop when matching status known
		}
	}
	$matched = $matched || $inverted;
	if ($loglvl > 19) {
		local($logmsg) = "applied '$pattern' on '$selector' ($range) was ";
		$logmsg .= $matched ? "true" : "false";
		&add_log($logmsg);
	}
	$matched;						# Return matching status
}

# Attempt a pattern match on a set of selectors, and set the special macro %&
# to the name of the field which matched. If there is more than one such
# selector, values are separated using comas. If selector is preceded by a '!',
# then the matching status is negated and *all* the tested fields are recorded
# within %& when the returned status is 'true'.
sub expr_selector_match {
	local($selector) = shift(@_);	# The selector on which pattern applies
	local($pattern) = shift(@_);	# The pattern or script to apply
	local($range) = shift(@_);		# The range on which pattern applies
	local($matched) = 0;			# True when a matching occurred
	local(@keys) = sort keys %Header;
	local($match);					# Local matching status
	local($not) = '';				# Shall boolean value be negated?
	local($orig_ampersand) = $macro_ampersand;	# Save %&
	$selector =~ s/^!// && ($not = '!');
	&add_log("field '$selector' has metacharacters") if $loglvl > 18;
	field: foreach $key (@keys) {
		next if $Pseudokey{$key};		# Skip Body, All...
		&add_log("'$select' tried on '$key'") if $loglvl > 19;
		next unless eval '$key =~ /' . $select . '/';
		$match = &selector_match($key, $pattern, $range);
		$matched = 1 if $match;			# Only one match needed
		# Record matching field for futher reference if a match occurred and
		# the selector does not start with a '!'. Record all the tested fields
		# if's starting with a '!' (because that's what is interesting in that
		# case). In that last case, the original macro will be restored if any
		# match occurs.
		if ($not || $match) {
			$macro_ampersand .= ',' if $macro_ampersand;
			$macro_ampersand =~ s/;,$/;/;
			$macro_ampersand .= $key;
		}
		if ($match) {
			&add_log("obtained match with '$key' field")
				if $loglvl > 18;
			next field;				# Try all the matching selectors
		}
		&add_log("no match with '$key' field") if $loglvl > 18;
	}
	$macro_ampersand .= ';';		# Set terminated with a ';'
	# No need to negate status if selector was preceded by a '!': this will
	# be done by apply match.
	$macro_ampersand = $orig_ampersand if $not && $matched;	# Restore %&
	&add_log("matching status for '$selector' ($range) is '$matched'")
		if $loglvl > 18;
	$matched;						# Return matching status
}

# Attempt a match of a pattern against a selector, return boolean status.
# If pattern is preceded by a '!', the boolean status is negated.
# If the 'rulemac' configuration variable is set to ON, a macro substitution
# is performed on the search pattern.
sub selector_match {
	local($selector) = shift(@_);	# The selector on which pattern applies
	local($pattern) = shift(@_);	# The pattern to apply
	local($range) = shift(@_);		# The range on which pattern applies
	local($matcher);				# Subroutine used to do the match
	local($matched);				# Record matching status
	local($not) = '';				# Shall we apply NOT on matching result?
	$selector = &header'normalize($selector);	# Normalize case
	$matcher = $Matcher{$selector};
	$matcher = 'match_var' unless $matcher;
	$pattern =~ s/^!// && ($not = '!');
	&macros_subst(*pattern) if $cf'rulemac =~ /on/i;	# Macro substitution
	$matched = &$matcher($selector, $pattern, $range);
	$matched = !$matched if $not;	# Revert matching status if ! pattern
	if ($loglvl > 19) {
		local($logmsg) = "matching '$not$pattern' on '$selector' ($range) was ";
		$logmsg .= $matched ? "true" : "false";
		&add_log($logmsg);
	}
	$matched;				# Return matching status
}

# Pattern matching functions:
#	They are invoked as function($selector, $pattern, $range) and return true
#	if the pattern is found in the variable, according to some internal rules
#	which are different among the functions. For instance, match_single will
#	attempt a match with a login name or a regular pattern matching on the
#	whole variable if the pattern was not a single word.

# Matching is done in a header which only contains an internet address. The
# $range parameter is ignored (does not make any sense here). An optional 4th
# parameter may be supplied to specify the matching buffer. If absent, the
# corresponding header line is used -- this feature is used by &match_list.
sub match_single {
	local($selector, $pattern, $range, $buffer) = @_;
	local($login) = 0;				# Set to true when attempting login match
	local(@matched);
	unless (defined $buffer) {		# No buffer for matching was supplied
		$buffer = $Header{$selector};
	}
	#
	# If we attempt a match on a field holding e-mail addresses and the pattern
	# is anchored at the beginning with a /^, then we only keep the address
	# part and remove the comment if any.
	#
	# If the field holds a full e-mail address and only that, we automatically
	# select the address part of the field for matching. -- RAM, 17/03/2001
	#
	# Otherwise, the field is left alone.
	#
	# If the pattern is only a single name, we extract the login name for
	# matching purposes...
	#
	if ($Amatcher{$selector}) {					# Field holds an e-mail address
		if (
			$pattern =~ m|^/\^| ||
			$pattern =~ m|^[-\w.*?]+(\\\@[-\w.*?]+)?\s*$|
		) {
			$buffer = (&parse_address($buffer))[0];
			&add_log("matching buffer reduced to '$buffer'") if $loglvl > 18;
		}
		if ($pattern =~ m|^[-\w.*?]+\s*$|) {	# Single name may have - or .
			$buffer = &login_name($buffer);		# Match done only on login name
			$pattern =~ tr/A-Z/a-z/;	# Cannonicalize name to lower case
		}
		$login = 1 unless $pattern =~ m|^/|;	# Ask for case-insensitive match
	}
	$buffer =~ s/^\s+//;				# Remove leading spaces
	$buffer =~ s/\s+$//;				# And trailing ones
	$pattern = &make_pattern($pattern);
	$pattern .= "i" if $login;			# Login matches are case-insensitive
	@matched = eval '($buffer =~ ' . $pattern . ');';
	# If buffer is empty, we have to recheck the pattern in a non array context
	# to see if there is a match. Otherwise, /(.*)/ does not seem to match an
	# empty string as it returns an empty string in $matched[0]...
	$matched[0] = eval '$buffer =~ ' . $pattern if $buffer eq '';
	&eval_error;						# Make sure eval worked
	&update_backref(*matched);			# Record non-null backreferences
	$matched[0];						# Return matching status
}

# Matching is done on a header field which may contains multiple addresses
# This will not work if there is a ',' in the comment part of the addresses,
# but I never saw that and I don't want to write complex code for that--RAM.
# If a range is specified, then only the items specified by the range are
# actually used.
sub match_list {
	local($selector, $pattern, $range) = @_;
	local($_) = $Header{$selector};	# Work on a copy of the line
	tr/\n/ /;						# Make one big happy line
	local(@list) = split(/,/);		# List of addresses
	local($min, $max) = &mrange($range, scalar(@list));
	return 0 unless $min;			# No matching possible if null range
	local($buffer);					# Buffer on which pattern matching is done
	local($matched) = 0;			# Set to true when matching has occurred
	@list = @list[$min - 1 .. ($max > $#list ? $#list : $max - 1)]
		if $min != 1 || $max != 9_999_999;
	foreach $buffer (@list) {
		# Call match_single to perform the actual match and supply the matching
		# buffer as the last argument. Note that since range does not make
		# any sense for single matches, undef is passed on instead.
		$matched = &match_single($selector, $pattern, undef, $buffer);
		last if $matched;
	}
	$matched;
}

# Look for a pattern in a multi-line context
sub match_var {
	local($selector, $pattern, $range) = @_;
	local($lines) = 0;					# Number of lines in matching buffer
	if ($range ne '<1,->') {			# Optimize: count lines only if needed
		$lines = $Header{$selector} =~ tr/\n/\n/;
	}
	local($min, $max) = &mrange($range, $lines);
	return 0 unless $min;				# No matching possible if null range
	local($buffer);						# Buffer on which matching is attempted
	local(@buffer);						# Same, whith range line selected
	local(@matched);
	$pattern = &make_pattern($pattern);
	# Optimize, since range selection is the exception and not the rule.
	# Most likely, we use the default selection, i.e. we take everything...
	if ($min != 1 || $max != 9_999_999) {
		@buffer = split(/\n/, $Header{$selector});
		@buffer = @buffer[$min - 1 .. ($max > $#buffer ? $#buffer : $max - 1)];
		$buffer = join("\n", @buffer);		# Keep only selected lines
		undef @buffer;						# May be big, so free ASAP
	} else {
		$buffer = $Header{$selector};
	}
	# Ensure multi-line matching by adding trailing "m" option to pattern
	@matched = eval '($buffer =~ ' . $pattern . 'm);';
	# If buffer is empty, we have to recheck the pattern in a non array context
	# to see if there is a match. Otherwise, /(.*)/ does not seem to match an
	# empty string as it returns an empty string in $matched[0]...
	$matched[0] = eval '$buffer =~ ' . $pattern . 'm' if $buffer eq '';
	&eval_error;						# Make sure eval worked
	&update_backref(*matched);			# Record non-null backreferences
	$matched[0];						# Return matching status
}

#
# Backreference handling
#

# Reseet the backreferences at the beginning of each rule match attempt
# The backreferences include %& and %1 .. %99.
sub reset_backref {
	$macro_ampersand = '';			# List of matched generic selector
	@Backref = ();					# Stores backreferences provided by perl
}

# Update the backward reference array. There is a maximum of 99 backreferences
# per filter rule. The argument list is an array of all the backreferences
# found in the pattern matching, but the first item has to be skipped: it is
# the whole matching string -- see comment on make_pattern().
sub update_backref {
	local(*array) = @_;				# Array holding $1 .. $9, $10 ..
	local($i, $val);
	for ($i = 1; $i < @array; $i++) {
		$val = $array[$i];
		push(@Backref, $val);		# Stack backreference for later perusal
		&add_log("stacked '$val' as backreference") if $loglvl > 18;
	}
}

#
# Range interpolation
#

# Return minimum and maximum for range value. A range is specified as <min,max>
# but '-' may be used as min for 1 and max as a symbolic constant for the
# maximum value. An arbitrarily large number is returned in that case. If a
# negative value is used, it is added to the number of items and rounded towards
# 1 if still negative. That way, it is possible to request the last 10 items.
# As a special case, <3> stands for <3,3> and thus <-> means everything.
sub mrange {
	local($range, $items) = @_;
	local($min, $max) = (1, 9_999_999);
	local($rmin, $rmax);
	$rmin = $rmax = $1 if $range =~ /<\s*([\d-]+)\s*>/;
	($rmin, $rmax) = $range =~ /<\s*([\d-]*)\s*,\s*([\d-]*)\s*>/
		unless defined $rmin;
	$rmin = $min if $rmin eq '' || $rmin eq '-';
	$rmax = $max if $rmax eq '' || $rmax eq '-';
	$rmin = $rmin + $items + 1 if $rmin < 0;
	$rmax = $rmax + $items + 1 if $rmax < 0;
	$rmin = 1 if $rmin < 0;
	$rmax = 1 if $rmax < 0;
	($rmin, $rmax) = (0, 0) if $rmin > $rmax;	# Null range if min > max
	return ($rmin, $rmax);
}

