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
;# $Log: include.pl,v $
;# Revision 3.0.1.2  1998/07/28  17:02:49  ram
;# patch62: skip blank lines in included file
;#
;# Revision 3.0.1.1  1998/03/31  15:22:33  ram
;# patch59: typo fix in comment
;#
;# Revision 3.0  1993/11/29  13:48:52  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Process "include-file" requests. The file is allowed to have shell comments
# and leading spaces are trimmed. The function returns an array, each item
# being one of the non-comment and non-empty lines found in the file.
sub include_file {
	local($inc) = shift(@_);	# Include request "file-name"
	local($what) = shift(@_);	# What we are looking for (singular)
	local(*INCLUDE);			# Local file handle
	local($filename) = $inc =~ /^"(.*)"$/;
	local(@result);
	local($_);
	# Find file using mailfilter, maildir variables if not specified with an
	# absolute pathname (starting with a '/').
	$filename = &locate_file($filename);
	&add_log("loading ".&plural($what)." from $filename") if $loglvl > 18;
	if ($filename ne '' && open(INCLUDE, "$filename")) {
		while (<INCLUDE>) {
			next if /^\s*#/;	# Skip shell comments
			next if /^\s*$/;	# Skip blank lines
			chop;
			s/^\s+//;			# Remove leading spaces
			push(@result, $_);
			&add_log("loaded $what '$_'") if $loglvl > 19;
		}
		close INCLUDE;
	} elsif ($filename ne '') {		# Could not open file
		&add_log("WARNING couldn't open $filename for ".&plural($what).": $!")
			if $loglvl > 4;
	} else {
		&add_log("WARNING incorrect file inclusion request: $inc")
			if $loglvl > 4;
	}
	@result;		# List of non-comment lines held in file
}

