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
;# $Log: rules.pl,v $
;# Revision 3.0.1.9  1998/03/31  15:27:04  ram
;# patch59: allow ~name expansion when specifying alternate rule files
;#
;# Revision 3.0.1.8  1997/01/31  18:08:02  ram
;# patch54: esacape metacharacter '{' in regexps for perl5.003_20
;#
;# Revision 3.0.1.7  1996/12/24  15:00:11  ram
;# patch45: forgot to unlock rulecache on errors
;# patch45: don't dataload hashkey(), used as a sort routine
;#
;# Revision 3.0.1.6  1995/08/07  16:24:53  ram
;# patch37: skip possible spaces before trailing command ';' terminator
;#
;# Revision 3.0.1.5  1995/02/16  14:36:26  ram
;# patch32: was not properly propagating rule-file variable definitions
;#
;# Revision 3.0.1.4  1995/02/03  18:03:57  ram
;# patch30: added tracing of alternate rules to help debug their parsing
;#
;# Revision 3.0.1.3  1995/01/03  18:15:44  ram
;# patch24: don't try to read the rule cache when none was configured
;#
;# Revision 3.0.1.2  1994/09/22  14:36:40  ram
;# patch12: lock rule cache before reading to prevent from concurrent updates
;#
;# Revision 3.0.1.1  1994/04/25  15:23:03  ram
;# patch7: added locking protections when updating rule cache
;#
;# Revision 3.0  1993/11/29  13:49:14  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Here are the data structures we use to store the compiled form of the rules:
#  @Rules has entries looking like "<$mode> {$action} $rulekeys..."
#  %Rule has entries looking like "$selector: $pattern"
# Each rule was saved in @Rules. The ruleskeys have the form H<num> where <num>
# is an increasing integer. They index the rules in %Rule.

# Compile the rules held in file $cf'rules (usually ~/.rules) or in memory
sub compile_rules {
	local($mode);			# mode (optional)
	local($first_selector);	# selector (mandatory first time)
	local($selector);		# selector (optional)
	local($pattern);		# pattern to be matched
	local($action);			# associated action
	local($rulekeys);		# keys to rules in hash table
	local($rulenum) = 0;	# to compute unique keys for the hash table
	local($line);			# buffer for next rule
	local($env);			# environment variable recognized

	# This function is called whenever a new line rule has to be read. By
	# default, rules are read from a file, but if @Linerules is set, they
	# are read from there.
	local(*read_rule) = *read_filerule if @Linerules == 0;
	local(*read_rule) = *read_linerule if @Linerules > 0;

	unless ($edited_rules) {		# If no rules from command line
		unless (-s "$cf'rules") {	# No rule file or empty
			&default_rules;			# Build default rules
			return;
		}
		unless (open(RULES, "$cf'rules")) {
			&add_log("ERROR cannot open $cf'rules: $!") if $loglvl;
			&default_rules;			# Default rules will apply then
			return;
		}
		if (&rules'read_cache) {	# Rules already compiled and cached
			close RULES;			# No parsing needs to be done
			return;
		}
	} else {						# Rules in @Linerules array
		&rule_cleanup if @Linerules == 1;
	}

	while ($line = &get_line) {
		# Detect environment settings as soon as possible
		if ($line =~ s/^\s*(\w+)\s*=\s*//) {
			# All the variables referenced in the line have to be environment
			# variables. So replace them with the values we already computed as
			# perl variables. This enables us to do variable substitution in
			# perl with minimum trouble.
			$env = $1;								# Variable being changed
			$line =~ s/\$(\w+)/\$XENV{'$1'}/g;		# $VAR -> $XENV{'VAR'}
			$line =~ s/\s*;$//;						# Remove trailing ;
			eval "\$XENV{'$env'} = \"$line\"";		# Perl does the evaluations
			&eval_error;							# Report any eval error
			next;
		}
		$rulekeys = '';						# Reset keys for each line
		$mode = &get_mode(*line);			# Get operational mode
		&add_log("mode: <$mode>") if $loglvl > 19;
		$first_selector = &get_selector(*line);		# Fetch a selector
		$first_selector = "Subject:" unless $first_selector;
		$selector = $first_selector;
		for (;;) {
			if ($line =~ /^\s*;/) {			# Selector alone on the line
				&add_log("ERROR no pattern nor action, line $.") if $loglvl > 1;
				last;						# Ignore the whole line
			}
			&add_log("selector: $selector") if $loglvl > 19;
			# Get a pattern. If none is found, it is assumed to be '*', which
			# will match anything.
			$pattern = &get_pattern(*line);
			$pattern = '*' if $pattern =~ /^\s*$/;
			&add_log("pattern: $pattern") if $loglvl > 19;
			# Record entry in H table and update the set of used keys
			$Rule{"H$rulenum"} = "$selector $pattern";
			$rulekeys .= "H$rulenum ";
			$rulenum++;
			# Now look for an action. No action at the end means LEAVE.
			$action = &get_action(*line);
			$action = "LEAVE" if $action =~ /^\s*$/ && $line =~/^\s*;/;
			if ($action !~ /^\s*$/) {
				&add_log("action: $action") if $loglvl > 19;
				push(@Rules, "$mode {$action} $rulekeys");
				$rulekeys = '';		# Reset rule keys once used
			}
			last if $line =~ /^\s*;/;	# Finished if end of line reached
			last if $line =~ /^\s*$/;	# Also finished if end of file
			# Get a new selector, defaults to last one seen if none is found
			$selector = &get_selector(*line);
			$selector = $first_selector if $selector eq '';
			$first_selector = $selector;
		}
	}
	close RULES;		# This may not have been opened

	&default_rules unless @Rules;	# Use defaults if no valid rules

	# If rules have been compiled from a file and not entered on the command
	# line via -e switch(es), then $edited_rules is false and it makes sense
	# to cache the lattest compiled rules. Note that the 'rulecache' parameter
	# is optional, and rules are actually cached only if it is defined.

	&rules'write_cache unless $edited_rules;
}

