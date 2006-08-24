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
;# $Log: hook.pl,v $
;# Revision 3.0.1.3  1997/02/20  11:44:12  ram
;# patch55: used $wmode and $loglvl from the wrong package
;#
;# Revision 3.0.1.2  1996/12/24  14:52:38  ram
;# patch45: perform security checks on hook programs
;#
;# Revision 3.0.1.1  1995/01/03  18:11:45  ram
;# patch24: routine &perl now calls &main'perl directly to do its job
;# patch24: no longer pre-extend variable when reading top 128 bytes
;#
;# Revision 3.0  1993/11/29  13:48:51  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# A mail hook (in the mailagent terminology) is an external file which
;# transparently influences some of the mailagent actions by injecting user-
;# defined actions at some well-defined places. Currently, the only hooks
;# available are executable folders, activated via the SAVE, STORE, and LEAVE
;# commands.
;#
;# The hook_type function parses the top of the hook file, looking for magic
;# token which will give hints regarding the type of the hook. Then the
;# corresponding hook function will be called with the file name where the mail
;# is stored given as first argument (an empty string meaning the mail is to be
;# fetched from stdin), the second argument being the hook file name.
;#
;# Five types of hooks are currently supported:
;#   - Simple program: the mail is simply fed to the standard input of the
;#     program. The exit status is propagated to the mailagent.
;#   - Rule file: the mail is to be re-analyzed according to the new rules
;#     held in the hook file. The APPLY command is used, and mode is reset to
;#	   the default INITIAL state.
;#   - Audit script: This is a perl script. Following the spirit of Martin
;#     Streicher's audit.pl package, some special variables are magically set
;#     prior to the invocation of script within the special mailhook package,
;#     in which the script is compiled.
;#   - Deliver script: Same as an audit script, excepted that the output of the
;#     script is monitored and taken as mailagent commands, which will then
;#     be executed on the original message upon completion of the script.
;#   - Perl script: This is an audit script with full access to the mailagent
;#     primitives for filtering (same as the ones provided with a PERL command).
;#
#
# Mailhook handling
#

package hook;

# Hooks constants definitions
sub init {
	$HOOK_UNKNOWN = "hook'unknown";		# Hook type was not recognized
	$HOOK_PROGRAM = "hook'program";		# Hook is a filter program
	$HOOK_AUDIT = "hook'audit";			# Hook is an audit-like script
	$HOOK_DELIVER = "hook'deliver";		# Hook is a deliver-like script
	$HOOK_RULES = "hook'rules";			# Hook is a rule file
	$HOOK_PERL = "hook'perl";			# Hook is a perl script
}

# Deal with the hook
sub process {
	&init unless $init_done++;			# Initialize hook constants
	local($hook) = @_;
	local($type) = &type($hook);		# Get hook type
	&hooking($hook, $type);				# Print log message
	unless (chdir $cf'home) {
		&'add_log("WARNING cannot chdir to $cf'home: $!") if $'loglvl > 5;
	}
	eval '&$type($hook)';				# Call hook (inside eval to allow die)
	&'eval_error;						# Report errors and propagate status
}

# Determine the nature of the hook. The top 128 bytes are scanned for a magic
# number starting with #: and followed by some words. The type of the hook
# is determined by the first word (case insensitively).
sub type {
	local($file) = @_;			# Name of hook file
	-f "$file" || return $HOOK_UNKNOWN;		
	-x _ || return $HOOK_UNKNOWN;
	open(HOOK, $file) || return $HOOK_PROGRAM;
	local($hook);
	sysread(HOOK, $hook, 128);	# Consider only top 128 bytes
	close(HOOK);
	local($name) = $hook =~ /^#:\s*(\w+)/;
	$name =~ tr/A-Z/a-z/;
	return $HOOK_AUDIT if $name eq 'audit';
	return $HOOK_DELIVER if $name eq 'deliver';
	return $HOOK_RULES if $name eq 'rules';
	return $HOOK_PERL if $name eq 'perl';
	$HOOK_PROGRAM;				# No magic token found
}

#
# Hook functions
#

