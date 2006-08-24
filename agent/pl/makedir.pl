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
;# $Log: makedir.pl,v $
;# Revision 3.0.1.2  1994/09/22  14:26:47  ram
;# patch12: fixed regexp for perl5 support
;#
;# Revision 3.0.1.1  1994/07/01  15:02:07  ram
;# patch8: default mode is now 0777, relies on umask for proper setting
;#
;# Revision 3.0  1993/11/29  13:48:59  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Make directories for files
# E.g, for /usr/lib/perl/foo, it will check for all the directories /usr,
# /usr/lib, /usr/lib/perl and make them if they do not exist.
# Note: default mode is now 0777 since we have an umask config parameter.
sub makedir {
	local($dir, $mode) = @_;	# directory name, mode (optional)
	local($parent);
	$mode = 0777 unless defined $mode;
	$dir =~ s|/$||;				# no trailing / or we'll try to make dir twice
	if (!-d $dir && $dir ne '') {
		# Make parent dir first
		&makedir($parent, $mode) if ($parent = $dir) =~ s|(.*)/.*|$1|;
		if (mkdir($dir, $mode)) {
			&add_log("creating directory $dir") if $loglvl > 19;
		} else {
			&add_log("ERROR cannot create directory $dir: $!")
				if $loglvl > 1;
		}
	}
}

