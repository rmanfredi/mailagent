# Common actions at the top of each misc test

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
;# $Log: misc.pl,v $
;# Revision 3.0.1.1  1994/07/01  15:11:55  ram
;# patch8: fixed RCS leading comment string
;#
;# Revision 3.0  1993/11/29  13:50:26  ram
;# Baseline for mailagent 3.0 netwide release.
;#

do '../pl/cmd.pl';

# Add option to command string held in $cmd
sub add_option {
	local($opt) = @_;
	local(@cmd) = split(' ', $cmd);
	$cmd = join(' ', $cmd[0], $opt, @cmd[1..$#cmd]);
}

