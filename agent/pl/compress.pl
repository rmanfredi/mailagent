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
;# $Log: compress.pl,v $
;# Revision 3.0.1.1  1995/09/15  14:03:35  ram
;# patch43: can now handle compression with various compressors
;# patch43: (code contributed by Kevin Johnson <kjj@pondscum.phx.mcd.mot.com>)
;#
;# Revision 3.0  1993/11/29  13:48:37  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This module handles compressed folders. Each folder specified in the file
;# 'compress' from the configuration file is candidate for compression checks.
;# The file specifies folders using shell patterns. If the pattern does not
;# start with a /, the match is only attempted to the basename of the folder.
;# 
;# Folder uncompressed are recompressed only before the mailagent is about
;# to exit, so that the burden of successive decompressions is avoided should
;# two or more mails be delivered to the same compressed folder. However, if
;# there is not enough disk space to hold all the uncompressed folder, the
;# mailagent will try to recompress them to try to make some room.
;#
;# The initial patterns are held in the @compress array, while the compression
;# status is stored within %compress. The key is the file name, and the value
;# is 0 if uncompression was attempted but failed somehow so recompression must
;# not be done, or compression tag string if uncompression was successful and
;# the folder is flagged for delayed recompression.
#
# Folder compression
#

package compress;

# Read in the compression file into the @compress array. As usual, shell
# comments are ignored.
sub init {
	unless (open(COMPRESS, "$cf'compress")) {
		&'add_log("WARNING cannot open compress file $cf'compress: $!")
			if $'loglvl > 5;
		return;
	}
	local($_);
	while (<COMPRESS>) {
		chop;
		next if /^\s*#/;			# Skip comments
		next if /^\s*$/;			# And blank lines
		$_ = &'perl_pattern($_);	# Shell pattern to perl one
		s/^~/$cf'home/;				# ~ substitution
		# Focus on basename unless absolute path
		$_ = '(?>.*/)'.$_ unless m|^/|;
		push(@compress, $_);		# Record pattern
	}
	close COMPRESS;

	unless (open(COMPSPEC, "$cf'compspec")) {
		# Configure a set of defaults if the user hasn't specified them manually
		# Fields are: tag extension compression_prog uncompress_prog cat_prog
		# The following legacy line removed as modern systems lack compress:
		# compress	.Z	compress	uncompress	zcat
		&add_compressor(<<'EOT');
gzip		.gz		gzip		gunzip		gunzip -c
bzip2		.bz2	bzip2		bunzip2		bzcat
EOT
		local($err) = "$!";
		&'add_log("WARNING cannot open compspec file $cf'compspec: $err")
			if $'loglvl > 5 && -f $cf'compspec;
		&'add_log("NOTICE using hardwired compressor defaults")
			if $'loglvl > 6;
	} else {
		while (<COMPSPEC>) {
			chop;
			next if /^\s*#/;			# Skip comments
			next if /^\s*$/;			# And blank lines
			s/^\s+//;
			s/\s+$//;
			&add_compressor($_);
		}
		close COMPSPEC;
	}

	unless (defined($Ext{$cf'comptag})) {
		&'add_log("ERROR invalid comptag: $cf'comptag") if $'loglvl;
		return;
	}
}

# Uncompress a folder, and record it in the %compress array for further
# recompression at the end of the mailagent processing. Return 1 for success.
# If the $retry parameter is set, other folders will be recompressed should
# this particular uncompression fail.
sub uncompress {
	local($folder, $retry) = @_;	# Folder to be decompressed
	local($tag);
	&'add_log("entering uncompress") if $'loglvl > 15;
	return if defined $compress{$folder};	# We already dealt with that folder
	# Lock folder, in case someone is trying to deliver to the uncompressed
	# folder while we're decompressing it...
	if (0 != &'acs_rqst($folder)) {
		&'add_log("WARNING unable to lock compressed folder $folder")
			if $'loglvl > 5;
		return 0;				# Failure, don't uncompress, sorry
	}
	# Make sure there is a compressed file, and that the corresponding folder
	# is not already present. If there is no compressed file but the folder
	# already exists, mark it uncompressed.
	if ($tag = &is_compressed($folder)) {		# A compressed form exists
		local($ext) = $Ext{$tag};
		if (-f $folder) {				# As well as an uncompressed form
			&'add_log("WARNING both folders $folder and $folder$ext exist")
				if $'loglvl > 5;
			&'add_log("NOTICE ignoring compressed file") if $'loglvl > 6;
			$compress{$folder} = 0;		# Do not recompress, yet mark as dealt
			&'free_file($folder);		# Unlock folder
			return 1;
		}
		# Normal case: there is a compressed file and no uncompressed version
		local($uncompress) = $Uncompressor{$tag};
		local($status) = system("$uncompress $folder$ext");
		&'add_log("$uncompress returned $status") if $'loglvl > 15;
		if ($status) {			# Uncompression failed
			local($retrying);
			$retrying = " (retrying)" if $retry;
			&'add_log("ERROR can't uncompress $folder via $uncompress$retrying")
				if $'loglvl;
			# Maybe there is not enough disk space, and maybe we can get some
			# by recompressing the folders we have decompressed so far.
			if ($retry) {				# Attempt is to be retried
				&recompress;			# Recompress other folders, if any
				&'free_file($folder);	# Unlock folder
				&'add_log("leaving uncompress after retry") if $'loglvl > 15;
				return 0;				# And report failure
			}
			&'add_log("WARNING $folder present before delivery")
				if -f $folder && $'loglvl > 5;
			&'add_log("ERROR original $folder$ext lost")
				if ! -f "$folder$ext" && $'loglvl;
			$compress{$folder} = 0;		# Do not recompress, yet mark as dealt
		} else {						# Folder should be decompressed
			if (-f "$folder$ext") {
				&'add_log("WARNING compressed $folder still present")
					if $'loglvl > 5;
				$compress{$folder} = 0;	# Do not recompress it
			} else {
				$compress{$folder} = $tag;	# Folder recompressed after delivery
			}
			&'add_log("uncompressed $folder using $uncompress") if $'loglvl > 8;
		}
	} else {
		$compress{$folder} = $cf'comptag;	# Folder compressed after creation
	}
	&'free_file($folder);	# Unlock folder
	&'add_log("leaving uncompress") if ($'loglvl > 15);
	1;						# Success
}

# Compress a folder
sub compress {
	local($folder) = @_;		# Folder to be compressed
	local($tag);
	return unless $compress{$folder};	# Folder not to be recompressed
	$tag = $compress{$folder};			# Which compression scheme was used
	delete $compress{$folder};			# Mark it compressed anyway
	if (&is_compressed($folder)) {		# A compressed form exists
		&'add_log("ERROR compressed $folder already present") if $'loglvl;
		return;
	}
	if (0 != &'acs_rqst($folder)) {		# Cannot compress if not locked
		&'add_log("WARNING $folder locked, skipping compression")
			if $'loglvl > 5;
		return;
	}
	local($compress) = $Compressor{$tag};
	local($ext) = $Ext{$tag};
	local($status) = system("$compress $folder");
	if ($status) {
		&'add_log("ERROR cannot compress $folder using $compress") if $'loglvl;
		if (-f $folder) {
			unless (unlink "$folder$ext") {
				&'add_log("ERROR cannot remove $folder$ext: $!") if $'loglvl;
			} else {
				&'add_log("NOTICE removing $folder$ext") if $'loglvl > 6;
			}
		} else {
			&'add_log("ERROR original $folder lost") if $'loglvl;
		}
	} else {
		&'add_log("WARNING uncompressed $folder still present")
			if -f $folder && $'loglvl > 5;
		&'add_log("compressed $folder using $compress") if $'loglvl > 8;
	}
	&'free_file($folder);
}

# Recompress all folders which have been delivered to
sub recompress {
	foreach $file (keys %compress) {
		&compress($file);
	}
}

# Restore uncompressed folder if listed in the compression list
sub restore {
	return unless $cf'compress;		# Do nothing if no compress parameter
	return unless -s $cf'compress;	# No compress list file, or empty
	&init unless defined @compress;	# Initialize array only once
	return unless defined $Ext{$cf'comptag};	# Invalid compression tag
	local($folder) = @_;			# Folder candidate for uncompression
	&'add_log("candidate folder is $folder") if $'loglvl > 18;

	# Loop over each pattern in the compression file and see if the folder
	# matches one of them. As soon as one matches, the folder is uncompressed
	# if necessary and the processing is over.
	foreach $pattern (@compress) {
		&'add_log("matching against '$pattern'") if $'loglvl > 19;
		if ($folder =~ /^$pattern$/) {
			&'add_log("matched '$pattern'") if $'loglvl > 18;
			# Give it two shots. The second parameter is a retrying flag.
			# The difference between the two is that recompression of other
			# uncompressed folders is attempted the first time if the folder
			# cannot be uncompressed (assuming low disk space).
			&uncompress($folder, 0) unless &uncompress($folder, 1);
			last;
		}
	}
}

# Check to see if a compressed version of a given folder exists.
# Returns the tag identifying the compression type.
sub is_compressed {
	local($folder) = @_; 
	local($suffix);

	foreach $suffix (keys %Suffix) {
		next unless -f "$folder$suffix";
		&'add_log("folder $folder$suffix was compressed by $Suffix{$suffix}")
			if $'loglvl > 15;
		return $Suffix{$suffix};
	}

	return undef;	# Unable to identify any valid compression suffix
}

# Given a compressor definition like:
#
#	GNUzip		.gz	gzip		gunzip		gunzip -c
#
# fill in the internal data structures identifying the 'GNUzip' compressor.
# Those data structures are (private to this package):
#
#   %Ext: given a compress tag, yields the extension to be used
#   %Suffix: given the extension, which compression tag is this?
#   %Compressor: compression program by tag
#   %Uncompressor: uncompression program, by tag
#   %Ccat: cat program (for compressed input) by tag
#
# It is mandatory that no duplicate suffixes be used amongst the various
# compressor definitions. This is enforced by ignoring the faulty line!
sub add_compressor {
	local($string) = @_;
	local($tag, $ext, $compress, $uncompress, $zcat) = split(/\t+/, $string, 5);
	if (defined $Suffix{$ext}) {
		local($ptag) = $Suffix{$ext};
		&'add_log("ERROR compressor suffix $ext for $tag already used by $ptag")
			if $'loglvl;
		return;			# Ignore duplicate suffix definition
	}
	$Ext{$tag} = $ext;
	$Suffix{$ext} = $tag;
	$Compressor{$tag} = $compress;
	$Uncompressor{$tag} = $uncompress;
	$Ccat{$tag} = $zcat;
}

package main;

