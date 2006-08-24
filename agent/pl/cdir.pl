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
;# $Log: cdir.pl,v $
;# Revision 3.0.1.1  1995/03/21  12:56:26  ram
;# patch35: created
;#
;#
;# Usage:
;#	$newdir = &cdir($relpath);			# Use `pwd` for current directory
;#	$newdir = &cdir($relpath, $dir);	# Specify path for derivation
;#
# Apply directory changes into current path and return new directory
sub cdir {
	local($dir, $cur) = @_;			# New relative path, current directory
	return $dir if $dir =~ m|^/|;	# Already an absolute path
	chop($cur = `pwd`) unless defined $cur;
	local(@cur) = split(/\//, $cur);
	local(@dir) = split(/\//, $dir);
	local($path);
	foreach $item (@dir) {
		next if $item eq '.';	# Stay in same dir
		if ($item eq '..') {	# Move up
			pop(@cur);
		} else {
			push(@cur, $item);	# Move down
		}
	}
	local($path) = '/' . join('/', @cur);
	$path =~ tr|/||s;			# Successive '/' are useless
	$path;
}

