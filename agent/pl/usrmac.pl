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
;# $Log: usrmac.pl,v $
;# Revision 3.0.1.1  1995/01/25  15:30:21  ram
;# patch27: ported to perl 5.0 PL0
;# patch27: added eval error tracking for perl 5.0
;#
;# Revision 3.0  1993/11/29  13:49:19  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# User-defined macros are available. They all begin with %-, followed by one
;# character, for instance %-i for user-defined macro i. Once defined, they are
;# globally visible. When defining a new macro, it is possible to replace an
;# already existing definition or to stack a new definition (that is to say,
;# we define some sort of dynamic scope). It is possible to save the macro
;# state and then restore it later.
;#
;# The user may also define multi-character macros, which are then used thusly:
;# If the name is mac, then %-(mac) will expand that macro. It is also possible
;# to use %-(i) for %-i. Macro names may contain any character but '%' and ().
;#
;# At the interface level, the following calls (usrmac package) are recognized:
;#
;#   . new(name, value, type)
;#        replace or create a new macro %-(name).
;#   . delete(name)
;#        delete all values recorded for the macro.
;#   . push(name, value, type)
;#        stack a new macro, creating it if necessary.
;#   . pop(name)
;#        remove last macro definition (either push'ed or new'ed).
;#   . save
;#        save the currently defined macros in an array of names.
;#   . restore
;#        scan an array of names and keep only those macros listed there,
;#        the others being deleted.
;#
;# When specifying a macro, the value given may be one of the following types:
;#
;#   . SCALAR
;#        a scalar value is given, e.g.: 'red'.
;#   . EXPR
;#        a perl expression will be eval'ed to get the value, e.g: '$red'.
;#   . CONST
;#        a perl constant expression, eval'ed only once and then cached.
;#   . FN
;#        a perl function called with (name), the macro name.
;#   . PROG
;#        a program to be run to get the actual value. Only trailing newline
;#        is chopped, others are preserved. The program is forked each time.
;#        In the argument list given to the program, %n is expanded as the
;#        macro name we are trying to evaluate.
;#   . PROGC
;#        same as PROG but the program is forked only once and the value is
;#        cached for later perusal. The C stands for Cache or Constant,
;#        depending on your taste.
;# 
;# At the data structure level, we have:
;#
;#   . %Name
;#        returns the name of the array containing the macro stack value for
;#        that name. Stacked values are unshift'ed at the beginning so we can
;#        always read the first item regardless of the number of defined
;#        values.
;#   . @gensym
;#        the array ('gensym' is a place holder for whatever dynamic name was
;#        generated and stored as a value in %Name) containing the macro
;#        values, followed by its type.
;#   . %Type
;#        this table maps a macro type like FN on a function dealing with the
;#        macro substitution at this level.
;#
;# Saving the state means recording all the defined macro names we currently
;# have. Restoring the state simply deletes the extra values which may have
;# been added since the last save. Thus a function defining macros for its own
;# usage will perform a save, then define its own macros and call restore before
;# returning. Alternatively, it can call delete for each defined macro.
;#
;# new/delete should be used normally, and push/pop only when a temporary
;# override is needed for a macro. save/restore should not be interleaved with
;# push/pop since after the restore, some macros added by push might have
;# already been deleted completely. Likewise, pushed values on top of macros
;# saved by save will not be poped by a restore.
;#
#
# User-defined macros
#

package usrmac;

$init_done = 0;

# Defines known macro types. Each type is associated with a function which will
# be called to deal with the macro substitution for that type and returning the
# proper value. The arguments passed to it are the glob to the gensym array and
# the macro name, in case we have to deal with an FN-type value. The value for
# the macro is at index 0 in the gensym array.
sub init {
	%Type = (
		'SCALAR',	'sub_scalar',		# Scalar value
		'EXPR',		'sub_expr',			# Expression to be eval'ed each time
		'CONST',	'sub_const',		# Constant eval'ed only once
		'FN',		'sub_fn',			# Perl function to be called
		'PROG',		'sub_prog',			# A program to call
		'PROGC',	'sub_progc',		# Program to call once, result cached
	);
}

# Add a new macro in the table. If one already existed, the new value is pushed
# before the old one and will be used in subsequent substitutions.
sub push {
	local($name, $value, $type) = @_;	# Name, value and type
	local($gensym);						# Generated array name storing values
	&init unless $init_done++;
	$gensym = defined $Name{$name} ? $Name{$name} : &'gensym;
	$Name{$name} = $gensym;				# Make a nested data structure
	eval "unshift(\@$gensym, \$value, \$Type{\$type})";
	&'add_log("ERROR usrmac'push: $@") if $@;
}

