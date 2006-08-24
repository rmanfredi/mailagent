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
;# $Log: stats.pl,v $
;# Revision 3.0.1.4  1997/02/20  11:46:51  ram
;# patch55: typo fixes and print() call cleanup to avoid run-time warnings
;#
;# Revision 3.0.1.3  1997/01/31  18:08:09  ram
;# patch54: esacape metacharacter '{' in regexps for perl5.003_20
;#
;# Revision 3.0.1.2  1995/02/03  18:04:36  ram
;# patch30: avoid blank printing when the default rule was never applied
;#
;# Revision 3.0.1.1  1995/01/25  15:29:53  ram
;# patch27: now supports 't' to track only top-most rule file stats
;#
;# Revision 3.0  1993/11/29  13:49:17  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Handle the mailagent statistics file. This file is known as the statfile
;# in the configuration file (typically mailagent.st in the spool directory).
;# This file contains a summary of the action taken by the mailagent. The very
;# first line contains: mailstat: <timestamp> which is the date the statistics
;# started.
;#
;# The following format is used for each records:
;#
;#    <timestamp> 0 0
;#    <# of mails processed> <# commands run> <# of failures> <# of bytes>
;#    <rule number> <mode> <number of matches>
;#    "default" <number of matches>
;#    "vacation" <number of vaction messages sent>
;#    "seen" <number of messages already seen>
;#    "saved" <number of messages saved by default>
;#    <command name> <mode> <number of execution>
;#    !<command name> <mode> <number of failures>
;#    @<command name> <mode> <tag> <number of execution>
;#    %@<command name> <mode> <tag> <number of non-executed commands>
;#    --------
;#    <output of rule dumping>
;#    ++++++++
;#
;# The leading timestamp records the stamp on the rule file, followed by two
;# zeros (currently unused locations, reserved for future use, as they say).
;#
;# The number of mails processed is only stored to check the consistency of the
;# statistics file. Likewise, the number of commands run and the number of
;# failed commands are used to check the logging accuracy.
;#
;# Lines starting with a number indicate a match for a particular rule, in
;# a given mode. The "default", "vacation" and "seen" lines record the activity
;# of the default action, the vacation mode or the messages already processed
;# which come back.
;#
;# Commands are also logged. They are always spelled upper-cased. If the line
;# starts with a '!', it indicates a failure. If the character '@' is found
;# before the command name, it indicates a ONCE command. The tag part of the
;# identification is logged, but not the name (which is likely to be an e-mail
;# address anyway, whereas the tag identifies the command itself). The lines
;# starting with '%' also give the number of ONCE commands which were not
;# executed because the retry time was not reached.
;#
;# Below the dashed line, all the rules are dumped in order, and are separated
;# by a blank line. These are the rules listed in the rule file and they are
;# given for information purposes only, when reporting statistics. It ends with
;# a plus line.
;#
;# Whenever the rule file is updated, another record is started after having
;# been diffing the rules we have parsed with the rules dumped in the statistics
;# file.
;#
;# In order to improve performances, the statistics file is cached in memory.
;# Only the last record is read, up to the dashed-line. The data structures
;# used are:
;#
;#     @stats'Top: the top seven fields of the record:
;#         (time, 0, 0, processed, run, failed, bytes)
;#     %stats'Rule: indexed by <N>+mode, the number of matches
;#     %stats'Special: indexed by "default", "vacation", "saved" or "seen"
;#     %stats'Command: indexed by name+mode, the total number of runs
;#         this accounts for ONCE commands as well.
;#     %stats'FCommand: indexed by name+mode, the number of failures
;#         this accounts for ONCE commands as well.
;#     %stats'Once: indexed by name+mode+tag, the number of succesful runs
;#     %stats'ROnce: indexed by name+mode+tag, number of non-executed comands
;#
package stats;

$stats_wanted = 0;				# No statistics wanted by default
$new_record = 0;				# True when a new record is to be started
$start_date = 0;				# When statistics started
$suppressed = 0;				# Statistics suppressed by higher authority

# Suppress statistics. This function is called when options like -r or -e are
# used. Those usually specify one time rules and thus are not entitled to be
# recorded into the statistics.
sub main'no_stats { $suppressed = 1; }

