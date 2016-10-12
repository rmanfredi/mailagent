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
;# $Log: lexical.pl,v $
;# Revision 3.0.1.4  1997/01/31  18:07:55  ram
;# patch54: esacape metacharacter '{' in regexps for perl5.003_20
;#
;# Revision 3.0.1.3  1995/02/03  18:01:58  ram
;# patch30: rule parsing could end-up prematurely when facing hook files
;#
;# Revision 3.0.1.2  1995/01/25  15:22:58  ram
;# patch27: added automatic @ escape in patterns for perl 5.0
;#
;# Revision 3.0.1.1  1994/09/22  14:24:44  ram
;# patch12: added logging at level 25 to debug lexer
;# patch12: better mismatched braces handling
;#
;# Revision 3.0  1993/11/29  13:48:55  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
#
# Lexical parsing of the rules
#

# The following subroutine is called whenever a new rule input is needed.
# It returns that new line or a null string if end of file has been reached.
sub read_filerule {
	<RULES>;					# Read a new line from file
}

# The following subroutine is called in place of read_rule when rules are
# coming from the command line via @Linerules.
sub read_linerule {
	$.++;						# One more line
	shift(@Linerules);			# Read a new line from array
}

# Assemble a whole rule in one line and return it. The end of a line is
# marked by a ';' at the end of an input line.
sub get_line {
	&add_log("IN get_line") if $loglvl > 24;
	local($result) = "";		# what will be returned
	local($in_braces) = 0;		# are we inside braces ?
	for (;;) {
		$_ = &read_rule;		# new rule line (pseudo from compile_rules)
		last unless defined $_;	# end of file reached
		&add_log("READ <<$_>>") if $loglvl > 24;
		s/\n$//;				# don't use chop in case we read from array
		next if /^\s*#/;		# skip comments
		next if /^\s*$/;		# skip empty lines
		s/\s\s+/ /;				# reduce white spaces
		s/#\s.*$//;				# trailing comments skipped (need space after #)
		$result .= $_;
		# Very simple braces handling
		$in_braces += tr/{/{/ - tr/}/}/;
		last if $in_braces <= 0 && /;\s*$/;
	}
	&add_log("OUT get_line: $result") if $loglvl > 24;
	$result;
}

# Get optional mode (e.g. <TEST>) at the beginning of the line and return
# it, or ALL if none was present. A mode can be negated by pre-pending a '!'.
sub get_mode {
	&add_log("IN get_mode") if $loglvl > 24;
	local(*line) = shift(@_);	# edited in place
	local($_) = $line;			# make a copy of original
	local($mode) = "ALL";		# default mode
	s/^\s*<([\s\w,!]+)>// && ($mode = $1);
	$mode =~ s/\s//g;			# no spaces in returned mode
	$line = $_;					# eventually updates the line
	&add_log("OUT get_mode: $mode") if $loglvl > 24;
	$mode;
}

