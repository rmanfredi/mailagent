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
;# $Log: gensym.pl,v $
;# Revision 3.0  1993/11/29  13:48:48  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Create a new symbol name each time it is invoked. That name is suitable for
# usage as a perl variable name.
sub gensym {
	$Gensym = 'AAAAA' unless $Gensym;
	$Gensym++;
}