# Read the statistics file and fill in the hash tables
sub main'read_stats {
	local($statfile) = $cf'statfile;	# Extract value from config package
	local($loglvl) = $main'loglvl;
	local($_, $.);
	$stats_wanted = 1 if ($statfile ne '' && -f $statfile);
	$stats_wanted = 0 if $suppressed;
	return unless $stats_wanted;
	# Do not come here unless statistics are really wanted
	unless (open(STATS, "$statfile")) {
		&'add_log("ERROR could not open statistics file $statfile: $!")
			if $loglvl > 0;
		$stats_wanted = 0;		# Cannot keep track of statistics
		return;
	}
	local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime, $mtime,
		$ctime,$blksize,$blocks) = stat($cf'rules);
	# A null size means we have to start over again
	unless (-s $statfile) {
		&'add_log("starting new statistics") if $loglvl > 6;
		$start_date = time;
		close STATS;
		@Top = ($mtime, 0, 0, 0, 0, 0, 0);
		return;
	}
	$_ = <STATS>;
	unless (/^mailstat: (\d+)/) {
		&'add_log("ERROR corrupted statistics file $statfile") if $loglvl;
		close STATS;
		$stats_wanted = 0;
		return;
	} else {
		$start_date = $1;
	}
	# The first record is always the active one. Check the timestamp. If the
	# rule file has changed, check the sums.
	$_ = <STATS>;
	local($timestamp, $unused_1, $unused_2) = split(' ', $_);
	if ($main'edited_rules || $mtime > $timestamp) {	# File was modified?
		# Reset timestamp for next time if rule come from a file.
		$timestamp = $mtime;
		$timestamp = 0 if $main'edited_rules;
		&'add_log("rule file may have changed") if $loglvl > 18;
		$new_record = &diff_rules($statfile);		# Run the full diff then
		if ($new_record) {
			&'add_log("rule file has changed") if $loglvl > 6;
			@Top = ($mtime, 0, 0, 0, 0, 0, 0);
			close STATS;
			$start_date = time;
			return;
		}
		&'add_log("rule file has not changed") if $loglvl > 6;
	}
	# Read second line and build the @Top array
	$_ = <STATS>;
	local($processed, $run, $failed, $bytes) = split(' ', $_);
	@Top =
		($timestamp, $unused_1, $unused_2, $processed, $run, $failed, $bytes);
	local($valid) = 0;			# Set to true when a valid record was found
	&fill_stats;				# Fill in data structures
	close STATS;
	&'add_log('statistics initialized and loaded') if $loglvl > 18;
}

# Write the statistics file
sub main'write_stats {
	local($statfile) = $cf'statfile;	# Extract value from config package
	local($loglvl) = $main'loglvl;
	return unless $stats_wanted;
	local($oldstat) = -f $statfile;
	if ($oldstat) {
		unlink("$statfile.b") if -f "$statfile.b";
		unless (rename($statfile, "$statfile.b")) {
			&'add_log("ERROR cannot rename $statfile as $statfile.b: $!")
				if $loglvl;
			return;
		}
	}
	unless (open(STATS, ">$statfile")) {
		&'add_log("ERROR cannot create $statfile: $!") if $loglvl;
		return;
	}
	# If a new record is to be created, do it at the top of the file, then
	# append the old statistics file at the end of it. Otherwise, the first
	# record of the old statistics file is removed and the remaining is
	# appended.
	print STATS "mailstat: $start_date\n";		# Magic line
	print STATS join(' ', @Top[0..2]). "\n";
	print STATS join(' ', @Top[3..$#Top]). "\n";
	&print_array(*Rule, "");			# Print rule matches statistics
	&print_array(*Special, "");			# Print special stats
	&print_array(*Command, "");			# Print actions executions
	&print_array(*FCommand, "!");		# Print failed actions
	&print_array(*Once, "@");			# Print once commands done
	&print_array(*ROnce, "%@");			# Print once commands not retried
	print STATS "------\n";
	&rules'write_fd("stats'STATS");		# Append internal form of rules
	# If there was no previous statistics file, it's done!
	unless ($oldstat) {
		close STATS;
		return;
	}
	unless (open(OLD, "$statfile.b")) {
		&'add_log("ERROR cannot open old statistics file") if $loglvl;
		close STATS;
		return;
	}
	# If no new record was created, we have to skip the first record of the old
	# statistics file before appending.
	unless ($new_record) {
		while (<OLD>) {
			last if /^\+\+\+\+\+\+/;
		}
	}
	# It's fine to only check the return status of print right now. If there is
	# not enough space on the device, we won't be able to append the whole
	# backup file, but then we have to discard previously saved statistics
	# anyway...
	# Note: 'print STATS <OLD>' would cause an excessive memory consumption
	# given that a statistics file can be several hundred Kbytes long.
	local($status) = 1;					# Printing status
	while (<OLD>) {
		$status &= (print STATS);		# Status remains to 1 while successful
	}
	close OLD;
	close STATS;
	if ($status) {						# Print ran ok
		unlink("$statfile.b");
	} else {							# Print failed
		&'add_log("ERROR could not update statistics: $!") if $loglvl;
		unless (rename("$statfile.b", $statfile)) {
			&'add_log("ERROR could not restore old statistics file: $!")
				if $loglvl;
		}
	}
}

# Print the hash table array in STATS file
sub print_array {
	local(*name, $leader) = @_;
	local(@keys);
	foreach (sort keys %name) {
		@keys = split(/:/);
		print STATS $leader . join(' ', @keys) . ' ' . $name{$_} . "\n";
	}
}

#
# Accounting routines
#

# Record a mail processing
sub main's_filtered {
	return unless $stats_wanted;
	local($length) = @_;
	$Top[3]++;
	$Top[6] += $length;
}

