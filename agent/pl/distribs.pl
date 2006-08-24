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
;# $Log: distribs.pl,v $
;# Revision 3.0  1993/11/29  13:48:40  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
;# This file relies on the following external conditions:
;#    - operation &fatal() available for fatal errors
;#    - the configuration variables are properly set
;#    - logging is done via &add_log()
;#
# Read a distribution file and fill in data structures for
# the query functions. All the data are stored in associative
# arrays, indexed by the system's name and version number.
# Associative arrays are:
#
# name          indexed by       information
#
# %Program      name + version   have we seen that line ?
# %System       name             is name a valid system ?
# %Version      name             latest version for system
# %Location		name + version   location of the distribution
# %Archived     name + version   is distribution archived ?
# %Compressed   name + version   is archive compressed ?
# %Patch_only   name + version   true if only patches delivered
# %Maintained   name + version   true if distribution is maintained
# %Patches      name + version   true if official patches available
#
# For systems with a version of '---' in the file, the version
# for accessing the data has to be a "0" string.
#
# Expected format for the distribution file:
#     system version location archive compress patches
#
# The `archive', `compress' and `patches' fields can take one
# of the following states: "yes" and "no". An additional state
# for `patches' is "old", which means that only patches are
# available for the version, and not the distribution. Another is
# "patch" which means that official patches are available.
# All these states can be abbreviated with the first letter.
#
sub read_dist {
	local($fullname);
	open(DIST, "$cf'distlist") ||
		&fatal("cannot open distribution file");
	while (<DIST>) {
		next if /^\s*#/;	# skip comments
		next if /^\s*$/;	# skip empty lines
		next unless s/^\s*(\w+)\s+([.\-0-9]+)//;
		$fullname = $1 . "|" . ($2 eq '---'? "0" : $2);
		if (defined $Program{$fullname}) {
			&add_log("WARNING duplicate distlist entry $1 $2 ignored")
				if $loglvl > 5;
			next;
		}
		$Program{$fullname}++;
		$Version{$1} = ($2 eq '---' ? "0" : $2) unless
			defined($System{$1}) && $Version{$1} > ($2 eq '---' ? "0":$2);
		$System{$1}++;
		unless (/^\s*(\S+)\s+(\w+)\s+(\w+)\s+(\w+)/) {
			&add_log("WARNING bad system description line $.")
				if $loglvl > 5;
			next;	# Ignore, but it may corrupt further processing
		}
		local($location) = $1;
		local($archive) = $2;
		local($compress) = $3;
		local($patch) = $4;
		$location =~ s/~\//$cf'home\//;		# ~ expansion
		$Location{$fullname} = $location;
		$Archived{$fullname}++ if $archive =~ /^y/;
		$Compressed{$fullname}++ if $compress =~ /^y/;
		$Patch_only{$fullname}++ if $patch =~ /^o/;
		$Maintained{$fullname}++ if $patch =~ /^y|o/;
		$Patches{$fullname}++ if $patch =~ /^p/;
	}
	close DIST;
}

