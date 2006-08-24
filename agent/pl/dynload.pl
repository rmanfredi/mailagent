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
;# $Log: dynload.pl,v $
;# Revision 3.0.1.1  1994/09/22  14:17:09  ram
;# patch12: added the &do routine to support new DO filtering command
;#
;# Revision 3.0  1993/11/29  13:48:40  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Dynamic loading of a file into a given package, with a few extra features,
;# like having the private mailagent lib prepended automatically to the @INC
;# array. The %Loaded array records the files which have already been loaded
;# so that we do not load the same file twice. The key records the package
;# name and then the file, separated by a ':'.
;#
;# Additionally, the &do routine can be given an argument of the form:
;#    package'routine
;#    COMMAND:package'routine
;#    file:package'routine
;# and would then call &load with the proper arguments. Of course, in the first
;# case, nothing is to be done but to check that the routine is already there.
;# The second and third case enable loading of a routine from a specific file,
;# of from a file defining a new command. Distinction is made by looking at
;# the commands first, which should not be the source of too many conflicts
;# when a path with '/' is given...
#
# Load function into package
#

package dynload;

# Load function within a package and returns undef if the package cannot be
# loaded, 0 if the file was loaded but contained some syntax error and 1 if
# loading was successful. If the function parameter is also specified, then
# the file is supposed to define that function, so we make sure it is so.
sub load {
	local($package, $file, $function) = @_;
	local($key) = "$package:$file";
	unless ($Loaded{$key}) {					# No reading attempt made yet
		local($res) = &parse($package, $file);	# Load and parse file
		$Loaded{$key} = 0;						# Mark loading attempt
		unless (defined($res) && $res) {		# Error
			return defined($res) ? $res : undef;
		}
	}

	if (defined $function) {	# File supposed to have defined a function
		# Make sure the function is defined by eval'ing a small script in the
		# context of the package where the file was loaded. Indeed, the package
		# name is implicit and defaults to that loading package.
		local($defined);
		eval("package $package; \$dynload'defined = 1 if defined &$function");
		unless ($defined) {
			&'add_log("ERROR script $file did not provide &$function")
				if $'loglvl;
			return 0;			# Definition failed
		}
	}

	$Loaded{$key} = 1;			# Mark and propagate success
}

# Load file into memory and parse it. Returns undef if file cannot be loaded,
# 0 on parsing error and 1 if ok.
sub parse {
	local($package, $file) = @_;
	unless (open(PERL, $file)) {
		&'add_log("SYSERR open: $!") if $'loglvl;
		&'add_log("ERROR cannot load $file into $package") if $'loglvl;
		return undef;		# Cannot load file
	}
	local($body) = ' ' x (-s PERL);		# Pre-extend variable
	{
		local($/) = undef;				# Slurp the whole thing
		$body = <PERL>;					# Load into memory
	}
	close PERL;
	local(@saved) = @INC;				# Save perl INC path (might change)
	unshift(@INC, $'privlib);			# Required files first searched there
	eval "package $package;" . $body;	# Eval code into memory
	@INC = @saved;						# Restore original require search path
	$Loaded{$key} = 0;					# Be conservative and assume error...

	if (chop($@)) {				# Script has an error
		&'add_log("ERROR in $file: $@") if $'loglvl;
		$@ = '';				# Clear error
		return 0;				# Eval failed
	}
	1;		# Ok so far
}

# Inspect their request closely, trying to guess what they really want. The
# general pattern they can give us is:
#     something:routine
# where something may be a command name or a path name, or may be missing
# entirely up to the ':' separator, and routine is a qualified or unqualified
# routine name, using the single quote as package separator, and not :: as in
# perl5 or C++ -- I loathe that token, maybe because I loathe C++ so much?
# Returns success condition, or undef if file cannot be loaded (missing?).
sub do {
	local($routine) = @_;
	$routine =~ s/::/'/;	# Despite what leading comment says, be perl5 aware
	local($something);
	$routine =~ s/^([^:]*):// && ($something = $1);
	$routine = "main'$routine" unless $routine =~ /'/;
	return 1 if $something eq '' && defined &$routine;	# Already there
	return 0 if $something eq '';		# Not there, no clue how to get it

	# Ok, at that point we know the routine is not there, but by looking
	# at $something, we might be able to find out where that routine might
	# be found... First check whether it is the name of a user-defined command
	# in which case we load that file and get the command. Otherwise, the
	# remaining is taken as a path where the routine may be found.

	local($cmd) = $something;
	local($path);
	$cmd =~ tr/a-z/A-Z/;				# Cannonicalize to upper case
	if (defined $newcmd'Usercmd{$cmd}) {
		$path = $newcmd'Usercmd{$cmd};	# Get command's path
	} else {
		$path = $something;				# Must be a path then
		$path =~ s/~/$cf'home/;			# ~ substitution
	}
	
	local($package);
	($package, $routine) = $routine =~ m|(.*)'(.*)|;

	return &load($package, $path, $routine);
}

package main;

