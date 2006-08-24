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
;# $Log: locate.pl,v $
;# Revision 3.0.1.2  1999/07/12  13:52:12  ram
;# patch66: added ~ substitution in locate_program()
;#
;# Revision 3.0.1.1  1996/12/24  14:54:19  ram
;# patch45: new locate_program() routine
;#
;# Revision 3.0  1993/11/29  13:48:56  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# If the file name does not start with a '/', then it is assumed to be found
# in the mailfilter directory if defined, maildir otherwise, and the home
# directory finally. The function returns the full path of the file derived
# from those rules but does not actually check whether file exists or not.
sub locate_file {
	local($filename) = @_;			# File we are trying to locate
	$filename =~ s/~/$cf'home/g;	# ~ substitution
	unless ($filename =~ m|^/|) {	# Do nothing if already a full path
		if (defined($XENV{'mailfilter'}) && $XENV{'mailfilter'} ne '') {
			$filename = $XENV{'mailfilter'} . "/$filename";
		} elsif (defined($XENV{'maildir'}) && $XENV{'maildir'} ne '') {
			$filename = $XENV{'maildir'} . "/$filename";
		} else {
			$filename = $cf'home . "/$filename";
		}
	}
	$filename =~ s/~/$cf'home/g;	# ~ substitution
	$filename;
}

# Locate specified program from command line by looking through the PATH
# like the shell would. Return the first matching program path or the program
# name if not found. Caller can check for the presence of '/' in the returned
# value to determine whether we succeeded. A leading ~ is replaced by the
# user's home directory.
sub locate_program {
	local($_) = @_;
	undef while s/^\s*[<>]\s*\S+//;	# Strip leading >&1 or >file directives
	local($name) = /^\s*(\S+)/;
	$name =~ s/~/$cf'home/g;		# ~ substitution
	return $name if $name =~ m|/|;	# Absolute or relative path, no search
	
	foreach $dir (split(/:/, $ENV{'PATH'})) {
		$dir = '.' if $dir eq '';
		return "$dir/$name" if -x "$dir/$name";
	}

	return $name;		# Not found, return plain name
}

