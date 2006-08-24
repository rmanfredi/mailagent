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
;# $Log: analyze.pl,v $
;# Revision 3.0.1.9  1999/07/12  13:49:39  ram
;# patch66: moved localization of the %Variable hash for APPLY
;#
;# Revision 3.0.1.8  1997/09/15  15:13:15  ram
;# patch57: $lastcmd now global from analyze_mail() for BACK processing
;# patch57: indication of relaying hosts now selectively emitted
;#
;# Revision 3.0.1.7  1997/01/31  18:07:47  ram
;# patch54: esacape metacharacter '{' in regexps for perl5.003_20
;#
;# Revision 3.0.1.6  1996/12/24  14:47:17  ram
;# patch45: forgot to return 0 at the end of special_user()
;#
;# Revision 3.0.1.5  1995/01/03  18:06:33  ram
;# patch24: now makes use of rule environment vars from the env package
;# patch24: removed old broken umask handling (now a part of rule env)
;#
;# Revision 3.0.1.4  1994/09/22  14:09:03  ram
;# patch12: defines new folder_saved variable to store folder path
;#
;# Revision 3.0.1.3  1994/07/01  14:59:58  ram
;# patch8: general umask is now reset before analyzing a message
;# patch8: added support for the UMASK command for local rule scope
;# patch8: now parses the new tome config variable for vacation messages
;# patch8: disable vacation message if Illegal-Object or Illegal-Field header
;#
;# Revision 3.0.1.2  1994/04/25  15:17:24  ram
;# patch7: fixed selector combination logic and added some debug logs
;#
;# Revision 3.0.1.1  1994/01/26  09:30:23  ram
;# patch5: now understands new -F option to force processing
;#
;# Revision 3.0  1993/11/29  13:48:35  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Analyzing mail
#

# Special users. Note that as login name matches are done in a case-insensitive
# manner, there is no need to upper-case any of the followings.
sub init_special {
	%Special = (
		'root', 1,				# Super-user
		'uucp', 1,				# Unix to Unix copy
		'daemon', 1,			# Not a real user, hopefully
		'news', 1,				# News daemon
		'postmaster', 1,		# X-400 mailer-daemon name
		'newsmaster', 1,		# My convention for news administrator--RAM
		'usenet', 1,			# Aka newsmaster
		'mailer-daemon', 1,		# Sendmail
		'mailer-agent', 1,		# NeXT mailer
		'nobody', 1				# Nobody we've heard of
	);
}

