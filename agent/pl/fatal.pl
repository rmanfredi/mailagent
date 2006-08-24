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
;# $Log: fatal.pl,v $
;# Revision 3.0  1993/11/29  13:48:45  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
# In case of fatal error, the program does not simply die
# but also records the failure in the log.
sub fatal {
	local($reason) = @_;			# Why did we get here ?
	&add_log("FAILED ($reason)") if $loglvl > 0;
	die "$prog_name: $reason\n";
}

# Emergency signal was caught
sub emergency {
	local($sig) = @_;			# First argument is signal name
	&fatal("trapped SIG$sig");
}

