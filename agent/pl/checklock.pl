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
;# $Log: checklock.pl,v $
;# Revision 3.0.1.3  1994/10/04  17:47:34  ram
;# patch17: added support for customized lockfile names
;#
;# Revision 3.0.1.2  1994/09/22  14:15:13  ram
;# patch12: localized variables used by stat()
;#
;# Revision 3.0.1.1  1994/07/01  15:00:20  ram
;# patch8: now honours new lockhold config variable for lock breaking
;#
;# Revision 3.0  1993/11/29  13:48:36  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
;# The $lockext variable must be correctly set.
;#
# Make sure lock lasts for a reasonable time
sub checklock {
	local($file, $format) = @_;				# Full path name, locking format
	local($lockfile) = $file . $lockext;	# Add lock extension
	$lockfile = &lock'file($file, $format) if defined $format;
	if (-f $lockfile) {
		# There is a lock file -- look for how long it's been there
		local($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			$atime,$mtime,$ctime,$blksize,$blocks) = stat($lockfile);
		if ((time - $mtime) > $cf'lockhold) {
			# More than outdating time!! Something must have gone wrong
			unlink $lockfile;
			$file =~ s|.*/(.*)|$1|;	# Keep only basename
			&add_log("UNLOCKED $file (lock older than $cf'lockhold seconds)")
				if $loglvl > 5;
		}
	}
}

