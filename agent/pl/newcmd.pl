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
;# $Log: newcmd.pl,v $
;# Revision 3.0.1.2  1995/01/03  18:12:58  ram
;# patch24: it is no longer possible to get at the vacation variable
;#
;# Revision 3.0.1.1  1994/09/22  14:28:06  ram
;# patch12: ensures the newcmd file is secure
;# patch12: propagates glob for folder_saved
;#
;# Revision 3.0  1993/11/29  13:49:03  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This package handles the dynamic loading of a perl script in memory,
;# providing a dynamic way of enhancing the command set of the mailagent.
;#
;# New commands are specified in the newcmd file specified in the config file.
;# The syntax of this file is the following:
;#
;#   <cmd_name> <path> <function> [<status_flag> [<seen_flag>]]
;#
;# cmd_name: this is the command name, eg. RETURN_SENDER
;# path: this is the path to the perl script implementing the command.
;# function: the perl function within the script which implements the command
;# status_flag: states whether the command modifies the execution status
;# seen_flag: states whether the command is allowed in _SEEN_ mode
;# 
;# The last two booleans are optional, and may be specified as either 'yes'
;# and 'no' or 'true' and 'false'. Their default value is respectively true
;# and false.
;#
;# New commands are loaded as they are used and put in a special newcmd
;# package, so that the names of the routines do not conflict with the
;# mailagent's one. They are free to use whatever function the mailagent
;# implements by prefixing the routine name with its package: normally, the
;# execution of the command is done from within the newcmd package.
;#
;# Commands are given a single argument: the string forming the command name.
;# Therefore, the command may implement the syntax it wishes. However, for
;# the user convenience, the special array @newcmd'argv is preset with a
;# shell-style parsed version. The mailagent also initializes the same
;# special variables as the one set for PERL commands, only does it put them
;# in the newcmd package instead of mailhook.
;#
;# Several data structures are maintained by this package:
;#   %Usercmd, maps a command name to a file
;#   %Loaded, records whether a file has been loaded or not
;#   %Run, maps a command name to a perl function
;#

package newcmd;

#
# User-defined commands
#

# Parse the newcmd file and record all new commands in the mailagent data
# structures.
sub load {
	return unless -s $cf'newcmd;	# Empty or non-existent file

	# Security checks. We cannot extend the mailagent commands if the file
	# describing those new commands is not owned by the user or ir world
	# writable. Indeed, someone could redefine default commands like LEAVE
	# and use that to break into the user account.
	return unless &'file_secure($cf'newcmd, 'new command');

	unless (open(NEWCMD, $cf'newcmd)) {
		&'add_log("ERROR cannot open $cf'newcmd: $!") if $'loglvl;
		&'add_log("WARNING new commands not loaded") if $'loglvl > 5;
		return;
	}

	local($home) = $cf'home;
	$home =~ s/(\W)/\\$1/g;			# Escape possible meta-characters like '+'

	local($_);
	local($cmd, $path, $function, $status, $seen);
	while (<NEWCMD>) {
		next if /^\s*#/;			# Skip comments
		next if /^\s*$/;			# Skip blank lines
		($cmd, $path, $function, $status, $seen) = split(' ');
		$cmd =~ tr/a-z/A-Z/;		# Cannonicalize to upper-case
		$path =~ s/~/$cf'home/;		# Perform ~ substitution
		unless (-e $path && -r _) {
			$path =~ s/^$home/~/;
			&'add_log("ERROR command '$cmd' bound to unreadable file $path")
				if $'loglvl > 1;
			next;					# Skip invalid command
		}
		unless (&'file_secure($path, "user command $cmd")) {
			&'add_log("ERROR command '$cmd' is not secure")
				if $'loglvl > 1;
			next;					# Skip unsecure command
		}
		# Load command into data structures by setting internal tables
		$'Filter{$cmd} = "newcmd'run";		# Main dispatcher for new commands
		$Usercmd{$cmd} = $path;				# Record command path
		$Loaded{$path} = 0;					# File not loaded yet
		$Run{$cmd} = $function;				# Perl function to call
		$'Nostatus{$cmd} = 1 if $status =~ /^f|n/i;
		$'Rfilter{$cmd} = 1 unless $seen =~ /^t|y/i;
		&interface'add($cmd);				# Add interface for perl hooks

		$path =~ s/^$home/~/;
		&'add_log("new command $cmd in $path (&$function)")
			if $'loglvl > 18;
	}
	close NEWCMD;
}

# This is the main dispatcher for user-defined command.
# Our caller 'run_command' has set up some special variables, like $mfile
# and $cmd_name, which are used here. Someday, I'll have to encapsulate that
# in a better way--RAM.
sub run {
	# Make global variables visible in this package. Variables which should
	# not be changed are marked 'read only'.
	local($cmd) = $'cmd;					# Full command line (read only)
	local($cmd_name) = $'cmd_name;			# Command name (read only)
	local($mfile) = $'mfile;				# File name (read only)
	local(*ever_saved) = *'ever_saved;		# Saving already occurred?
	local(*folder_saved) = *'folder_saved;	# Last folder saved to
	local(*cont) = *'cont;					# Continuation status
	local(*lastcmd) = *'lastcmd;			# Last failure status stored
	local(*wmode) = *'wmode;				# Filter mode

	&'add_log("user-defined command $cmd_name") if $'loglvl > 15;

	# Let's see if we already have loaded the perl script which is responsible
	# for implementing this command.
	local($path) = $Usercmd{$cmd_name};
	unless ($path) {
		&'add_log("ERROR unknown user-defined command $cmd_name") if $'loglvl;
		return 1;					# Command failed (should not happen)
	}
	local($function) = $Run{$cmd_name};

	unless (&dynload'load('newcmd', $path, $function)) {
		&'add_log("ERROR cannot load code for user-defined $cmd_name")
			if $'loglvl;
		return 1;			# Command failed
	}

	# At this point, we know we have some code to call in order to run the
	# user-defined command. Prepare the special array @ARGV and initialize
	# the mailhook variable in the current package.
	&hook'initvar('newcmd');		# Initialize convenience variables
	local(@ARGV);					# Argument vector for command
	require 'shellwords.pl';
	eval '@ARGV = &shellwords($cmd)';

	# We don't need to protect the following execution within an eval, since
	# we are currently inside one, via run_command.
	local($failed) = &$function($cmd);		# Call user-defined function

	# Log our action
	local($msg) = $failed ? "and failed" : "successfully";
	&'add_log("ran $cmd_name [$mfile] $msg") if $'loglvl > 6;

	$failed;			# Propagate failure status
}

package main;

