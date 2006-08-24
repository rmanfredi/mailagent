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
;# $Log: extern.pl,v $
;# Revision 3.0  1993/11/29  13:48:43  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# External variables are stored in the dbr database. They provide persistent
;# values accross different invocations of the mailagent.
;#
#
# Persitent variables handling
#

package extern;

# Fetch value of a persistent variable
sub val {
	local($name) = @_;
	local($time, $linenum, @value) = &dbr'info($name, 'VARIABLE');
	join("\t", @value);		# TAB is the record separator in dbr
}

# Update value of a persistent variable
sub set {
	local($name, $value) = @_;
	&dbr'update($name, 'VARIABLE', undef, $value);
}

# Fetch age of the variable (elapsed time since last modification)
sub age {
	local($name) = @_;
	local($time, $linenum) = &dbr'info($name, 'VARIABLE');
	time - $time;
}

package main;

