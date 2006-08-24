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
;# $Log: package.pl,v $
;# Revision 3.0.1.1  1994/09/22  14:29:07  ram
;# patch12: created
;#
;#
# Get at the .package file, created by the dist program packinit.
# Returns true if package file was read and sourced correctly within
# the pkg package, false otherwise (in which case we are likely not to
# be within a package source tree).
sub read_package {
	local($pack) = '.package';
	unless (-f $pack) {
		local(@path) = ( '..', '../..', '../../..', '../../../..');
		foreach $dir (@path) {
			if (-f "$dir/$pack") {
				$pack = "$dir/$pack";
				last;
			}
		}
	}
	return 0 unless -f $pack;
	open(PACKAGE, $pack) || return 0;
	while (<PACKAGE>) {
		next if /^:/;
		next if /^#/;
		if (($var,$val) = /^\s*(\w+)=(.*)/) {
			$val = "\"$val\"" unless $val =~ /^['"]/;
			eval "\$pkg'$var = $val;";
		}
	}
	close PACKAGE;
	return 1;
}

