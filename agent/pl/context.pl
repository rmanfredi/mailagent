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
;# $Log: context.pl,v $
;# Revision 3.0.1.3  1997/02/20  11:43:42  ram
;# patch55: removed the 'do' workaround for perl5.001
;#
;# Revision 3.0.1.2  1995/08/07  16:18:45  ram
;# patch37: fixed parsing bug in perl5.001
;#
;# Revision 3.0.1.1  1994/09/22  14:16:30  ram
;# patch12: added access routines to detect context changes
;# patch12: context is now written back to disk only when changed
;# patch12: added callout queue knowledge
;#
;# Revision 3.0  1993/11/29  13:48:38  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Keep track of the mailagent's context, in particular all the actions which
;# may be performed in a batched way and need to save some contextual data.
;#
package context;

#
# General handling
#

# Initialize context from context file
sub init {
	&default;						# Load a default context
	&load if -f $cf'context;		# Load context, overwriting default context
	&callout'init;					# Initialize callout queue
	&clean;							# Remove uneeded entries from context
}

# Provide a default context
sub default {
	%Context = (
		'last-clean', '0',			# Last cleaning of hash files
	);
}

# Load the context entries
sub load {
	unless(open(CONTEXT, "$cf'context")) {
		&'add_log("WARNING unable to open context file: $!") if $'loglvl > 5;
		return;
	}
	&'add_log("loading mailagent context") if $'loglvl > 15;
	local($_, $.);
	while (<CONTEXT>) {
		next if /^\s*#/;
		if (/^([\w\-]+)\s*:\s*(\S+)/) {
			$Context{$1} = $2;
			next;
		}
		&'add_log("WARNING context file corrupted, line $.") if $'loglvl > 5;
		last;
	}
	close CONTEXT;
}

# Clean context, removing useless entries
sub clean {
	&delete('last-clean') if $cf'autoclean !~ /^on/i && &get('last-clean');
}

# Save a new context file, if it has changed since we read it.
sub save {
	return unless $context_changed; 		# Do not save if no change
	local($existed) = -f $cf'context;
	&'acs_rqst($cf'context) if $existed;	# Lock existing file
	unless (open(CONTEXT, ">$cf'context")) {
		&'add_log("ERROR cannot overwrite context file: $!") if $'loglvl > 1;
		&'free_file($cf'context) if $existed;
		return;
	}
	&'add_log("saving context file $cf'context") if $'loglvl > 17;
	local($key, $value, $item);
	print CONTEXT "# Mailagent context, last updated " .
		scalar(localtime()) . "\n";
	while (($key, $value) = each %Context) {
		next unless $value;
		$item++;
		print CONTEXT $key, ': ', $value, "\n";
	}
	close CONTEXT;
	unlink "$cf'context" unless $item;		# Do not leave empty context
	&'add_log("deleted empty context") if $'loglvl > 17 && !$item;
	&'free_file($cf'context) if $existed;
}

#
# Access features
#

# Add or set an entry in the context
sub set {
	local($entry, $value) = @_;
	$Context{$entry} = $value;
	$context_changed++;
}

# Get a context entry value
sub get {
	local($entry) = @_;
	defined $Context{$entry} ? $Context{$entry} : undef;
}

# Delete an entry from context
sub delete {
	local($entry) = @_;
	unless (defined $Context{$entry}) {
		&'add_log("WARNING attempting to delete inexistant $entry context")
			if $'loglvl > 5;
		return;
	}
	delete $Context{$entry};
	$context_changed++;
}

#
# Context-dependant actions
#

# Remove entries in dbr hash files which are old enough. For this operation
# to be performed, the autoclean variable must be set to ON in ~/.mailagent,
# the cleanlaps indicates the period for those automatic cleanings, and agemax
# specifies the maximum allowed time within the database.
sub autoclean {
	return unless $cf'autoclean =~ /^on/i;
	local($period) = &'seconds_in_period($cf'cleanlaps);
	return if (&get('last-clean') + $period) > time;
	# Retry time reached -- start auto cleaning
	&'add_log("autocleaning of dbr files") if $'loglvl > 8;
	$period = &'seconds_in_period($cf'agemax);
	&dbr'clean($period);
	&set('last-clean', time);		# Update last cleaning time
}

#
# Perform all contextual actions
#

# Run all the contextual actions, each action returning if not needed or if
# the retry time was not reached. This routine is the main entry point in
# the package, and is the only one called from the outside world.
sub main'contextual_operations {
	&autoclean;				# Clean dbr hash files
	&callout'flush;			# Flush the callout queue
	&save;					# Save new context
}

package main;