# Build default rules:
#  -  Anything with 'Subject: Command' in it is processed.
#  -  All the mails are left in the mailbox.
sub default_rules {
	&add_log("building default rules") if $loglvl > 18;
	@Rules = ("ALL {LEAVE; PROCESS} H0");
	$Rule{'H0'} = "All: /^Subject: [Cc]ommand/";
}

# Rule cleanup: If there is only one rule specified within the @Linerules
# array, it might not have {} braces.
sub rule_cleanup {
	return if $Linerules[0] =~ /[{}]/;		# Braces found
	$Linerules[0] = '{' . $Linerules[0] . '}';
}

# Hook functions for dumping rules
sub print_rule_number {
	local($rulenum) = @_;
	print "# Rule $rulenum\n";			# For easier reference
	1;									# Continue
}

# Void function
sub void_func {
	print "\n";
}

# Print only rule whose number is held in variable $number
sub exact_rule {
	$_[0] eq $number;
}

sub nothing { }			 # Do nothing, really nothing

# Dump the rules we've compiled -- for debug purposes
sub dump_rules {
	# The 'before' hook is called before each rule is called. It returns a
	# boolean stating wether we should continue or skip the rule. The 'after'
	# hook is called after the rule has been printed. Both hooks are given the
	# rule number as argument.
	local(*before, *after) = @_;	# Hook functions to be called
	local($mode);			# mode (optional)
	local($selector);		# selector (mandatory)
	local($rulentry);		# entry in rule H table
	local($pattern);		# pattern for selection
	local($action);			# related action
	local($last_selector);	# last used selector
	local($rules);			# a copy of the rules
	local($rulenum) = 0;	# each rule is numbered
	local($lines);			# number of pattern lines printed
	local(@action);			# split actions (split on ;)
	local($printed) = 0;	# characters printed on line so far
	local($indent);			# next item indentation
	local($linelen) = 78;	# maximum line length
	# Print the environement variable which differ from the original
	# environment, i.e. those variable which were set by the user.
	$lines = 0;
	foreach (sort keys(%XENV)) {
		unless ("$XENV{$_}" eq "$ENV{$_}") {
			print "$_ = ", $XENV{$_}, ";\n";
			$lines++;
		}
	}
	print "\n" if $lines;
	# Order wrt the one in the rule file is guaranteed
	foreach (@Rules) {
		$rulenum++;
		next unless &before($rulenum);				# Call 'before' hook
		$rules = $_;		# Work on a copy
		$rules =~ s/^([^{]*)\{// && ($mode = $1);	# First "word" is the mode
		$rules =~ s/\s*(.*)\}// && ($action = $1);	# Then action within {}
		$mode =~ s/\s*$//;							# Remove trailing spaces
		print "<$mode> ";							# Mode in which it applies
		$printed = length($mode) + 3;
		$rules =~ s/^\s+//;							# The rule keys remain
		$last_selector = "";						# Last selector in use
		$lines = 0;
		foreach $key (split(/ /, $rules)) {			# Loop over the keys
			$rulentry = $Rule{$key};
			$rulentry =~ s/^\s*([^\/]*:)// && ($selector = $1);
			$rulentry =~ s/^\s*//;
			$pattern = $rulentry;
			if ($last_selector eq $selector) {		# Try to stay on same line
				# Go to next line if current pattern won't fit nicely
				if ($printed + length($pattern) > $linelen) {
					$indent = length($mode) + length($selector) + 4;
					print ",\n", ' ' x $indent;
					$lines++;
					$printed = $indent;
				} else {
					print ", ";
					$printed += 2;
				}
			} else {								# Selector has changed
				if ($lines++) {
					$indent = length($mode) + 3;
					print ",\n", ' ' x $indent;
					$printed = $indent;
				}
			}
			if ($last_selector ne $selector) {		# Update last selector
				$last_selector = $selector;
				if ($selector ne 'script:') {		# Pseudo not printed
					print "$selector ";
					$printed += length($selector) + 1;
				}
			}
			if ($selector ne 'script:') {
				print "$pattern";					# Normal pattern
				$printed += length($pattern);
			} else {
				print "[[ $pattern ]] ";			# An interpreted script
				$printed += length($pattern) + 7;
			}
		}
		print "  " if $lines == 1 && ($printed += 2);

		# Split actions, but take care of escaped \; (layout purposes)
		$action =~ s/\\\\/\02/g;			# \\ -> ^B
		$action =~ s/\\;/\01/g;				# \; -> ^A
		@action = split(/;/, $action);
		foreach (@action) {					# Restore escapes by in-place edit
			s/\01/\\;/g;					# ^A -> \;
			s/\02/\\\\/g;					# ^B -> \\
		}

		# If action is large enough, format differently (one action/line)
		$lines++ if length($action) + 5 + $printed > $linelen;
		$indent = $lines > 1 ? length($mode) + 3 + 4 : 0;
		$printed = $indent == 0 ? $printed : $indent;
		if ((length($action) + $printed) > $linelen && @action > 1) {
			print "\n\t{\n";
			foreach $act (@action) {
				$act =~ s/^\s+//;
				print "\t\t$act;\n";
			}
			print "\t};\n";
		} else {
			print "\n", ' ' x $indent if $lines > 1;
			print "{ $action };\n";
		}
		$printed = 0;

		# Call the hook function after having printed the rule
		&after($rulenum);
	}
}

# Print only a specific rule on stdout
sub print_rule {
	local($number) = @_;
	local(%XENV);			# Suppress printing of leading variables
	&dump_rules(*exact_rule, *nothing);
}

#
# The following package added to hold all the new rule-specific functions
# added at version 3.0.
#

package rules;

# Cache rules to the 'rulecache' file. The first line is the full pathname
# of the rule file, followed by the modification time stamp. The rulecache
# file will be recreated each time a different rule file is provided or when
# it is out of date. Note that this function is only called when actually
# compiling from the 'rules' file defined in the config file.
# The function returns 1 if success, 0 on failure.
sub write_cache {
	return 0 unless defined $cf'rulecache;
	local(*CACHE);					# File handle used to write the cache
	if (0 != &'acs_rqst($cf'rulecache)) {
		&'add_log("NOTICE unable to write-lock $cf'rulecache") if $'loglvl > 6;
		return 0;					# Cannot write
	}
	unless (open(CACHE, ">$cf'rulecache")) {
		&'add_log("ERROR cannot create rule cache $cf'rulecache: $!")
			if $'loglvl;
		&'free_file($cf'rulecache);	# Unlock cache
		unlink $cf'rulecache;
		return 0;
	}
	local($error) = 0;
	local($ST_MTIME) = 9 + $[;
	local($mtime) = (stat($cf'rules))[$ST_MTIME];
	(print CACHE "$cf'rules $mtime\n") || $error++;
	&write_fd(CACHE) || $error++;		# Write rules
	&writevar_fd(CACHE) || $error++;	# And XENV variables
	close(CACHE) || $error++;
	&'free_file($cf'rulecache);		# Unlock cache
	if ($error) {
		unlink $cf'rulecache;
		&'add_log("WARNING could not cache rules") if $'loglvl > 5;
		return 0;
	}
	1;	# Success
}

# Read cached rules into @Rules and %Rules and returns 1 if done, 0 when
# the cache may not be read for whatever reason (e.g. out of date).
# Since the '-r' option may also need to cache rules and no mailagent lock
# is taken in that case, we need to lock the rule file before accessing it.
sub read_cache {
	return 0 unless defined $cf'rulecache;
	if (0 != &'acs_rqst($cf'rulecache)) {
		&'add_log("NOTICE unable to read-lock $cf'rulecache") if $'loglvl > 6;
		return 0;					# Cannot read
	}
	unless (&cache_ok) {
		&'free_file($cf'rulecache);
		return 0;					# Cache outdated
	}
	local(*CACHE);					# File handle used to read the cache
	local($_);
	open(CACHE, $cf'rulecache) || return 0;	# Cannot open, assume out of date
	$_ = <CACHE>;					# Disregard top line
	while (<CACHE>) {				# First read the @Rules
		chop;
		last if /^$/;				# Reached end of @Rules table
		push(@'Rules, $_);
	}
	local($rulenum) = 0;
	while (<CACHE>) {				# Next read sorted values, assigned to H...
		chop;
		last if /^\+\+\+\+\+\+/;	# End of dumped rules
		$'Rule{"H$rulenum"} = $_;
		$rulenum++;
	}
	while (<CACHE>) {				# Read XENV variables
		chop;
		s/^\s*(\w+)\s*=\s*// && ($'XENV{$1} = $_);
	}
	close CACHE;
	&'free_file($cf'rulecache);		# Unlock cache
	1;	# Success
}