# A selector is either a script or a list of header fields ending with a ':'.
sub get_selector {
	&add_log("IN get_selector") if $loglvl > 24;
	local(*line) = shift(@_);	# edited in place
	local($_) = $line;			# make a copy of original
	local($selector) = "";
	s/^\s*,//;					# remove rule separator
	if (/^\s*\[\[/) {			# detected a script form
		$selector = 'script:';
	} else {
		s/^\s*([^\/,{\n]*(<[\d\s,-]+>)?\s*:)// && ($selector = $1);
	}
	$line = $_;					# eventually updates the line
	&add_log("OUT get_selector: $selector") if $loglvl > 24;
	$selector;
}

# A pattern if either a single word (with no white space) or something
# starting with a / and ending with an un-escaped / followed by some optional
# modifiers.
# Patterns may be preceded by a single '!' to negate the matching value.
sub get_pattern {
	&add_log("IN get_pattern") if $loglvl > 24;
	local(*line) = shift(@_);		# edited in place
	local($_) = $line;				# make a copy of original
	local($pattern) = "";			# the recognized pattern
	local($buffer) = "";			# the buffer used for parsing
	local($not) = '';				# shall boolean value be negated?
	local($script) = 0;				# true if pattern is a script
	s|^\s*||;						# remove leading spaces
	s/^!// && ($not = '!');			# A leading '!' inverts matching status
	if (s|^\[\[([^{]*)\]\]||) {		# pattern is a script
		$pattern = $1;				# get the whole script
		$script++;					# mark it as a script
	} elsif (s|^/||) {				# pattern starts with a /
		$pattern = "/";				# record the /
		while (s|([^/]*/)||) {		# while there is something before a /
			$buffer = $1;			# save what we've been reading
			$pattern .= $1;
			last unless $buffer =~ m|\\/$|;	# finished unless / is escaped
		}
		s/^(\w+)// && ($pattern .= $1);		# add optional modifiers
	} else {								# pattern does not start with a /
		s/([^\s,;{]*)// && ($pattern = $1);	# grab all until next delimiter
	}
	$line = $_;					# eventually updates the line
	$pattern =~ s/\s+$//;		# remove trailing spaces

	# In perl 4.0, we could write /^ram@acri\.fr/, but in perl 5.0, that
	# is not allowed since @ is now interpolated in patterns and strings.
	# In order to let them still write things that way, or escape the @
	# if they don't mind, we replace all un-escaped @ by escaped ones.

	$pattern =~ s/([^\\](\\\\)*)@/$1\\@/g unless $script;

	if ($not && !$pattern) {
		&add_log("ERROR discarding '!' not followed by pattern") if $loglvl;
	} else {
		$pattern = $not . $pattern;
	}
	&add_log("OUT get_pattern: $pattern") if $loglvl > 24;
	$pattern;
}

# Extract the action part from the line (by editing it in place) and return
# the first action encountered. Nesting of {...} blocks may occur.
sub get_action {
	&add_log("IN get_action") if $loglvl > 24;
	local(*line) = shift(@_);	# edited in place
	local($_) = $line;			# make a copy of original
	unless (s/^\s*\{/{/) {
		&add_log("OUT get_action (none)") if $loglvl > 24;
		return '';
	}
	local($action) = &action_parse(*_, 0);
	&add_log("ERROR no action, discarding '$_'") if $loglvl && $action eq '';
	$line = $_;					# eventually update the line
	$action =~ s/^\{\s*//;		# remove leading and trailing braces
	$action =~ s/\s*\}$//;
	&add_log("OUT get_action: $action") if $loglvl > 24;
	$action;					# return new action block
}

# Recursively parse the action string and return the parsed portion of the text
# with proper nesting wherever necessary. The string given as parameter is
# edited in place and the remaining is the unparsed part.
sub action_parse {
	local(*_) = shift(@_);		# edited in place
	local($level) = shift(@_);	# recursion level
	&add_log("IN action_parse $level: $_") if $loglvl > 24;
	local($parsed) = '';		# the part we parsed so far
	local($block);				# block recognized
	local($follow);				# recursion string returned

	for (;;) {
		# Go to first un-escaped '{', if possible and save leading string
		# up-to first '{'. Note that any '}' immediately stops scanning.
		s/^(([^\\{}]|\\.)*\{)// && ($parsed .= $1);
		# Go to first un-escaped '}', with any '{' stopping scan.
		$block = '';
		s/^(([^\\{}]|\\.)*\})// && ($block = $1);
		$parsed .= $block;		# block may be empty, or has trailing '}'
		&add_log("action_parse $level: $parsed") if $loglvl > 24;
		if ($parsed =~ s/\{$//) {	# recursion if '{' found
			$follow = &action_parse(*_, $level + 1);
			# If a null string is returned, then no matching '}' was found
			&add_log("WARNING no closing brace (added for you)")
				if $follow eq '' && $loglvl > 5;
			$parsed .= '{' . $follow . '}';
		} elsif (s/^\}//) {		# reached end of a block
			&add_log("WARNING extra closing brace ignored")
				if $level == 0 && $loglvl > 5;
			&add_log("OUT action_parse $level: $parsed") if $loglvl > 24;
			return $parsed;
		} else {
			# Get the whole string until the next '}' and return. If a '{'
			# interposes, the first match will return an empty string. In that
			# case, we continue if we are not at level #0. Otherwise we got the
			# whole action and may return now.
			$block = '';
			s/^(([^\\{}]|\\.)*\})// && ($block = $1);
			if ($block eq '' && $level) {		# Advance until '{'
				s/^(([^\\}]|\\.)*\{)// && ($block = $1);
				$parsed .= $block;
				last if $block eq '';	# Reached the end... prematurely!
				next;
			}
			$block =~ s/\}//;
			&add_log("OUT action_parse $level: $parsed$block") if $loglvl > 24;
			return $parsed . $block;
		}
	}

	&add_log("WARNING mismatched braces in rule file") if $loglvl > 5;
	&add_log("OUT action_parse $level: $parsed <EOF>") if $loglvl > 24;
	return $parsed;
}

