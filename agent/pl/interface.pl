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
;# $Log: interface.pl,v $
;# Revision 3.0.1.6  1998/03/31  15:23:00  ram
;# patch59: added hook for the new ON command
;#
;# Revision 3.0.1.5  1997/02/20  11:45:12  ram
;# patch55: made use of local $lastcmd instead of main's
;#
;# Revision 3.0.1.4  1995/08/07  16:19:24  ram
;# patch37: new BIFF command interface routine for PERL hooks
;# patch37: fixed symbol table lookups for perl5 support
;#
;# Revision 3.0.1.3  1995/02/16  14:33:49  ram
;# patch32: forgot to add interfaces for BEEP and PROTECT
;#
;# Revision 3.0.1.2  1994/09/22  14:23:38  ram
;# patch12: mailhook package cleaning now done only for subroutines
;# patch12: package name is separated with '::' in perl5
;#
;# Revision 3.0.1.1  1994/07/01  15:01:19  ram
;# patch8: new UMASK command
;# patch8: cannot dataload exit
;#
;# Revision 3.0  1993/11/29  13:48:53  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This is for people who, like me, are perl die-hards :-). It simply provides
;# a simple perl interface for hook scripts and PERL commands. Instead of
;# writing 'COMMAND with some arguments;' in the filter rule file, you may say
;# &command('with some arguments') in the perl script. Big deal! Well, at least
;# that brings you some other nice features from perl itself ;-).
;#
#
# Perl interface with the filter actions
#

package mailhook;

sub abort		{ &interface'dispatch; }
sub annotate	{ &interface'dispatch; }
sub apply		{ &interface'dispatch; }
sub assign		{ &interface'dispatch; }
sub back		{ &interface'dispatch; }
sub beep		{ &interface'dispatch; }
sub begin		{ &interface'dispatch; }
sub biff		{ &interface'dispatch; }
sub bounce		{ &interface'dispatch; }
sub delete		{ &interface'dispatch; }
sub feed		{ &interface'dispatch; }
sub forward		{ &interface'dispatch; }
sub give		{ &interface'dispatch; }
sub keep		{ &interface'dispatch; }
sub leave		{ &interface'dispatch; }
sub macro		{ &interface'dispatch; }
sub message		{ &interface'dispatch; }
sub nop			{ &interface'dispatch; }
sub notify		{ &interface'dispatch; }
sub on			{ &interface'dispatch; }
sub once		{ &interface'dispatch; }
sub pass		{ &interface'dispatch; }
sub perl		{ &interface'dispatch; }
sub pipe		{ &interface'dispatch; }
sub post		{ &interface'dispatch; }
sub process		{ &interface'dispatch; }
sub protect		{ &interface'dispatch; }
sub purify		{ &interface'dispatch; }
sub queue		{ &interface'dispatch; }
sub record		{ &interface'dispatch; }
sub reject		{ &interface'dispatch; }
sub require		{ &interface'dispatch; }
sub restart		{ &interface'dispatch; }
sub resync		{ &interface'dispatch; }
sub run			{ &interface'dispatch; }
sub save		{ &interface'dispatch; }
sub select		{ &interface'dispatch; }
sub server		{ &interface'dispatch; }
sub split		{ &interface'dispatch; }
sub store		{ &interface'dispatch; }
sub strip		{ &interface'dispatch; }
sub subst		{ &interface'dispatch; }
sub tr			{ &interface'dispatch; }
sub umask		{ &interface'dispatch; }
sub unique		{ &interface'dispatch; }
sub vacation	{ &interface'dispatch; }
sub write		{ &interface'dispatch; }

# A perl filtering script should call &exit and not exit directly.
# Perload OFF
# (Cannot be data-loaded or it will corrupt $@ expected by &main'perl)
sub exit { 
	local($code) = @_;
	die "OK\n" unless $code;
	die "Exit $code\n";
}
# Perload ON

package interface;

# Perload OFF
# (Cannot be dynamically loaded as it uses the caller() function)

# The dispatch routine is really simple. We compute the name of our caller,
# prepend it to the argument and call run_command to actually run the command.
# Upon return, if we get anything but a continue status, we simply die with
# an 'OK' string, which will be a signal to the routine monitoring the execution
# that nothing wrong happened.
sub dispatch {
	local($args) = join(' ', @_);			# Arguments for the command
	local($name) = (caller(1))[3];			# Function which called us
	local($status);							# Continuation status
	$name =~ s/^\w+('|::)//;				# Strip leading package name
	&'add_log("calling '$name $args'") if $'loglvl > 18;
	$status = &'run_command("$name $args");	# Case does not matter

	# The status propagation is the only thing we have to deal with, as this
	# is handled within run_command. All other variables which are meaningful
	# for the filter are dynamically bound to function called before in the
	# stack, hence they are modified directly from within the perl script.

	die "Status $status\n" unless $status == $'FT_CONT;

	# Return the status held in $lastcmd, unless the command does not alter
	# the status significantly, in which case we return success. Note that
	# this is in fact a boolean success status, so 1 means success, whereas
	# $lastcmd records a failure status.

	$name =~ tr/a-z/A-Z/;					# Stored upper-cased
	$'Nostatus{$name} ? 1 : !$'lastcmd;		# Propagate status
}

# Perload ON

$in_perl = 0;					# Number of nested perl evaluations

# Record entry in new perl evaluation
sub new {
	++$in_perl;					# Add one evalution level
}

# Reset an empty mailhook package by undefining all its symbols.
# (Warning: heavy wizardry used here -- look at perl's manpage for recipe.)
sub reset {
	return if --$in_perl > 0;	# Do nothing if pending evals remain
	&'add_log("undefining variables from mailhook") if $'loglvl > 11;
	local($key, $val);			# Key/value from perl's symbol table
	# Loop over perl's symbol table for the mailhook package
	eval "*_mailhook = *::mailhook::" if $] > 5;	# Perl 5 support
	while (($key, $val) = each(%_mailhook)) {
		local(*entry) = $val;	# Get definitions of current slot
		# Temporarily disable those. They are causing problems with perl
		# 4.0 PL36 on some machines when running PERL escapes. Keep only
		# the removal of functions since the re-definition of routines is
		# the most harmful with perl 4.0.
		#undef $entry unless length($key) == 1 && $key !~ /^\w/;
		#undef @entry;
		#undef %entry unless $key =~ /^_/ || $key eq 'header';
		undef &entry if defined &entry && &valid($key);
		$_mailhook{$key} = *entry;	# Commit our changes
	}
}

# Return true if the function may safely be undefined
sub valid {
	local($fun) = @_;			# Function name
	return 0 if $fun eq 'exit';	# This function is a convenience
	# We cannot undefine a filter function, which are listed (upper-cased) in
	# the %main'Filter table.
	return 1 unless length($fun) == ($fun =~ tr/a-z/A-Z/);
	return 1 unless $'Filter{$fun};
	0;
}

# Add a new interface function for user-defined commands
sub add {
	local($cmd) = @_;			# Command name
	$cmd =~ tr/A-Z/a-z/;		# Cannonicalize to lower case
	eval &'q(<<EOP);			# Compile new mailhook perl interface function
:	sub mailhook'$cmd { &interface'dispatch; }
EOP
	if (chop($@)) {
		&'add_log("ERROR while adding 'sub $cmd': $@") if $'loglvl;
		&'add_log("WARNING cannot use '&$cmd' in perl hooks")
			if $'loglvl > 5;
	}
}

package main;