# Record a rule match
sub main's_match {
	return unless $stats_wanted;
	local($number, $mode) = @_;
	$Rule{"$number:$mode"}++;
}

# Record a default rule
sub main's_default {
	return unless $stats_wanted;
	$Special{'default'}++;
}

# Record a vacation message sent in vacation mode
sub main's_vacation {
	return unless $stats_wanted;
	$Special{'vacation'}++;
}

# Record a message saved by the default action
sub main's_saved {
	return unless $stats_wanted;
	$Special{'saved'}++;
}

# Record an already processed message
sub main's_seen {
	return unless $stats_wanted;
	$Special{'seen'}++;
}

# Record a successful execution
sub main's_action {
	return unless $stats_wanted;
	local($name, $mode) = @_;
	$Command{"$name:$mode"}++;
	$Top[4]++;
}

# Record a failed execution
sub main's_failed {
	return unless $stats_wanted;
	local($name, $mode) = @_;
	$Command{"$name:$mode"}++;
	$FCommand{"$name:$mode"}++;
	$Top[4]++;
	$Top[5]++;
}

# Record a successful once
sub main's_once {
	return unless $stats_wanted;
	local($name, $mode, $tag) = @_;
	$Once{"$name:$mode:$tag"}++;
}

# Record a non-retried once
sub main's_noretry {
	return unless $stats_wanted;
	local($name, $mode, $tag) = @_;
	$ROnce{"$name:$mode:$tag"}++;
}

#
# Low-level routines
#

# Establish a difference between the rules we have in memory and the rules
# that has been dumped at the end of the active record. Return the difference
# status, true or false.
sub diff_rules {
	local($file) = @_;					# Statistics file where dump is stored
	local(*loglvl) = *main'loglvl;
	local($_, $.);
	open(FILE, "$file") || return 1;	# Changed if we cannot re-open file
	# Go past the first dashed line, where the dumped rules begin
	while (<FILE>) {
		last if /^------/;
	}
	# The difference is done on the internal representation of the rules,
	# which gives us a uniform and easy way to make sure the rules did not
	# change.
	local(*Rules) = *main'Rules;		# The @Rules array
	local($i) = 0;						# Index in the rules
	while (<FILE>) {
		last if /^\+\+\+\+\+\+/;		# End of dumped rules
		last if $i > $#Rules;
		chop;
		last unless $_ eq $Rules[$i];	# Compare rule with internal form
		$i++;							# Index in the @Rules array
	}
	if ($i <= $#Rules) {				# If one rule did not match
		close FILE;
		++$i;
		&'add_log("rule $i did not match") if $loglvl > 11;
		return 1;						# Rule file has changed
	}
	# Now check the hash table entries
	local(*Rule) = *main'Rule;			# The %Rule array
	local(@keys) =
		sort rules'hashkey keys(%Rule);	# Sorted keys H0, H1, etc...
	$i = 0;								# Reset index
	while (<FILE>) {					# Swallow blank line
		last if /^\+\+\+\+\+\+/;		# End of dumped rules
		last if $i > $#keys;
		chop;
		last unless $_ eq $Rule{$keys[$i]};
		$i++;							# Index in @keys
	}
	if ($i <= $#keys) {					# Changed if one rule did not match
		close FILE;
		++$i;
		&'add_log("hrule $i did not match") if $loglvl > 11;
		return 1;						# Rule file has changed
	}
	close FILE;
	return 1 unless /^\+\+\+\+\+\+/;	# More rules to come
	0;									# Rule file did not change
}