# Is cache up-to-date with respect to the rule file? Returns true if cache ok.
# The rule file should be read-locked by the caller.
sub cache_ok {
	return 0 unless defined $cf'rulecache;
	local(*CACHE);					# File handle used to read the cache
	local($top);					# Top line recording file name and timestamp
	open(CACHE, $cf'rulecache) || return 0;	# Cannot open, assume out of date
	$top = <CACHE>;					# Get that first line
	close CACHE;
	local($name, $stamp) = split(' ', $top);
	return 0 if $name ne $cf'rules;	# File changed, cache out of date
	local($ST_MTIME) = 9 + $[;
	local($mtime) = (stat($cf'rules))[$ST_MTIME];
	$mtime != $stamp ? 0 : 1;		# Cache up-to-date only if $stamp == $mtime
}

# Dump the internal form of the rules, returning 1 for success.
sub write_fd {
	local($file) = @_;				# Filehandle in which rules are to be dumped
	local($_);
	local($error) = 0;
	foreach (@'Rules) {
		(print $file $_, "\n") || $error++;
	}
	(print $file "\n") || $error++;	# A blank line separates tables
	foreach (sort hashkey keys %'Rule) {
		(print $file $'Rule{$_}, "\n") || $error++;
	}
	(print $file "++++++\n") || $error++;	# Marks end of dumped rules
	$error ? 0 : 1;		# Success when no error reported
}

# Dump the internal form of environment variables, returning 1 for success.
sub writevar_fd {
	local($file) = @_;				# Filehandle in which variables are printed
	local($error) = 0;
	local($_);
	foreach (keys(%'XENV)) {
		unless ("$'XENV{$_}" eq "$'ENV{$_}") {
			(print $file "$_ = ", $'XENV{$_}, "\n") || $error++;
		}
	}
	$error ? 0 : 1;		# Success when no error reported
}

# Perload OFF
# (Used as a sort function, causes perl5 to dump core with native AUTOLOAD)

# Sorting for hash keys used by %Rule
sub hashkey {
	local($c) = $a =~ /^H(\d+)/;
	local($d) = $b =~ /^H(\d+)/;
	$c <=> $d;
}

# Perload ON

# The following sets-up a new rule environment and then transfers the control
# to some other function, giving it the remaining parameters. That enables the
# other function to work transparently with a different set of rules. Merely
# done for the APPLY function. Returns undef for errors, or propagates the
# result of the function.
sub alternate {
	local($rules, $fn, @rest) = @_;
	local($'edited_rules) = 1;	# Signals that rules do not come from main file
	local(@'Linerules);			# We're stuffing our new rules there

	$rules =~ s/^~/$cf'home/;	# ~ substitution
	unless (open(RULES, $rules)) {
		&'add_log("ERROR cannot open alternate rule file $rules: $!")
			if $'loglvl;
		return undef;
	}
	local($_);
	while (<RULES>) {
		chop;					# Not really needed, but it'll save space :-)
		push(@'Linerules, $_);
		&'add_log("PUSH <<$_>>") if $'loglvl > 24;
	}
	close RULES;

	# Need at list two line rules or we'll try to apply some default fixes
	# used by the -e 'rules' switch...
	push(@'Linerules, '', '') if @'Linerules <= 1;

	# Make sure transfer function is package-qualified
	$fn = "main'$fn" unless $fn =~ /'/;

	# Create local instances of @Rules and %Rule that will get filled-up
	# by &compile_rules. Also make a copy of %XENV so that the local
	# rules may override some default settings.

	local(@'Rules);				# Set up a new dynamic environment...
	local(%'Rule);
	local(@xenv) = %'XENV;
	local(%'XENV) = @xenv;		# Local copy of previous environment

	&'compile_rules;	# Compile new rules held in the @'Linerules array
	&$fn(@rest);		# Transfer control in new environment
}

package main;

