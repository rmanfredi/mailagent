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
;# $Log: q.pl,v $
;# Revision 3.0  1993/11/29  13:49:10  ram
;# Baseline for mailagent 3.0 netwide release.
;#
# Quotation removal routine
sub q {
	local($_) = @_;
	local($*) = 1;
	s/^://g;
	$_;
}

