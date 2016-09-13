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
;# $Log: secure.pl,v $
;# Revision 3.0.1.7  1998/07/28  17:07:05  ram
;# patch62: now explicitely log when too many symlink levels are found
;#
;# Revision 3.0.1.6  1997/02/20  11:46:00  ram
;# patch55: now honours groupsafe and execsafe configuration variables
;#
;# Revision 3.0.1.5  1997/01/07  18:35:52  ram
;# patch52: now only perform extended exec() checks iff execsafe is ON
;#
;# Revision 3.0.1.4  1996/12/24  15:00:39  ram
;# patch45: extended security checks and created exec_secure()
;#
;# Revision 3.0.1.3  1995/03/21  12:57:42  ram
;# patch35: symbolic directories are now correctly followed
;#
;# Revision 3.0.1.2  1994/10/04  17:55:19  ram
;# patch17: wrong stat command could cause errors when checking symlinks
;#
;# Revision 3.0.1.1  1994/09/22  14:38:04  ram
;# patch12: symbolic directories are now specially handled
;#
;# Revision 3.0  1993/11/29  13:49:16  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# Requires pl/cdir.pl to derive paths when following symbolic links.
;# 
# A file "secure" if it is owned by the user and not world writable. Some key
# file within the mailagent have to be kept secure or they might compromise the
# security of the user account.
#
# Additionally, for 'root' users or if the 'secure' parameter in the config
# file is set to ON, checks are made for group writable files and suspicious
# directory as well.
#
# Return true if the file is secure or missing, false otherwise.
# Note the extra parameter $exec which is set by exec_secure() only.
sub file_secure {
	my ($file, $type, $exec) = @_;
	return 1 unless -e $file;	# Missing file considered secure

	# We're resolving symlinks recursively
	# NB: Race condition between our checks and the perusal of the file!
	#	--RAM, 2016-09-13

	if (-l $file) {				# File is a symbolic link
		my $target = &symfile_secure($file, $type);
		unless (defined $target) {
			# Symbolic link is not secure
			unless ($exec) {
				&add_log(
					"WARNING sensitive $type file $file is an " .
					"unsecure symbolic link"
				) if $loglvl > 5;
			}
			return 0;	# Unsecure file
		}
		$file = $target;
		if ($exec) {
			&add_log("NOTICE running $type $file actually runs $target")
				if $loglvl > 6;
		}
	}

	local($ST_MODE) = 2 + $[;	# Field st_mode from inode structure
	unless ($exec || -O _) {	# Reuse stat info from -e
		&add_log("WARNING you do not own $type file $file") if $loglvl > 5;
		return 0;		# Unsecure file
	}
	local($st_mode) = (stat(_))[$ST_MODE];
	if ($st_mode & $S_IWOTH) {
		&add_log("WARNING $type file $file is world writable!") if $loglvl > 5;
		return 0;		# Unsecure file
	}

	# If file is excutable and seg[ug]id, make sure it's not publicly writable.
	# If writable at all, only the owner should have the rights. That's for
	# systems which do no reset the set[ug]id bit on write to the file.
	if (-x _) {
		if (($st_mode & $S_ISUID) && ($st_mode & ($S_IWGRP|$S_IWOTH))) {
			&add_log("WARNING setuid $type file $file is writable!")
				if $loglvl > 5;
			return 0;
		}
		if (($st_mode & $S_ISGID) && ($st_mode & ($S_IWGRP|$S_IWOTH))) {
			&add_log("WARNING setgid $type file $file is writable!")
				if $loglvl > 5;
			return 0;
		}
	}

	return 1 unless $cf'secure =~ /on/i || $< == 0;

	# Extra checks for secure mode (or if root user). We make sure the
	# file is not writable by group and then we conduct the same secure tests
	# on the directory itself
	if (($st_mode & $S_IWGRP) && $cf'groupsafe !~ /^off/i) {
		&add_log("WARNING $type file $file is group writable!") if $loglvl > 5;
		return 0;		# Unsecure file
	}
	local($dir);		# directory where file is located
	$dir = '.' unless ($dir) = ($file =~ m|(.*)/.*|);
	unless ($exec || -O $dir) {
		&add_log("WARNING you do not own directory of $type file $file")
			if $loglvl > 5;
		return 0;		# Unsecure directory, therefore unsecure file
	}
	$st_mode = (stat(_))[$ST_MODE];
	return 0 unless &check_st_mode($dir, 1);

	# If linkdirs is OFF, we do not check further when faced with a symbolic
	# link to a directory.
	if (-l $dir && $cf'linkdirs !~ /^off/i && !&symdir_secure($dir, $type)) {
		&add_log("WARNING directory of $type file $file is an unsecure symlink")
			if $loglvl > 5;
		return 0;		# Unsecure directory
	}

	1;		# At last! File is secure...
}

# Is a symbolic link to a directory secure?
sub symdir_secure {
	local($dir, $type) = @_;
	if (&symdir_check($dir, 0)) {
		&add_log("symbolic directory $dir for $type file is secure")
			if $loglvl > 11;
		return 1;
	}
	0;	# Not secure
}

# Is a symbolic link to a file secure?
# Returns the final target if all links up to that file are secure, undef
# if one of the links is not secure enough.
sub symfile_secure {
	local($file, $type) = @_;
	local($target) = &symfile_check($file, 0);
	if (defined $target) {
		&add_log("symbolic file $file for $type file is secure")
			if $loglvl > 11;
	} else {
		&add_log("WARNING symbolic file $file for $type file is unsecure")
			if $loglvl > 5;
	}
	return $target;
}

# A symbolic directory (that is a symlink pointing to a directory) is secure
# if and only if:
#   - its target is a symlink that recursively proves to be secure.
#   - the target lies in a non world-writable directory
#   - the final directory at the end of the symlink chain is not world-writable
#   - less than $MAX_LINKS levels of indirection are needed to reach a real dir
# Unfortunately, we cannot check for group writability here for the parent
# target directory since the target might lie in a system directory which may
# have a legitimate need to be read/write for root and wheel, for instance.
# The routine returns 1 if the file is secure, 0 otherwise.
sub symdir_check {
	local($dir, $level) = @_;	# Directory, indirection level
	$MAX_LINKS = 100 unless defined $MAX_LINKS;	# May have been overridden
	if ($level++ > $MAX_LINKS) {
		&add_log("ERROR more than $MAX_LINKS levels of symlinks to reach $dir")
			if $loglvl;
		return 0
	}
	local($ndir) = readlink($dir);
	unless (defined $ndir) {
		&add_log("SYSERR readlink: $!") if $loglvl;
		return 0;
	}
	$dir =~ s|(.*)/.*|$1|;		# Suppress link component (tail)
	$dir = &cdir($ndir, $dir);	# Follow symlink to get its final path target
	local($still_link) = -l $dir;
	unless (-d $dir || $still_link) {
		&add_log("ERROR inconsistency: $dir is a plain file?") if $loglvl;
		return 0;		# Reached a plain file while following links to a dir!
	}
	unless (-d "$dir/..") {
		&add_log("ERROR inconsistency: $dir/.. is not a directory?") if $loglvl;
		return 0;		# Reached a file hooked nowhere in the file system!
	}
	# Check parent directory
	local($ST_MODE) = 2 + $[;	# Field st_mode from inode structure
	$st_mode = (stat(_))[$ST_MODE];
	return 0 unless &check_st_mode("$dir/..", 0);
	# Recurse if still a symbolic link
	if ($still_link) {
		return 0 unless &symdir_check($dir, $level);
	} else {
		$st_mode = (stat($dir))[$ST_MODE];
		return 0 unless &check_st_mode($dir, 1);
	}
	1;	# Ok, link is secure
}

# Same as symdir_check, but target is a file!
sub symfile_check {
	local($file, $level) = @_;	# File, indirection level
	return undef if $level++ > $MAX_LINKS;
	local($nfile) = readlink($file);
	unless (defined $nfile) {
		&add_log("SYSERR readlink: $!") if $loglvl;
		return undef;
	}
	local($dir) = $file;			# Where symlink was held
	$dir =~ s|(.*)/.*|$1|;			# Suppress link component (tail)
	$file = &cdir($nfile, $dir);	# Follow symlink to get its path
	local($still_link) = -l $file;
	unless (-f $file || $still_link) {
		&add_log("ERROR $file does not exist") if !-e _ && $loglvl;
		&add_log("ERROR $file is not a plain file") if -e _ && $loglvl;
		return undef;				# Reached something that is not a plain file
	}
	# Check parent directory
	($dir = $file) =~ s|(.*)/.*|$1|;
	local($ST_MODE) = 2 + $[;		# Field st_mode from inode structure
	$st_mode = (stat($dir))[$ST_MODE];
	return undef unless &check_st_mode($dir, 1);
	return $file unless $still_link;		# Ok, link is secure
	return &symfile_check($file, $level);	# Still a symbolic link
}

# Returns true if mode in $st_mode does not include world or group writable
# bits, false otherwise. This helps factorizing code used in both &file_secure
# and &symdir_check. Set $both to true if both world/group checks are desirable,
# false to get only world checks.
sub check_st_mode {
	local($dir, $both) = @_;
	if ($st_mode & $S_IWOTH) {
		&add_log("WARNING directory $dir of $type file is world writable!")
			if $loglvl > 5;
		return 0;		# Unsecure directory
	}
	return 1 unless $both;
	if (($st_mode & $S_IWGRP) && $cf'groupsafe !~ /^off/i) {
		&add_log("WARNING directory $dir of $type file is group writable!")
			if $loglvl > 5;
		return 0;		# Unsecure directory
	}
	1;
}

# Make sure the file we are about to execute is secure. If it is a script
# with the '#!' kernel hook, also check the interpreter! Returns true if the
# file can be executed "safely".
sub exec_secure {
	local($file) = @_;	# File to be executed

	unless (-x $file) {
		&add_log("ERROR lacking execute rights on $file") if $loglvl > 1;
		return 0;
	}

	return 1 if $cf'execskip =~ /^on/i;	# Assume safe to be exec'ed

	local($cf'secure) = $cf'execsafe;	# Use exec settings for file_secure()

	unless (&file_secure($file, 'program', 1)) {
		&add_log("ERROR cannot execute unsecure $file") if $loglvl > 1;
		return 0;
	}

	&add_log("can allow exec() of $file") if $loglvl > 17;

	return 1 unless -T $file;	# Safe as far as we can tell, unless script...

	local($head);				# Heading line
	local($interpretor);		# Interpretor running the script
	local($perl) = '';			# Empiric support for perl scripts
	local(*SCRIPT);

	unless (open(SCRIPT, $file)) {
		&add_log("SYSERR open: $!") if $loglvl > 1;
		&add_log("ERROR cannot check script $file") if $loglvl > 1;
		return 0;
	}

	$head = <SCRIPT>;

	# Allow empiric support for common perl scripts
	# This is not bullet-proof, but should guard against common errors.

	if ($head =~ /\bperl\b/) {
		$perl = <SCRIPT>;
		if ($perl =~ /\beval\b.*\bexec\s+(\S+)/) {
			$perl = $1;
		} else {
			$perl = '';			# False alarm, can't check further
		}
	}

	close SCRIPT;

	($interpretor) = $head =~ /^#!\s*(\S+)/;
	$interpretor = '/bin/sh' unless $interpretor;
	unless (-x $interpretor) {
		&add_log("ERROR lacking execute rights on $interpretor") if $loglvl > 1;
		return 0;
	}

	unless (&file_secure($interpretor, 'interpretor', 1)) {
		&add_log("ERROR cannot run unsecure interpretor $interpretor")
			if $loglvl > 1;
		&add_log("ERROR cannot allow execution of script $file") if $loglvl > 1;
		return 0;
	}

	&add_log("can allow $interpretor to run $file") if $loglvl > 17;

	return 1 unless $perl;		# Okay, can run the script

	$perl = &locate_program($perl) unless $perl =~ m|/|;
	unless (-x $perl) {
		&add_log("ERROR lacking execute rights on $perl") if $loglvl > 1;
		return 0;
	}

	unless (&file_secure($perl, 'perl', 1)) {
		&add_log("ERROR cannot run unsecure perl $perl")
			if $loglvl > 1;
		&add_log("ERROR cannot allow execution of perl script $file")
			if $loglvl > 1;
		return 0;
	}

	&add_log("can allow $perl to run $file") if $loglvl > 17;

	return 1;					# Okay, perl can run it
}

