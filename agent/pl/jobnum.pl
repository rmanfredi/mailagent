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
;# $Log: jobnum.pl,v $
;# Revision 3.0  1993/11/29  13:48:54  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Depends on the following external routines:
;#  checklock() to check for locks older than one hour (via acs_rqst)
;#  acs_rqst() to get a lock on file
;#  free_file() to release lock on file
;#
# Computes a new job number
sub jobnum {
	local($job);						# Computed job number
	if (0 != &acs_rqst($cf'seqfile)) {
		$job = "?";
	} else {
		local($njob);
		open(FILE, "$cf'seqfile");
		$njob = int(<FILE>);
		close FILE;
		$njob++;
		open(FILE, ">$cf'seqfile");
		print FILE "$njob\n";
		close FILE;
		$job = "$njob";
		&free_file("$cf'seqfile");
	}
	$job;		# Return job number to be used
}