# Read pre-opened STATS file descriptor and fill in the statistics arrays
sub fill_stats {
	while (<STATS>) {
		last if /^------/;		# Reached end of statistics
		if (/^(\d+)\s+(\w+)\s+(\d+)/) {				# <rule> <mode> <# match>
			$Rule{"$1:$2"} = int($3);
		} elsif (/^([a-z]+)\s+(\d+)/) {				# <special> <# match>
			$Special{$1} = $2;						# first token is the key
		} elsif (/^([A-Z]+)\s+(\w+)\s+(\d+)/) {		# <cmd> <mode> <# succes>
			$Command{"$1:$2"} = int($3);
		} elsif (/^!([A-Z]+)\s+(\w+)\s+(\d+)/) {	# <cmd> <mode> <# fail>
			$FCommand{"$1:$2"} = int($3);
		} elsif (/^@([A-Z]+)\s+(\w+)\s+(\S+)\s+(\d+)/) {	# Once run
			$Once{"$1:$2:$3"} = int($4);
		} elsif (/^%@([A-Z]+)\s+(\w+)\s+(\S+)\s+(\d+)/) {	# Once not retried
			$ROnce{"$1:$2:$3"} = int($4);
		} else {
			&'add_log("ERROR corrupted line $. in statistics file") if $loglvl;
			&'add_log("ERROR line $. was: $_") if $loglvl > 1;
		}
	}
}

#
# Reporting statistics
#

# Dump the statistics on the standard output.
# Here are the possible options:
#   u: print only used rules
#   m: merge all the statistics at the end
#   a: all mode reported
#   r: rule-based statistics, on a per-state basis
#   y: USELESS if -m, but kept for nice mnemonic
#	t: print only statistics for top-level rules (most recent rule file)
sub main'report_stats {
	require 'ctime.pl';
	local($option) = @_;				# Options from command line
	local($opt_u) = $option =~ /u/;		# Only used rules
	local($opt_m) = $option =~ /m/;		# Merge all statistics at the end
	local($opt_a) = $option =~ /a/;		# Print mode-related statistics
	local($opt_r) = $option =~ /r/;		# Print rule-based statistics
	local($opt_y) = $option =~ /y/;		# Yield rule-based summary
	local($opt_t) = $option =~ /t/;		# Only last rule file
	local($times) = $opt_t ? 1 : 100_000_000;
	$option =~ /t(\d+)/ && ($times = $1) if $opt_t;
	local($statfile) = $cf'statfile;
	local(*loglvl) = *main'loglvl;
	local($_, $.);
	select(STDOUT);
	unless ($statfile ne '' && -f "$statfile") {
		print "No statistics available.\n";
		return;
	}
	unless (open(STATS, "$statfile")) {
		print "Can't open $statfile: $!\n";
		return;
	}
	unless (-s $statfile) {
		print "Statistics file is empty.\n";
		close STATS;
		return;
	}
	local($lasttime) = time;	# End of last dumped period
	local($start) = $lasttime;	# Save current time
	local($amount);				# Number of mails processed
	local($bytes);				# Bytes processed
	local($actions);			# Number of actions
	local($failures);			# Failures reported
	local(%Cmds);				# Execution / action
	local(%FCmds);				# Failures / action
	local(%Spec);				# Summary of special actions
	local(%Mrule);				# For merged rules statistics
	local($in_summary);			# True when in summary
	1 while $times-- > 0 && &print_stats;	# Print stats for each record
	close STATS;
	if ($opt_m) {
		$in_summary = 1;				# Signal in summary part
		$Top[3] = $amount;				# Number of mails processed
		$Top[4] = $actions;				# Number of mails processed
		$Top[5] = $failures;			# Failures reported
		$Top[6] = $bytes;				# Bytes processed
		$current_time = $lasttime;
		$lasttime = $start;
		local(*Special) = *Spec;		# Alias %Spec into %Special
		&print_general("Summary");
		local(*Command) = *Cmds;		# Alias %Cmds into %Command
		local(*FCommand) = *FCmds;		# Alias %FCmds into %FCommand
		&print_commands;				# Commands summary
		&print_rules_summary;			# Print rules summary
	}
}