# The hook file is not valid
sub unknown {
	local($hook) = @_;
	die("$hook is not a hook file");
}

# Mail is to be piped to the hook program (on stdin)
sub program {
	local($hook) = @_;
	&'add_log("hook is a plain program") if $'loglvl > 17;
	local($failed) = &'shell_command($hook, $'MAIL_INPUT, $'NO_FEEDBACK);
	die("cannot run $hook") if $failed;
}

# Mail is to be filetered with rules from hook file
sub rules {
	local($hook) = @_;
	&'add_log("hook contains mailagent rules") if $'loglvl > 17;
	die("unsecure hook") unless &'file_secure($hook, 'rule hook');
	local($'wmode) = 'INITIAL';		# Force working mode of INITIAL
	local($failed, $saved) = &'apply($hook);
	die("cannot apply rules") if $failed;
	unless ($saved) {
		&'add_log("NOTICE not saved, leaving in mailbox") if $'loglvl > 5;
		&'xeqte("LEAVE");
	}
}

# Mail is to be filtered through a perl script
sub perl {
	local($hook) = @_;
	&'add_log("hook is a perl script") if $'loglvl > 17;
	die("unsecure hook") unless &'exec_secure($hook, 'perl hook');
	local($failed) = &'perl($hook);
	die("cannot run perl hook") if $failed;
}

# Hook is an audit script. Set up a suitable environment and execute the
# script after having forked a new process. To avoid name clashes, the script
# is compiled in a dedicated 'mailhook' package and executed.
# Note: the only difference with the perl hook is that we need to fork an
# extra process to run the hook, since it might use a plain 'exit', which would
# be desastrous on the mailagent.
sub audit {
	local($hook) = @_;
	&'add_log("hook is an audit script") if $'loglvl > 17;
	die("unsecure hook") unless &'exec_secure($hook, 'audit hook');
	local($pid) = fork;
	$pid = -1 unless defined $pid;
	if ($pid == 0) {				# Child process
		&initvar('mailhook');		# Initialize special variables
		&run($hook);				# Load hook and run it
		exit(0);
	} elsif ($pid == -1) {
		&'add_log("ERROR cannot fork: $!") if $'loglvl;
		die("cannot audit with hook");
	}
	# Parent process comes here
	wait;
	die("audit hook failed") unless $? == 0;
}

# A delivery script is about the same as an audit script, except that the
# output on stdout is monitored and understood as mailagent commands to be
# executed upon successful return.
sub deliver {
	local($hook) = @_;
	&'add_log("hook is a deliver script") if $'loglvl > 17;
	die("unsecure hook") unless &'exec_secure($hook, 'deliver hook');
	# Fork and let the child do all the work. The parent simply captures the
	# output from child's stdout.
	local($pid);
	$pid = open(HOOK, "-|");	# Implicit fork
	unless (defined $pid) {
		&'add_log("ERROR cannot fork: $!") if $'loglvl;
		die("cannot deliver to hook");
	}
	if (0 == $pid) {			# Child process
		&initvar('mailhook');	# Initialize special variables
		&run($hook);			# Load hook and run it
		exit(0);				# Everything went well
	}
	# Parent process comes here
	local($output) = ' ' x (-s HOOK);
	{
		local($/) = undef;		# We wish to slurp the whole output
		$output = <HOOK>;
	}
	close HOOK;					# An implicit wait -- status put in $?
	unless (0 == $?) {
		&'add_log("ERROR hook script failed") if $'loglvl;
		die("non-zero exit status") unless $output;
		die("commands ignored");
	}
	if ($output eq '') {
		&'add_log("WARNING no commands from delivery hook") if $'loglvl > 5;
	} else {
		&main'xeqte($output);	# Run mailagent commands
	}
}

# Log hook operation before it happens, as we may well exec() another program.
sub hooking {
	local($hook, $type) = @_;
	local($home) = $cf'home;
	$home =~ s/(\W)/\\$1/g;		# Escape possible meta-characters
	$type =~ s/^hook'//;
	$hook =~ s/^$home/~/;
	&'add_log("HOOKING [$'mfile] to $hook ($type)") if $'loglvl > 4;
}

package main;

