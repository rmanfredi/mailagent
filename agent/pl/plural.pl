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
;# $Log: plural.pl,v $
;# Revision 3.0  1993/11/29  13:49:07  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Pluralize names -- Adapted from a routine posted by Tom Christiansen in
# comp.lang.perl on June 20th, 1992.
sub plural {
	local($_, $n) = @_;		# Word and amount (plural if not specified)
	$n = 2 if $n eq '';		# Pluralize word by default
	if ($n != 1) {			# 0 something is plural
		if ($_ eq 'was') {
			$_ = 'were';
		} else {
			s/y$/ies/   || s/s$/ses/  || s/([cs]h)$/$1es/ ||
			s/sis$/ses/ || s/ium$/ia/ || s/$/s/;
		}
	}
	"$_";			# How to write $n times the original $_
}