# Print statistics for one record. This subroutine exectues in the context
# built by report_stats. I heavily used dynamic scope hereafter to avoid code
# duplication.
sub print_stats {
	return 0 if eof(STATS);
	$_ = <STATS>;
	unless (/^mailstat: (\d+)/) {
		print "Statistics file is corrupted, line $.\n";
		return 0;
	}
	local($current_time) = $1;
	# Build a valid context for data structures fill-in
	local(@Top, %Rule, %Special, %Command, %FCommand, %Once, %ROnce);
	# The two first line are the @Top array
	$_ = <STATS>;
	$_ .= <STATS>;
	chop;
	@Top = split(/\s+/);
	&fill_stats;						# Fill in local data structures
	&print_summary;						# Print local summary
	# Now build a valid context for rule dumping
	local(@main'Rules, %main'Rule);
	local($i) = 0;						# Force numeric context
	local($hash);						# True when entering %Rule section
	while (<STATS>) {
		last if /^\+\+\+\+\+\+/;
		chop;
		if (/^$/) {
			$hash = 1;					# Separator between @Rules and %Rule
			next;
		}
		unless ($hash) {
			push(@main'Rules, $_);
		} else {
			$main'Rule{"H$i"} = $_;
			$i++;
		}
	}
	&main'dump_rules(*print_header, *rule_stats);
	print '=' x 79 . "\n";
	$lasttime = $current_time;
}

# Print a summary from a given record
sub print_summary {
	&print_general("Statistics");
	&print_commands;						# Commands summary
	$amount += $Top[3];						# Number of mails processed
	$bytes += $Top[6];						# Bytes processed
	$actions += $Top[4];					# Actions exectuted
	$failures += $Top[5];					# Failures reported
	foreach (keys %Special) {				# Special statistics
		$Spec{$_} += $Special{$_};
	}
	foreach (keys %Command) {				# Commands ececuted
		$Cmds{$_} += $Command{$_};
	}
	foreach (keys %FCommand) {				# Failed commands
		$FCmds{$_} += $FCommand{$_};
	}
}

# Print general informations, as found in @Top.
sub print_general {
	local($what) = @_;
	local($last) = &'ctime($lasttime);
	local($now) = &'ctime($current_time);
	local($n, $s);
	chop $now;
	chop $last;
	# Header of statistics
	print "$what from $now to $last:\n";
	print '~' x 79 . "\n";
	print "Processed $Top[3] mail";
	print "s" unless $Top[3] == 1;
	print " for a total of $Top[6] bytes";
	$n = $Special{'seen'};
	$s = $n == 1 ? '' : 's';
	print " ($n mail$s already seen)" if $n;
	print ".\n";
	print "Executed $Top[4] action";
	print "s" unless $Top[4] == 1;
	local($failed) = $Top[5];
	unless ($failed) {
		print " with no failure.\n";
	} else {
		print ", $failed of which failed.\n";
	}
	$n = 0 + $Special{'default'};
	$s = $n == 1 ? '' : 's';
	print "The default rule was applied $n time$s";
	$n = $Special{'saved'};
	$s = $n == 1 ? '' : 's';
	local($was) = $n == 1 ? 'was' : 'were';
	print " and $n message$s $was implicitely saved" if $n;
	print ".\n";
	$n = $Special{'vacation'};
	$s = $n == 1 ? '' : 's';
	print "Received $n message$s in vacation mode with no rule match.\n" if $n;
}

# Print the commands executed, as found in %Command and @Top.
sub print_commands {
	print '~' x 79 . "\n";
	local($cmd, $mode);
	local(%states, %fstates);
	local(%cmds, %fcmds);
	local(@kstates, @fkstates);
	local($n, $s);
	foreach (keys %Command) {
		($cmd, $mode) = /^(\w+):(\w+)/;
		$n = $Command{$_};
		$cmds{$cmd} += $n;
		$states{"$cmd:$mode"} += $n;
	}
	foreach (keys %FCommand) {
		($cmd, $mode) = /^(\w+):(\w+)/;
		$n = $FCommand{$_};
		$fcmds{$cmd} += $n;
		$fstates{"$cmd:$mode"} += $n;
	}
	local($total) = $Top[4];
	local($percentage);
	local($cmd_total);
	foreach $key (sort keys %cmds) {
		@kstates = sort grep(/^$key:/, keys %states);
		$cmd_total = $n = $cmds{$key};
		$s = $n == 1 ? '' : 's';
		$percentage = '0.00';
		$percentage = sprintf("%.2f", ($n / $total) * 100) if $total;
		print "$key run $n time$s ($percentage %)";
		if (@kstates == 1) {
			($mode) = $kstates[0] =~ /^\w+:(\w+)/;
			print " in state $mode";
		} else {
			$n = @kstates;
			print " in $n states";
		}
		if (defined($fcmds{$key}) && ($n = $fcmds{$key})) {
			$s = $n == 1 ? '' : 's';
			$percentage = sprintf("%.2f", ($n / $cmd_total) * 100);
			print " and failed $n time$s ($percentage %)";
		}
		if (@kstates == 1 || !$opt_a) {
			print ".\n";
		} else {
			print ":\n";
			@fkstates = sort grep(/^$key:/, keys %states);
			foreach (@kstates) {
				($mode) = /^\w+:(\w+)/;
				$n = $states{$_};
				$s = $n == 1 ? '' : 's';
				$percentage = sprintf("%.2f", ($n / $cmd_total) * 100);
				print "    state $mode: $n time$s ($percentage %)";
				$n = $fstates{$_};
				$s = $n == 1 ? '' : 's';
				print ", $n failure$s" if $n;
				print ".\n";
			}
		}
	}
}

# Return a uniform representation of a rule (suitable for usage merging)
sub uniform_rule {
	local($rulenum) = @_;
	local($text) = $main'Rules[$rulenum - 1];
	$text =~ s/^(.*}\s+)//;					# Get mode and action
	local($rule) = $1;
	local(@keys) = split(' ', $text);		# H keys for selection / patterns
	foreach (@keys) {
		$rule .= "\n" . $main'Rule{$_};		# Add selectors and patterns
	}
	$rule;
}

