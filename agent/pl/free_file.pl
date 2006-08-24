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
;# $Log: free_file.pl,v $
;# Revision 3.0.1.1  1994/10/04  17:52:52  ram
;# patch17: added support for customized lockfile names
;#
;# Revision 3.0  1993/11/29  13:48:47  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
# Remove the lock on a file. Returns 0 if ok, -1 otherwise
# Locking format is optional but when given must match the one used by
# the &acs_rqst() locking routine.
sub free_file {
	local($file, $format) = @_;		# locked file, locking format
	local($stamp);					# string written in lock file

	if ($cf'nfslock =~ /on/i) {			# NFS-secure lock wanted
		$stamp = "$$" . &hostname;		# use PID and hostname
	} else {
		$stamp = "$$";					# use PID only (may spare a fork)
	}

	local($lockfile) = $file . $lockext;
	$lockfile = &lock'file($file, $format) if defined $format;

	if ( -f $lockfile) {
		# if lock exists, check for pid
		open(FILE, $lockfile);
		chop($_ = <FILE>);
		close FILE;
		if ($_ eq $stamp) {
			# pid (plus hostname eventually) is correct
			$result = 0;
			unlink $lockfile;
		} else {
			# pid is not correct (we did not get that lock)
			$result = -1;
		}
	} else {
		# no lock file
		$result = 0;
	}
	$result;	# return status
}

