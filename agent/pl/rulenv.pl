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
;# $Log: rulenv.pl,v $
;# Revision 3.0.1.3  1995/08/07  16:24:06  ram
;# patch37: new support for biff and biffmsg variable environment
;# patch37: fixed environment setup code
;#
;# Revision 3.0.1.2  1995/01/25  15:28:49  ram
;# patch27: new routines &unset and &undef
;# patch27: added default values for PROTECT and BEEP
;# patch27: added logs in case of eval errors for perl 5.0
;#
;# Revision 3.0.1.1  1995/01/03  18:14:46  ram
;# patch24: created
;#
;#
;# These routines handle the local rule environment. Configuration variables
;# that must be permanently changed can be assigned to directly. However,
;# configuration variables that require a local setting only must be set
;# with &env'local(variable, value);
;#
;# Before calling the processing of rules, &env'setup must be called.
;# Once the processing is done, &env'restore will restore the original value
;# of all modified variables. The value saved is the one the variable had the
;# first time it was locally modified within the rule. Any other global
;# assigment is lost.
;#
;# This works by setting up a %Var array. The first time a local setting is
;# used, an entry is created in the table recording the current value. Further
;# local modifications do not alter the value held in %Var.
;#
package env;

# %Spec contains special actions that must be peformed when the original
# value of a variable is restored. For instance, when restoring the umask, a
# system call must also be performed to restore the correct system value.
# That code is called *after* the variable has retained its previous value.
# %Spec is indexed by variable name and must contain valid perl code.
sub init {
	%Spec = (
		'umask',	'umask($umask)',
	);
	@Env = (		# Variables handled by local environment
		'umask',
		'vacperiod', 'vacfile',
		'biff', 'biffmsg',
	);
	foreach $var (@Env) {
		$SETUP .= "\$$var = \$cf'$var;\n";	# Copy value from config
	}
}

# Set-up initial environment for rules.
# This routine is called once for every mail parsed.
sub setup {
	&init unless %Spec;
	eval $SETUP if $SETUP ne '';
	&'add_log("ERROR env'setup: $@") if $@;
	undef %Var;

	#
	# Default environment setting not copied from configuration...
	#

	$vacation = 1;		# Vacation message allowed, if configured of course
	undef $protect;		# Default protection (from umask setting) applies
	$beep = 1;			# When biffing, %b expands to one ^G.
}

# Make a local modification to a variable
sub local {
	local($var, $value) = @_;	# Variable name, new value
	eval "\$Var{'".$var."'} = defined(\$$var) ? \$".$var.' : undef;'
		unless defined $Var{$var};
	eval "\$$var = \$value;" unless $@;
	&'add_log("ERROR env'local: $@") if $@;
}

# Erase all instances of a variable. If there was a local instance, it is
# destroyed as well as any global one. To erase a local instance only if
# there is one, use &env'undef.
sub unset {
	local($var) = @_;			# Variable name
	eval "undef \$$var;";
	eval "delete \$Var{'".$var."'};" unless $@;
	&'add_log("ERROR env'unset: $@") if $@;

}

# Undefine last occurrence of a variable.
sub undef {
	local($var) = @_;			# Variable name
	eval "\$$var = defined \$Var{'$var'} ? \$Var{'$var'} : undef;\n";
	&'add_log("ERROR env'undef: $@") if $@;
}

# Restore variables to the value held in the %Var table (key = variable name).
# If an action is required by the resetting of a variable, it is performed
# following the directive from the %Spec table.
sub restore {
	return unless %Var;
	local($code) = '';		# Code built to restore original variable values
	foreach $var (keys %Var) {
		$code .= "\$$var = \$Var{'$var'};\n";
		$code .= $Spec{$var} . ";\n" if defined $Spec{$var};
	}
	eval $code if $code ne '';
	&'add_log("ERROR env'restore: $@") if $@;
	undef %Var;
}

# Cleanup environment processing
sub cleanup {
	&restore;		# For possible side-effects in %Spec
}

package main;

