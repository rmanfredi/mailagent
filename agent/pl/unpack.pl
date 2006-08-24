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
;# $Log: unpack.pl,v $
;# Revision 3.0.1.1  1996/12/24  15:01:04  ram
;# patch45: allow '-' in package names
;#
;# Revision 3.0  1993/11/29  13:49:18  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
# Expands an archive's name
sub expand {
	local($path) = shift;		# The archive
	# Look for extension of base path (eg: .cpio.Z)
	local(@fullpath) = <${path}.*>;
	if (-1 == $#fullpath) {
		&clean_tmp;
		&fatal("no archive file");
	}
	$path = $fullpath[0];		# Name with archive extension
}

# Unpack(path,dir,flag) restores archive `path' into `dir'
# and returns the location of the main directory.
sub unpack {
	local($path) = shift;		# The archive
	local($dir) = shift;		# Storage place
	local($compflag) = shift;	# Flag for compression (useful for short names)
	local($unpack) = "";		# Will hold the restore command
	$path = &expand($path);		# Name with archive extension
	&add_log("archive is $path") if $loglvl > 19;
	# First determine wether it is compressed
	if ($compflag) {
		$unpack = "zcat | ";
	}
	# Cpio or tar ?
	if ($path =~ /\.tar/) {
		$unpack .= "tar xof -";
	} else {
		$unpack .= "cpio -icmd";
	}
	system "< $path (cd $dir; $unpack)";
	$path =~ s|.*/([\w-]+)|$1|;	# Keep only basename
	local ($stat) = $?;			# Return status
	if ($stat) {
		&clean_tmp;
		&fatal("unable to unpack $path");
	}
	&add_log("unpacked $path with \"$unpack\"") if $loglvl > 12;

	# The top level directory is the only file in $dir
	local(@top) = <${dir}/*>;
	if ($#top < 0) {
		&clean_tmp;
		&fatal("$prog_name: no top-level dir for $path");
	}
	if ($#top > 0) {
		&add_log("WARNING more than one file in $dir") if $loglvl > 4;
	}
	&add_log("top-level dir for $path is $top[0]") if $loglvl > 19;
	$top[0];		# Top-level directory
}

