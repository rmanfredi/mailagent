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
;# $Log: signals.pl,v $
;# Revision 3.0.1.2  1995/01/25  15:29:24  ram
;# patch27: put signal handler names into double quotes for perl 5.0
;#
;# Revision 3.0.1.1  1994/09/22  14:39:13  ram
;# patch12: created
;#
;#
# Catch all common signals
sub catch_signals {
	unless (defined &emergency) {
		&add_log("WARNING no emergency routine to trap signals") if $loglvl > 4;
		return;
	}
	$SIG{'HUP'} = "emergency";
	$SIG{'INT'} = "emergency";
	$SIG{'QUIT'} = "emergency";
	$SIG{'PIPE'} = "emergency";
	$SIG{'IO'} = "emergency";
	$SIG{'BUS'} = "emergency";
	$SIG{'ILL'} = "emergency";
	$SIG{'SEGV'} = "emergency";
	$SIG{'ALRM'} = "emergency";
	$SIG{'TERM'} = "emergency";
}