# Parse mail message and apply the filtering rules on it
sub analyze_mail {
	local($file) = shift(@_);	# Mail file to be parsed
	local($mode) = 'INITIAL';	# Initial working mode
	local($wmode) = $mode;		# Needed for statistics routines
	local(%Variable);			# User-defined variables, visible through APPLY

	# Set-up proper environment. Dynamic scoping is used on those variables
	# for the APPLY command (see the &apply function). Note that the $wmode
	# variable is passed to &apply_rules but is local to that function,
	# meaning there is no feedback of the working mode when using APPLY.
	# However, the variables listed below may be probed upon return since they
	# are external to &apply_rules.
	local($ever_matched) = 0;	# Did we ever matched a single saving rule ?
	local($ever_saved) = 0;		# Did we ever saved a message ?
	local($folder_saved) = '';	# Last folder we saved into (full path)

	# Other local variables used only in this function
	local($ever_seen) = 0;		# Did we ever enter seen mode ?
	local($header);				# Header entry name to look for in Header table

	# Reset environment and umask before each new mail processing
	&env'setup;
	umask($env'umask);

	# Parse the mail message in file
	&parse_mail($file);			# Parse the mail and fill-in H tables
	return 1 unless defined $Header{'All'};		# Mail not parsed correctly
	&reception if $loglvl > 8;	# Log mail reception
	&run_builtins;				# Execute builtins, if any

	# Now analyze the mail. If there is already a X-Filter header, then the
	# mail has already been processed. In that case, the default action is
	# performed: leave it in the incomming mailbox with no further action.
	# This should prevent nasty loops.

	&add_log ("analyzing mail") if $loglvl > 18;
	$header = $Header{'X-Filter'};				# Mulitple occurences possible
	if ($header ne '') {						# Hmm... already filtered...
		local(@filter) = split(/\n/, $header);	# Look for each X-Filter
		local($address) = &email_addr;			# Our e-mail address
		local($done) = 0;						# Already processed ?
		local($*) = 0;
		local($_);
		foreach (@filter) {						# Maybe we'll find ourselves
			if (/mailagent.*for (\S+)/) {		# Mark left by us ?
				$done = 1 if $1 eq $address;	# Yes, we did that
				$* = 1;
				# Remove that X-Filter line, LEAVE will add one anyway
				$Header{'Head'} =~ s/^X-Filter:\s*mailagent.*for $address\n//;
				$* = 0;
				last;
			}
		}
		if ($done) {			# We already processed that message
			if ($force_seen) {	# They used the -F option
				&add_log("NOTICE already filtered, processing anyway")
					if $loglvl > 5;
			} else {
				&add_log("NOTICE already filtered, entering seen mode")
					if $loglvl > 5;
				$mode = '_SEEN_';	# This is a special mode
			}
			$ever_seen = 1;		# This will prevent vacation messages
			&s_seen;			# Update statistics
		}
	}

	local($lastcmd) = 0;		# Failure status from last command
	&apply_rules($mode, 1);		# Now apply the filtering rules on it.

	# Deal with vacation mode. It applies only on mail not previously seen.
	# The vacation mode must be turned on in the configuration file. The
	# conditions for a vacation message to be sent are:
	#   - Message was directly sent to the user.
	#   - Message does not come from a special user like root.
	#   - Vacation message was not disabled via a VACATION command
	# Note that we use the environment set-up by the last rule we processed.

	if (!$ever_seen && $cf'vacation =~ /on/i && $env'vacation) {
		unless (&special_user) {	# Not from special user and sent to me
			# Send vacation message only once per address per period
			&xeqte("ONCE (%r,vacation,$env'vacperiod) MESSAGE $env'vacfile");
			&s_vacation;		# Message received while in vacation
		}
	}

	# Default action if no rule ever matched. Statistics routines will use
	# our own local $wmode variable.

	unless ($ever_matched) {
		&add_log("NOTICE no match, leaving in mailbox") if $loglvl > 5;
		&xeqte("LEAVE");			# Default action anyway
		&s_default;					# One more application of default rule
	} else {
		unless ($ever_saved) {
			&add_log("NOTICE not saved, leaving in mailbox") if $loglvl > 5;
			&xeqte("LEAVE");		# Leave if message not saved
			&s_saved;				# Message saved by default rule
		}
	}
	&s_filtered($Header{'Length'});		# Update statistics

	&env'cleanup;						# Clean-up the environment
	0;									# Ok status
}

# This is the heart of the mail agent -- Apply the filtering rules
sub apply_rules {
	local($wmode, $stats)= @_;	# Working mode (the mode we start in)
	local($mode);				# Mode (optional)
	local($selector);			# Selector (mandatory)
	local($range);				# Range for selection (optional)
	local($rulentry);			# Entry in rule H table
	local($pattern);			# Pattern for selection, as written in rules
	local($action);				# Related action
	local($last_selector);		# Last used selector
	local($rules);				# A copy of the rules
	local($matched);			# Flag set to true if a rule is matched
	local(%Matched);			# Records the selectors which have been matched
	local($status);				# Status returned by xeqte
	local(@Executed);			# Records already executed rules
	local($selist);				# Key used to detect identical selector lists
	local(%Inverted);			# Records inverted '!' selectors which matched

	# The @Executed array records whether a specified action for a rule was
	# executed. Loops are possible via the RESTART action, and as there is
	# almost no way to exit from such a loop (there is one with FEED and RESYNC)
	# I decided to prohibit them. Hence a given action is allowed to be executed
	# only once during a mail analysis (modulo each possible working mode).
	# For a rule number n, $Executed[n] is a collection of modes in which the
	# rule was executed, comma separated.

	$Executed[$#Rules] = '';		# Pre-extend array

	# Order wrt the one in the rule file is guaranteed. I use a for construct
	# with indexed access to be able to restart from the beginning upon
	# execution of RESTART. This also helps filling in the @Executed array.

	local($i, $j);			# Indices within rule array

	rule: for ($i = 0; $i <= $#Rules; $i++) {
		$j = $i + 1;
		$_ = $Rules[$i];

		# The %Matched array records the boolean value associated with each
		# possible selector. If two identical selector are found, the values
		# are OR'ed (and we stop evaluating as soon as one is true). Otherwise,
		# the values are AND'ed (for different selectors, but all are evaluated
		# in case we later find another identical selectors -- no sort is done).
		# The %Inverted which records '!' selector matches has all the above
		# rules inverted according to De Morgan's Law.

		undef %Matched;							# Reset matching patterns
		undef %Inverted;						# Reset negated patterns
		$rules = $_;							# Work on a copy
		$rules =~ s/^([^{]*)\{// && ($mode = $1);	# First word is the mode
		$rules =~ s/\s*(.*)\}// && ($action = $1);	# Followed by action }
		$mode =~ s/\s*$//;							# Remove trailing spaces
		$rules =~ s/^\s+//;						# Remove leading spaces
		$last_selector = "";					# Last selector used

		# Make sure we are in the correct mode. The $mode variable holds a
		# list of comma-separated modes. If the working mode is found in it
		# then the rules apply. Otherwise, skip them.

		next rule unless &right_mode;		# Skip rule if not in right mode

		# Now loop over all the keys and apply the patterns in turn

		&reset_backref;						# Reset backreferences
		foreach $key (split(/ /, $rules)) {
			$rulentry = $Rule{$key};
			$rulentry =~ s/^\s*([^\/]*:)// && ($selector = $1);
			$rulentry =~ s/^\s*//;
			$pattern = $rulentry;
			if ($last_selector ne $selector) {	# Update last selector
				$last_selector = $selector;
			}
			$selector =~ s/:$//;			# Remove final ':' on selector
			$range = '<1,->';				# Default range
			$selector =~ s/\s*(<[\d\s,-]+>)$// && ($range = $1);

			&add_log ("selector '$selector' on '$range', pattern '$pattern'")
				if $loglvl > 19;

			# Identical (lists of) selectors are logically OR'ed. To make sure
			# 'To Cc:' and 'Cc To:' are correctly OR'ed, the selector list is
			# alphabetically sorted.

			$selist = join(',', sort split(' ', $selector));

			# Direct selectors and negated selectors (starting with a !) are
			# kept separately, because the rules are dual:
			# For normal selectors (kept in %Matched):
			#  - Identical are OR'ed
			#  - Different are AND'ed
			# For inverted selectors (kept in %Inverted):
			#  - Identical are AND'ed
			#  - Different are OR'ed
			# Multiple selectors like 'To Cc' are sorted according to the first
			# selector on the list, i.e. 'To !Cc' is normal but '!To Cc' is
			# inverted.

			if ($selector =~ /^!/) {		# Inverted selector
				# In order to guarantee an optimized AND, we first check that
				# no previous failure has been reported for the current set of
				# selectors.
				unless (defined $Inverted{$selist} && !$Inverted{$selist}) {
					$Inverted{$selist} = &match($selector, $pattern, $range);
				}
			} else {						# Normal selector
				# Here it is the OR which is guaranteed to be optimized. Do
				# not attempt the match if an identical selector already
				# matched sucessfully.
				unless (defined $Matched{$selist} && $Matched{$selist}) {
					$Matched{$selist} = &match($selector, $pattern, $range);
				}
			}
		}

		# Both groups recorded in %Matched and %Inverted are globally AND'ed
		# However, only one match is necessary within %Inverted whilst all
		# must have matched within %Matched...

		$matched = 1;						# Assume everything matched
		foreach $key (keys %Matched) {		# All entries must have matched
			$matched = $Matched{$key} ? 1 : 0;
			&add_log("rule #$j: direct $key " . ($matched ? 'ok' : 'failed'))
				if $loglvl > 19;
			last unless $matched;
		}
		if ($matched) {						# If %Matched failed, all failed!
			foreach $key (keys %Inverted) {	# Only one entry needs to match
				$matched = $Inverted{$key} ? 1 : 0;
				&add_log("rule #$j: neg $key " . ($matched ? 'ok' : 'failed'))
					if $loglvl > 19;
				last if $matched;
			}
		}

		&add_log("matching summary rule #$j: " . ($matched ? 'ok' : 'failed'))
			if $loglvl > 17;

		if ($matched) {						# Execute action if pattern matched
			# Make sure the rule has not already been executed in that mode
			if ($Executed[$i] =~ /,$wmode,/) {
				&add_log("NOTICE loop detected, rule $j, state $wmode")
					if $loglvl > 5;
				last rule;					# Processing ends here
			} else {						# Rule was never executed
				$Executed[$i] = ',' unless $Executed[$i];
				$Executed[$i] .= "$wmode,";
			}
			$ever_matched = 1;				# At least one match
			&add_log("MATCH on rule #$j in mode $wmode") if $loglvl > 8;
			&track_rule($j, $wmode) if $track_all;
			&s_match($j, $wmode) if $stats;	# Record match for statistics

			# By issuing an &env'restore, we make sure any local variable
			# setting done in other rules is not seen by the actions we are
			# about to execute. However, should the action be the last one
			# to be performed, its settings will remain for later perusal
			# by our caller (vacation messages come to mind).

			&env'restore;				# Restore vars set in previous rules
			$status = &xeqte($action);	# Execute actions

			last rule if $status == $FT_CONT;
			$ever_matched = 0;				# No match if REJECT or RESTART
			next rule if $status == $FT_REJECT;
			$i = -1;		# Restart analysis from the beginning ($FT_RESTART)
		}
	}
	($ever_saved, $ever_matched);
}

# Return true if the modes currently specified by the rule (held in $mode)
# are selected by the current mode (in $wmode), meaning the rule has to
# be applied.
sub right_mode {
	local($list) = "," . $mode . ",";
	&add_log("in mode '$wmode' for $mode") if $loglvl > 19;

	# If mode is negated, skip the rule, whatever other selectors may
	# indicate. Thus <ALL, !INITIAL> will not be taken into account if
	# mode is INITIAL, despite the leading ALL. They can be seen as further
	# requirements or restrictions applied to the mode list (like in the
	# sentence "all the listed modes *but* the one negated").

	return 0 if $list =~ /!ALL/;		# !ALL cannot match, ever
	return 0 if $list =~ /,!$wmode,/;	# Negated modes logically and'ed

	# Now strip out all negated modes, and if the resulting string is
	# empty, force a match...

	1 while $list =~ s/,![^,]*,/,/;		# Strip out negated modes
	$list = ',ALL,' if $list eq ',';	# Emtpy list, force a match

	# The special ALL mode matches anything but the other sepcial mode for
	# already filtered messages. Otherwise, direct mode (i.e. non-negated)
	# are logically or'ed.

	if ($list =~ /,ALL,/) {
		return 0 if $wmode eq '_SEEN_' && $list !~ /,_SEEN_,/;
	} else {
		return 0 unless $list =~ /,$wmode,/;
	}

	1;	# Ok, rule can be applied
}

# Return true if the mail was from a special user (root, uucp...) or if the
# mail was not directly mailed to the user (i.e. it comes from a distribution
# list or has bounced somewhere).
sub special_user {
	# Before sending the vacation message, we have to make sure the mail
	# was sent to the user directly, through a 'To:' or a 'Cc:'. Otherwise,
	# it must be from a mailing list or a 'Bcc:' and we don't want to
	# send something back in that case.

	local($matched) = &match_list("To", $cf'user);
	$matched = &match_list("Cc", $cf'user) unless $matched;

	# Try alternate login names, in case they used a company-wide alias like
	# First.Last or simply a plain sendmail alias.

	if (!$matched && $cf'tome ne '') {
		foreach $addr (split(/\s*,\s*/, $cf'tome)) {
			$matched = &match_list('To', $addr);
			$matched = &match_list('Cc', $addr) unless $matched;
			if ($matched) {
				&add_log("mail was sent to alternate $addr") if $loglvl > 8;
				last;
			} else {
				&add_log("mail wasn't sent to alternate $addr") if $loglvl > 12;
			}
		}
	}

	unless ($matched) {
		&add_log("mail was not directly sent to $cf'user") if $loglvl > 8;
		return 1;
	}

	# If there is a Precedence: header set to either 'bulk', 'list' or 'junk',
	# then we do not reply either.
	local($prec) = $Header{'Precedence'};
	if ($prec =~ /^bulk|junk|list/i) {
		&add_log("mail was tagged with a '$prec' precedence") if $loglvl > 8;
		return 1;
	}
	# If there is an RFC-886 Illegal-Object or Illegal-Field header, do not
	# trust the whole header integrity, and therefore do not reply.
	if ($Header{'Illegal-Object'} ne '' || $Header{'Illegal-Field'} ne '') {
		&add_log("mail was received with header errors") if $loglvl > 8;
		return 1;
	}
	# Make sure the mail does not come from a "special" user, as listed in
	# the %Special array (root, uucp...)
	$matched = 0;
	local($matched_login);
	foreach $login (keys %Special) {
		$matched = &match_single("From", $login);
		$matched_login = $login if $matched;
		last if $matched;
	}
	if ($matched) {
		&add_log("mail was from special user $matched_login")
			if $loglvl > 8;
		return 1;
	}
	0;	# Not from special user!
}

# Compare a machine and an e-mail address and return true if the domain
# for that address matches the domain of the machine. We allow an extra
# level of "domain indirection".
sub fuzzy_domain {
	local($first, $fhost) = @_;
	$fhost =~ s/^\S+@([\w-.]+)/$1/;					# Keep hostname part
	$fhost =~ tr/A-Z/a-z/;							# perl4 misses lc()
	$first =~ tr/A-Z/a-z/;
	local(@fhost) = split(/\./, $fhost);
	local(@first) = split(/\./, $first);
	if (@fhost > @first) {
		shift(@fhost);					# Allow extra machine name
	} elsif (@first > @fhost) {
		shift(@first);
	} elsif (@fhost >= 3) {				# Has at least machine.domain.top
		shift(@first);					# Allow server1.domain.top to match
		shift(@fhost);					# server2.domain.top
	}
	$fhost = join('.', @fhost);
	$first = join('.', @first);
	return $fhost eq $first;
}

# Log reception of mail (sender and subject fields). This is mainly intended
# for people like me who parse the logfile once in a while to do more 
# statistics about mail reception. Hence the other distinction between
# original mails and answers.
sub reception {
	local($subject) = $Header{'Subject'};
	local($sender) = $Header{'Sender'};
	local($from) = $Header{'From'};
	&add_log("FROM $from");
	local($faddr) = (&parse_address($from))[0];		# From address
	local($saddr) = '';

	if ($sender ne '') {
		$saddr = (&parse_address($sender))[0];
		&add_log("VIA $sender") if $saddr ne $faddr;
	}

	# Trace relaying hosts as well if the first host is unrelated to sender
	local($relayed) = $Header{'Relayed'};
	local($first) = (split(/,\s+/, $relayed))[0];	# First relaying host
	&add_log("RELAYED $relayed") if $relayed ne '' &&
		!(&fuzzy_domain($first, $saddr) || &fuzzy_domain($first, $faddr));

	if ($subject ne '') {
		if ($subject =~ s/^Re:\s*//) {
			&add_log("REPLY $subject");
		} else {
			&add_log("ABOUT $subject");
		}
	}
	print "-------- From $from\n" if $track_all;
}

# Print match on STDOUT when -t option is used
sub track_rule {
	local($number, $mode) = @_;
	print "*** Match on rule $number in mode $mode ***\n";
	&print_rule($number);
}