# Create a brand new macro or replace the one currently visible.
sub new {
	local($name, $value, $type) = @_;	# Name, value and type
	local($gensym);						# Generated array name storing values
	&init unless $init_done++;
	$gensym = defined $Name{$name} ? $Name{$name} : &'gensym;
	$Name{$name} = $gensym;				# Make a nested data structure
	eval "\@$gensym\[0, 1\] = (\$value, \$Type{\$type})";
	&'add_log("ERROR usrmac'new: $@") if $@;
}

# Remove topmost macro definition
sub pop {
	local($name) = @_;					# Macro to undefine at this level
	return unless defined $Name{$name};	# Nothing here it would seem
	local($gensym) = $Name{$name};		# Array storing macro definition
	eval "shift(\@$gensym); shift(\@$gensym)";
	&'add_log("ERROR usrmac'pop: $@") if $@;
}

# Delete the whole (possibly stacked) macro entries under a given name.
sub delete {
	local($name) = @_;
	return unless defined $Name{$name};	# Ooops... Has already been done
	local($gensym) = $Name{$name};		# Array storing macro definition
	eval "undef \@$gensym";				# Delete the value array
	&'add_log("ERROR usrmac'delete: $@") if $@;
	delete $Name{$name};				# As well as the entry in name table
}

# Save the valid macro names we currently have. Returns an array of names.
sub save {
	keys %Name;		# List of currently defined macros
}

# Restore the name space we had at the time the save was made, deleting all the
# macro names which are now defined and were not present at that time. Note
# that stacked macro definitions are deleted in one block.
sub restore {
	local(@names) = @_;			# Names we had at that time
	local(%saved);				# Tell us whether a name was saved or not
	foreach $key (@names) {		# Build a hash table of names for faster access
		$saved{$key}++;
	}
	foreach $key (keys %Name) {	# Delete all macros not defined at save time
		&delete($key) unless $saved{$key};
	}
}

#
# User-defined substitutions
#

# Perform the user-defined macro substitution and return the value string.
# (called from macros_subst in macros.pl).
sub macro'usr {
	local($name) = @_;		# Macro name
	return '' unless defined $Name{$name};	# Unknown macro
	local($gensym) = $Name{$name};			# Get value array
	return '' unless $gensym;				# Key present, but nothing there
	local($glob) = eval "*$gensym";			# Type glob to value array
	local(*array) = $glob;					# From now on, @array is set
	local($function) = $array[1];			# How to deal with that macro type
	$function = $Type{'SCALAR'} unless $function;
	&$function($glob, $name);				# Propagate return value
}

#
# Type-dependant substitutions
#

# Substitute a scalar value, simply return the verbatim value we got.
sub sub_scalar {
	local(*ary, $name) = @_;
	$ary[0];
}

# Evaluate a perl expression and return the scalar result
sub sub_expr {
	local(*ary, $name) = @_;
	eval $ary[0];
}

# Evaluate a perl expression and cache the result as a scalar value
sub sub_const {
	local(*ary, $name) = @_;
	local($result) = eval $ary[0];
	&cache(*ary, $result);			# Cache and propagate result
}

# Call a perl function to evaluate the macro. Function should be a fully
# qualified name, with package info, unless it is explicitely defined in
# the usrmac package.
sub sub_fn {
	local(*ary, $name) = @_;
	eval "&$ary[0](\$name)";
}

# Call an external program, grab its output and remove final character. Then
# return that as a result of the substitution. That program should execute
# quickly. Use a PROGC type to cache the result if the value returned does not
# change. In the argument list, %n is taken as the macro name.
sub sub_prog {
	local(*ary, $name) = @_;
	local($prog) = $ary[0];
	$prog =~ s/%%/#%#/g;			# Escape %
	$prog =~ s/%n/$name/g;			# Replace %n by macro name
	$prog =~ s/#%#/%/g;				# %% turns out as a single %
	local($result);					# To store program output
	chop($result = `$prog 2>&1`);	# Invoke program, merge stdout and stderr
	$result;						# Return output
}

# Same a sub_prog but cache the result as a scalar value to avoid other calls
# to that same program.
sub sub_progc {
	local(*ary, $name) = @_;
	local($result) = &sub_prog(*ary, $name);
	&cache(*ary, $result);			# Cache and propagate result
}

#
# Value caching
#

# Cache computed value by making it a SCALAR-type macro value so that further
# calls to evaluate that macro will simply return that cached information.
# The result value passed as argument is returned unchanged.
sub cache {
	local(*ary, $result) = @_;
	$ary[0] = $result;				# Cache result for further invocations
	$ary[1] = $Type{'SCALAR'};		# Make value a simple scalar
	$result;						# Return computed value
}

package main;

