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
;# $Log: install.pl,v $
;# Revision 3.0.1.4  1998/07/28  17:03:54  ram
;# patch62: was not processing (prefix) indication from setup.cf
;#
;# Revision 3.0.1.3  1997/02/20  11:44:47  ram
;# patch55: missed a '$' in front of a variable in create()
;#
;# Revision 3.0.1.2  1996/12/24  14:54:05  ram
;# patch45: new prefix() routine
;#
;# Revision 3.0.1.1  1995/02/16  14:33:13  ram
;# patch32: created
;#
;#
;# This part of the 'cf' package is responsible for setting up a proper config
;# for mailagent to run correctly.
;#
;# The main entry point is &cf'setup. Little information is available at that
;# time, and of course, we do not have any logging. Therefore, messages are
;# printed on stdout.
;#
;# We start by looking for the ~/.mailagent file. If it exists, then we'll
;# have to merge it with newer variables that may have been introduced.
;# The configuration is then loaded and all mandatory directories or files
;# are created.
;#
;# The configured path is also checked to ensure we can find at least perl
;# and mailagent. NB: when creating a ~/.mailagent from scratch, we only
;# configure the path variable, not the p_host one.
;#
#
# Configuration setup main entry point
#

package cf;

# Setup a decent mailagent environment, and returns a proper exit status,
# i.e. 0 for success and 1 for failure.
sub setup {
	*main'add_log = *main'stdout_log;	# Setup a decent logging routine

	# To allow for automatic -I testing, we set-up the following two
	# variables specially for the test suite when invoked with the
	# undocumented -TEST option.

	local($cfset'home);					# Computed HOME directory
	local($cfset'privlib);				# Installed mailagent libdir
	if ($'test_mode) {
		$cfset'home = $ENV{'HOME'};					# agent/test/out
		$cfset'privlib = "$cfset'home/../../files";	# agent/files
	} else {
		$cfset'home = &'tilda_expand('~');
		$cfset'privlib = &'tilda_expand($'privlib);
	}

	umask(077);							# Default mode: rw for user only!
	$home = $cfset'home;				# Required by &main'tilda...

	# Setup a default configuration
	unless (&cfset'init) {
		&'add_log("trouble initializing configuration -- help required");
		return 1;
	}

	# Now load new configuration and perform sanity checks
	&'get_configuration;
	unless (defined $main'loglvl) {
		&'add_log("trouble getting new configuration -- check it up");
		return 1;
	}

	&cfset'check;		# Check the configuration
	return 0;			# OK
}

#
# Configuration setup routines
#

package cfset;

# Initialize configuration, returning true on success.
sub init {
	unless (-d $home) {
		&'add_log("cannot locate home directory -- all I have is '$home'");
		return 0;	# failed
	}
	unless (-w $home) {
		&'add_log("you lack write permissions in $home");
		return 0;	# failed
	}

	local($pwdhome) = $'test_mode ? $ENV{'HOME'} : (getpwuid($<))[7];
	if (defined $ENV{'HOME'} && $ENV{'HOME'} ne $pwdhome) {
		&'add_log("your HOME environment variable disagrees with /etc/passwd");
		&'add_log("HOME: $ENV{'HOME'}, /etc/passwd: $pwdhome");
	}

	$ENV{'HOME'} = $home;					# This is set by filter normally

	return 0 unless &read_setup;			# Get setup.cf for defaults
	return &merge if -e "$home/.mailagent";	# Merge if already exists

	# Ok, at this point, we need to create a default ~/.mailagent that
	# will enable the user to run mailagent correctly.

	&'add_log("creating ~/.mailagent...");

	unless (open(TEMPLATE, "$privlib/mailagent.cf")) {
		&'add_log("cannot open $privlib/mailagent.cf: $!");
		return 0;	# failed
	}

	unless (open(CONFIG, ">$home/.mailagent")) {
		&'add_log("cannot create $home/.mailagent: $!");
		return 0;	# failed
	}

	# Build up a default configuratiuon from the mailagent.cf template.
	# If some variables have configured defaults in setup.cf, then use that.
	# Otherwise, copy the line, propagating the "commented out" status.

	local($_);
	local($c, $var, $sp1, $sp2, $val, $comment);
	while (<TEMPLATE>) {
		if (
			($c, $var, $sp1, $sp2, $val, $comment) =
			/^(#?)(\w+)(\s*):(\s*)([^#\n]*)(#.*)?/
		) {
			next if $var =~ /^p_/;				# Skip p_host examples
			if (defined $Var{$var}) {			# Has a computable default
				($val) = $val =~ m/(\s+)$/;		# Keep spaces before comment
				print CONFIG "$c$var$sp1:$sp2", &dflt($var), "$val$comment\n";
			} else {
				print CONFIG;		# No computable default, print verbatim
			}
		} else {
			print CONFIG;
		}
	}
	close CONFIG;
	close TEMPLATE;
}

# Merge existing configuration with possible new variables, returning
# true on success. Called from &init, after setup.cf loading when an
# existing ~/.mailagent is detected.
sub merge {
	local($old) = '.mailagent';
	local($new) = "$old.new";
	local($bak) = "$old.bak";

	&'add_log("merging ~/.mailagent...");

	unless (open(OLD, "$home/$old")) {
		&'add_log("cannot open $home/$old: $!");
		return 0;	# failed
	}

	# Fist pass on old file to get at the currently defined variables

	local(%seen);		# Records variables in current configuration
	local($_);
	while (<OLD>) {
		$seen{$1}++ if /^#?(\w+)\s*:/;
	}
	seek(OLD, 0, 0);	# Rewind

	unless (open(TEMPLATE, "$privlib/mailagent.cf")) {
		&'add_log("cannot open $privlib/mailagent.cf: $!");
		return 0;	# failed
	}

	# Now grab all the "known" variables in the mailagent.cf template.
	# Those tell us about the possible new variables that may have been
	# introduced since  the time ~/.mailagent was first created.

	local(%known);
	while (<TEMPLATE>) {
		$known{$1}++ if /^#?(\w+)\s*:/;
	}
	seek(TEMPLATE, 0, 0);	# Rewind

	unless (open(NEW, ">$home/$new")) {
		&'add_log("cannot create $home/$new: $!");
		return 0;	# failed
	}

	# Start duplicating existing configuration
	while (<OLD>) {
		print NEW;			# Print line verbatim
	}
	close OLD;

	local(%missing);
	local($missing) = 0;

	# Look for possible new variables added since last configuration
	foreach $var (keys %known) {
		next if $var =~ /^p_/;				# Skip p_host examples
		$missing{$var}++ unless defined $seen{$var};
		$missing++ unless defined $seen{$var};
	}

	if ($missing) {
		local($s) = $missing == 1 ? '' : 's';
		&'add_log("adding $missing extra variable$s to ~/.mailagent...");
		print NEW <<EOM;

#
# Extra variables added to configuration -- version $'mversion PL$'patchlevel
#

EOM
	} else {
		close NEW;
		close TEMPLATE;
		&'add_log("existing configuration was up-to-date");
		unlink("$home/$new") || &'add_log("WARNING can't unlink $new: $!");
		return 1;	# OK
	}

	# Add all new variables. If they have configured defaults in setup.cf,
	# then use that. Otherwise, copy the line verbatim from the mailagent.cf
	# template. We propagate the "commented out" status as necessary.

	local($c, $var, $sp1, $sp2, $val, $comment);
	while (<TEMPLATE>) {
		if (
			($c, $var, $sp1, $sp2, $val, $comment) =
			/^(#?)(\w+)(\s*):(\s*)([^#\n]*)(#.*)?/
		) {
			next unless defined $missing{$var};
			if (defined $Var{$var}) {			# Has a computable default
				($val) = $val =~ m/(\s+)$/;		# Keep spaces before comment
				print NEW "$c$var$sp1:$sp2", &dflt($var), "$val$comment\n";
			} else {
				print NEW;		# No computable default, print verbatim
			}
		}
	}
	close NEW;
	close TEMPLATE;

	local($status) = 1;

	unless (rename("$home/$old", "$home/$bak")) {
		&'add_log("ERROR unable to rename $old into $bak: $!");
	} else {
		&'add_log("renamed $old into $bak");
	}

	unless (rename("$home/$new", "$home/$old")) {
		&'add_log("ERROR unable to intall new $old: $!");
		$status = 0;
	} else {
		&'add_log("new $old installed");
	}

	return $status;	# OK, unless ~/.mailagent not installed
}

# Check the current loaded configuration.
# We ensure all the required files/directories are there, and that the path
# setting on this machine is good enough to locate perl and mailagent.
sub check {
	&'add_log("checking your configuration...");

	# Check file/directory existence and consistency...
	local($path);		# Computed value for given configuration parameter
	local($type);		# File/directory type
	foreach $var (keys %File) {
		eval '$path = $cf' . "'$var";
		&'add_log("ERROR in &cfset'check: $@") if chop($@);
		next if $@ ne '';
		$type = $File{$var};
		next unless $type;
		next if $path eq '' && $type =~ /^[fd]/;	# Missing, but optional
		$path = &'tilda_expand($path);
		if ($type =~ /^[fd]/) {
			&exists($path, $type, $var);	# Check existing file/dir
		} elsif ($path eq '') {
			&'add_log("ERROR mandatory parameter '$var' not defined");
		} else {
			&create($path, $type, $var);	# Create missing file/dir
		}
	}

	# Check home directory consistency...
	local($pwdhome) = $'test_mode ? $ENV{'HOME'} : (getpwuid($<))[7];
	unless ($pwdhome eq $cf'home) {
		&'add_log("WARNING home config parameter disagrees with /etc/passwd");
		&'add_log("home: $cf'home, /etc/passwd: $pwdhome");
	}

	# Make sure path setting is correct...
	&path_check;
	&path_check('mailagent');
	&path_check('perl');
}

# Get the setup.cf file, and create two data structures:
#   %Var:  indexed by variable name, yielding a perl expression to compute
#          the default value of that variable.
#   %File: indexed by variable name, yields whether it refers to a file
#          or a directory. Used to check-up the configuration.
# Return true on success.
sub read_setup {
	unless (open(SETUP, "$privlib/setup.cf")) {
		&'add_log("cannot open $privlib/setup.cf: $!");
		return 0;	# failed
	}
	local($_);
	while (<SETUP>) {
		next if /^#/;			# Skip comments
		next if /^\s*$/;		# Skip blank lines
		if (/^(\w+)\s*:\s*(.*)/) {			# var: perl-expr
			$Var{$1} = $2;					# specifies a computation for var
		} elsif (/^(\w+)\s*=\s*(.*)/) {		# var= F file
			$File{$1} = $2;					# tells what $var points to
		} else {
			&'add_log("WARNING setup.cf file corrupted at line $.");
		}
	}
	close SETUP;
	return 1;		# OK
}

# Compute a default specified by the setup.cf file.
sub dflt {
	local($var) = @_;
	local($perl) = $Var{$var};
	local($dflt);
	eval '$dflt = ' . $perl;
	&'add_log("ERROR while computing default for $var: $@") if chop($@);
	return $dflt;
}

# Check that a given file/directory is of the correct kind.
# Returns true if file/directory exists.
sub exists {
	local($path, $type, $var) = @_;
	local($what) = $type =~ /^[Dd]/ ? 'directory' : 'file';
	local($prefix) = &prefix($path, $type);
	local($short) = &'tilda("$prefix/$path");
	unless (-e "$prefix/$path") {
		&'add_log("no $prefix/$path for $what '$var' yet") if $cf'level > 14;
		return 0;
	}
	&'add_log("checking $what '$var' at $prefix/$path") if $cf'level > 11;
	if ($type =~ /^[Dd]/) {
		&'add_log("ERROR $short is not a directory (variable $var)")
			unless -d "$prefix/$path";
	} else {
		&'add_log("ERROR $short is not a file (variable $var)")
			if -d "$prefix/$path";
	}
	return 1;		# Exists, but may be of the wrong type
}

# Create file/directory, using type sepcification from the setup.cf file.
sub create {
	local($path, $type, $var) = @_;
	return if &exists($path, $type, $var);
	local($what) = $type =~ /^D/ ? 'directory' : 'file';
	local($file) = $type =~ /^\w\s*(.*)/;
	$file =~ s/\s*\(.*\)\s*//;		# Remove ($spool)-like location hints
	local($from) = $file ? "from default $file" : '(empty)';
	local($prefix) = &prefix($path, $type);
	local($target) = "$prefix/$path";
	$target =~ tr|/||s;				# If $path starts with /, $prefix is ''
	local($short) = &'tilda($target);
	&'add_log("creating mandatory $what $short $from for variable $var");
	if ($type =~ /^D/) {
		&'makedir($target);
	} else {
		local($dir, $base) = $target =~ m|(.*)/(.*)|;
		&'makedir($dir);
		unless (open(BASE, ">$dir/$base")) {
			&'add_log("ERROR cannot create $dir/$base: $!") if $cf'level;
			return;
		}
		if ($file && !open(FILE, "$privlib/$file")) {
			&'add_log("ERROR cannot open $privlib/$file: $!") if $cf'level;
		} else {
			local($_);
			while (<FILE>) {
				print BASE;
			}
			close FILE;
		}
		close BASE;
	}
}

# Compute suitable prefix to put in front of variable value before checking
# for file existence or performing creation. In the absence of specified
# prefix, the file is anchored under the home directory if it does not
# begin with a /.
#
# If a file is spefied as:
#        mailbox = f ($maildrop)
# in the setup.cf file, then it means the optional file is implicitely located
# under another configuration variable or specified path. Use that if necessary.
# Note that if a variable is specified, it is assumed to be a configuration
# variable and is therefore evaluated in the cf package. It is possible to
# fully qualify that name if necessary...
#
# Returns the suitable prefix (with ~ substitution).
sub prefix {
	local($path, $type) = @_;	# Path, file type such as "f ($var)"
	local($prefix) = $type =~ /\((.*)\)/;	# Grab ($var) or (/usr/bin) prefix
	eval "package cf; \$cfset'prefix = \"$cfset'prefix\";" if $prefix;
	$prefix = '~' unless $prefix || $path =~ m|^/|;
	return $prefix ? &'tilda_expand($prefix) : '';
}

# Check path setting.
# Without any argument, simply checks that each path directory is correct.
# Otherwise, try to locate the argument within the path.
sub path_check {
	local($prog) = @_;
	local($host) = &'hostname;
	$host =~ s/^(\w+).*/$1/;		# Trim domain name
	local($lpath);					# Value of local path (p_host)
	eval '$lpath = $cf' . "'p_$host";
	&'add_log("ERROR in cfset'path_check: $@") if chop($@);

	local($direxp);		# Expanded version of the directory
	local($found) = 0;
	foreach $dir (split(/:/, "$lpath:$cf'path")) {
		next if $dir eq '';
		$direxp = &'tilda_expand($dir);
		unless (defined $prog || -d $direxp) {
			&'add_log("WARNING path component '$dir' not found!");
		}
		if (defined $prog && -e "$direxp/$prog" && -x _ && !-d _) {
			$found++;
			last;
		}
	}
	&'add_log("WARNING cannot locate '$prog' in set-up path")
		if defined($prog) && !$found;
}

# Compute a suitable default path and return it. We try to include directories
# under the user home directory, and directories containing some programs
# like 'ls', 'pg', 'perl' and 'mailagent'.
# NB: This routine is not called directly but via setup.cf and &dflt.
sub default_path {
	local($path) = '';		# The build-up path
	local($short);			# Path with tilda substitution
	foreach $dir (split(/:/, $ENV{'PATH'})) {
		next if $dir eq '' || $dir =~ /^\.\.?$/;
		$short = &'tilda($dir);
		if ($short ne $dir) {
			$path .= "$short:";
			next;
		}
		$path .= "$dir:" if &contains($dir, 'ls', 'pg', 'perl', 'mailagent');
	}
	chop($path);			# Remove trailing ':'
	return $path;
}

# Returns true if the specified dir exists, has the x bit set and contains
# one of the specified programs.
sub contains {
	local($dir, @progs) = @_;
	return 0 if !-d $dir || !-x _;
	foreach $prog (@progs) {
		return 1 if -e "$dir/$prog" && -x _;
	}
	return 0;	# Not found
}

package main;

