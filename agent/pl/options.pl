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
;# $Log: options.pl,v $
;# Revision 3.0.1.2  1995/08/07  16:21:11  ram
;# patch37: fixed syntax error when restoring previous option values
;#
;# Revision 3.0.1.1  1995/01/03  18:14:03  ram
;# patch24: created
;#
;#
;# This file handles filtering command option parsing. It is derived from the
;# getopts.pl file from the perl 4.0 library, with minor adaptations.
;#
;# Usage:
;#      &opt'get(name, 'a:bc', *args);  # -a takes arg. -b & -c not.
;#                                      # Sets $opt'sw_* as a side effect.
;#
;# For each action there is a syntax table describing which options are
;# recognized and whether or not they take options. If they do, i.e. if there
;# is a non-null option list, the &opt'get routine is called to set $opt'i
;# and friends.
;#
package opt;

# Given a command list, an option syntax specification, and a glob on the
# array containing the command arguments, set the $sw_* variables for each
# of the recognized options and returns true if ok.
sub get {
	local($me, $argumentative, *argv) = @_;
	local(@args, $_, $first, $rest);
	local($errs) = 0;

	@args = split(/ */, $argumentative);
	while (@argv) {
		$_ = $argv[0];
		do { shift(@argv), next } if /^\s+$/;	# Skip spaces (see &parse)
		last unless /^-(\w)(.*)/;
		($first, $rest) = ($1, $2);
		$pos = index($argumentative, $first);
		if ($pos >= 0) {
			if ($args[$pos+1] eq ':') {
				shift(@argv);
				if ($rest eq '') {
					++$errs unless @argv;
					$rest = shift(@argv);
				}
				eval "\$sw_$first = \$rest;";
			} else {
				eval "\$sw_$first = 1";
				if($rest eq '') {
					shift(@argv);
				} else {
					$argv[0] = "-$rest";
				}
			}
		} else {
			&'add_log("WARNING: unknown option -$first for $me")
				if $'loglvl > 5;
			++$errs;
			if ($rest ne '') {
				$argv[0] = "-$rest";
			} else {
				shift(@argv);
			}
		}
	}
	$errs == 0;
}

# Reset the switch variables by saving their current values and undefining them
sub reset {
	unless (defined &RESET) {
		local($reset) = "sub RESET {\n";
		foreach $opt ('a'..'z', 'A'..'Z', '1'..'9','_') {
			$reset .=
				"push(\@sw_$opt, defined(\$sw_$opt) ? \$sw_$opt : undef);
				undef \$sw_$opt;\n";
		}
		$reset .= "}\n";
		eval $reset;
	}
	&RESET;
}

# Restore the previous value for all the available switch variables
sub restore {
	unless (defined &RESTORE) {
		local($restore) = "sub RESTORE {\n";
		foreach $opt ('a'..'z', 'A'..'Z', '1'..'9','_') {
			$restore .= "\$sw_$opt = pop(\@sw_$opt);\n";
		}
		$restore .= "}\n";
		eval $restore;
	}
	&RESTORE;
}

# Parse the options for a given filtering command. Although we are breaking
# the command into words for the sake of option parsing, we must ensure we
# are not actually destroying multiple spaces in the arguments.
# Returns the new command string with all the (recognized) options stripped.
sub parse {
	local($cmd, $argumentative) = @_;
	local($me);
	local(@argv) = split(/(\s+)/, $cmd);	# Preserve spaces into @argv
	$me = shift(@argv);						# Remove command name
	$me =~ tr/a-z/A-Z/;						# Translate to upper-case
	&get($me, $argumentative, *argv);		# Ignore return status
	return join('', "$me ", @argv);
}

package main;