# Print a summary of merged rules as found in %Mrule
sub print_rules_summary {
	return unless $opt_y;
	local(@main'Rules);				# The main rules array
	local(%main'Rule);				# The H table for selectors and patterns
	local($counter) = 0;			# Counter for H key computation
	local($rulenum) = 0;			# Rule number
	local(%Rule);					# The local rule statistics array
	local(@components);				# Rule components
	local($rule);					# Constructed rule
	foreach (keys %Mrule) {
		s/^(\w+)://;				# Get applied state
		$state = $1;
		@components = split(/\n/);
		$rule = shift(@components);
		foreach (@components) {
			$rule .= " H$counter";
			$main'Rule{"H$counter"} = $_;
			$counter++;
		}
		push(@main'Rules, $rule);
		$rulenum++;
		$Rule{"$rulenum:$state"} += $Mrule{"$state:$_"};
	}
	&main'dump_rules(*print_header, *rule_stats);
}

#
# Hooks for rule dumping
#

# Print the rule number and the number of applications
sub print_header {
	local($rulenum) = @_;
	local($total_matches) = 0;
	local(@keys) = grep(/^$rulenum:/, keys %Rule);
	local($state);
	local($matches);
	# Add up the usage of rules, whatever the matching state was
	foreach (@keys) {
		$matches = $Rule{$_};
		$total_matches += $matches;
		if ($opt_y && !$in_summary) {
			($state) = /^\d+:(.*)/;
			$_ = $state . ":" . &uniform_rule($rulenum);
			$Mrule{$_} += $matches;
		}
	}
	return 0 if ($opt_u && $total_matches == 0);
	return 0 unless $opt_r;
	local($total) = $Top[3];
	$total = 1 unless $total;
	local($percentage) = sprintf("%.2f", ($total_matches / $total) * 100);
	$percentage = '0' if $total_matches == 0;
	local($s) = $total_matches == 1 ? '' : 's';
	print '-' x 79 . "\n";
	print "Rule #$rulenum, applied $total_matches time$s ($percentage %).\n";
}

# Print the rule applications, on a per-state basis
sub rule_stats {
	return unless $opt_r;
	local($rulenum) = @_;
	local($mode) = $main'Rules[$rulenum - 1] =~ /^(.*)\s+\{/;
	return unless $mode =~ /,/ || $mode eq 'ALL' || $mode =~ /!/;

	# If there is only one mode <ALL>, more than one mode, or at least
	# a negated mode, then we have a priori more than one possible mode
	# that can lead to the execution of the rule. So dump them.

	local(@keys) = grep(/^$rulenum:/, keys %Rule);
	local(%states);
	local($s, $total);
	foreach (@keys) {
		/^\d+:(.+)/;
		$states{$1}++;
	}
	@keys = keys %states;
	return unless $opt_a;
	if (@keys == 1) {
		print "Applied only in state $keys[0].\n";
	} else {
		foreach (@keys) {
			$total = $states{$_};
			$s = $total == 1 ? '' : 's';
			print "State $_: $total time$s.\n";
		}
	}
}

package main;

