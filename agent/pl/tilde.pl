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
;# $Log: tilde.pl,v $
;# Revision 3.0  1993/11/29  13:49:18  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
# Perform ~name expansion ala ksh...
# (banish csh from your vocabulary ;-)
sub tilda_expand {
	local($path) = @_;
	return $path unless $path =~ /^~/;
	$path =~ s:^~([^/]+):(getpwnam($1))[$[+7]:e;			# ~name
	$path =~ s:^~:$ENV{'HOME'} || (getpwuid($<))[$[+7]:e;	# ~
	$path;
}

