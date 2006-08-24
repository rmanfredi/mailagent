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
;# $Log: hostname.pl,v $
;# Revision 3.0  1993/11/29  13:48:52  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
# Return only the hostname portion of the host name (no domain name)
sub myhostname {
	local($_) = &hostname;
	s/^([^.]*)\..*/$1/;			# Trim down domain name
	$_;
}

# Compute hostname once and for all and cache its value (since we have to fork
# to get it).
sub hostname {
	unless ($cache'hostname) {
		chop($cache'hostname = `$phostname`);
		$cache'hostname =~ tr/A-Z/a-z/;			# Cannonicalize to lower case
	}
	$cache'hostname;
}

