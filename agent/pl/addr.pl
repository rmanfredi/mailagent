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
;# $Log: addr.pl,v $
;# Revision 3.0.1.5  1997/01/07  18:32:15  ram
;# patch52: slight mis-parsing of user names with '-' in them
;#
;# Revision 3.0.1.4  1995/02/03  17:59:19  ram
;# patch30: ensure domain name matches are made after the '@' delimiter
;#
;# Revision 3.0.1.3  1994/10/10  10:23:58  ram
;# patch19: added various escapes in strings for perl5 support
;#
;# Revision 3.0.1.2  1994/10/04  17:47:17  ram
;# patch17: now checks for shell meta-characters in addresses
;#
;# Revision 3.0.1.1  1994/09/22  14:08:28  ram
;# patch12: created
;#
;#
package addr;

#
# Address stuff, mainly for mailing list maintainance (package command)
#

# Is an address valid?
# Addresses containing either '|' or '/' in them are considered hostile, since
# sendmail for instance would attempt to deliver to a program or to a file...
# Also, the address must not contain any space or control characters.
# Since the address might also be given verbatim on a shell command line,
# it must not contain any "funny" shell meta-characters.
sub valid {
	local($_) = @_;
	return 0 if $_ eq '';		# Empty address
	return 0 if tr/\0-\31//;	# Control character found
	return 0 if /\s/;			# No space in address
	return 0 if m![\$^&*()[{}`\\|;><?]!;
	1;							# Address is ok
}

# Simplify address for comparaison purposes
sub simplify {
	local($_) = @_;

	return &simplify($_) if s/^@[\w-.]+://;			# @b.c:x -> x and retry
	return "$2\@$1.uucp" if /^([\w-]+)!(\w+)$/;		# b!u -> u@b.uucp
	return "$2\@$1" if /^([\w-.]+)!(\w+)$/;			# b.c!u -> u@b.c
	return $_ if /^[\w.-]+@[\w-.]+$/;				# u@b.c
	return &simplify("$2!$3")
		if /([^%@]+)!([\w-.]+)!(\w+)$/;				# ...!b!u -> b!u
	return "$1\@$2"
		if /^([\w.-]+)%([\w-.]+)@[\w-.]+/;			# u%b.c@d.e -> u@b.c
	return &simplify($1) if s/(.*)@[\w-.]+$//;		# x@b.c -> x and retry
	return &simplify("$1\@$2")
		if /^([\w-.%!]+)%([\w-.]+)$/;				# x%b -> x@b and retry

	return $_;		# Hmm... Better stop here, since we are clueless!!
}

# Does first address matches second address?
sub match {
	local($a1, $a2) = @_;		# Two plain e-mail addresses (no comments)
	$a1 =~ tr/A-Z/a-z/;			# Cannonicalize to lower case
	$a2 =~ tr/A-Z/a-z/;
	local($s1) = &simplify($a1);
	local($s2) = &simplify($a2);
	return 1 if $s1 eq $s2;
	# Face ram@lyon.eiffel.com versus ram@york.eiffel.com or ram@eiffel.com
	# We do not want a match in the first case, but it's ok for the other one.
	local($p1, $p2) = ($s1, $s2);
	$p1 =~ s/(\W)/\\$1/g;
	$p2 =~ s/(\W)/\\$1/g;
	$p1 =~ s/@/@[\\w-]+\\./;
	$p2 =~ s/@/@[\\w-]+\\./;
	$s1 =~ /^$p2$/ || $s2 =~ /^$p1$/;
}

# Are the two addresses close?
# They are if they match or if their login name is the same or they are
# within the same subdomain.domain.country or domain.country.
sub close {
	local($a1, $a2) = @_;		# Two plain e-mail addresses (no comments)
	return 1 if &match($a1, $a2);
	$a1 =~ tr/A-Z/a-z/;			# Cannonicalize to lower case
	$a2 =~ tr/A-Z/a-z/;
	$a1 = &simplify($a1);
	$a2 = &simplify($a2);
	local($l1, $l2);			# Login names
	local($d1, $d2);			# Domain names
	($l1) = $a1 =~ /^(.*)@/;
	($l2) = $a2 =~ /^(.*)@/;
	return 1 if $l1 ne '' && $l1 eq $l2;
	($d1) = $a1 =~ /\@([\w-]+\.[\w-]+\.[\w]+)$/;
	($d2) = $a2 =~ /\@([\w-]+\.[\w-]+\.[\w]+)$/;
	return 1 if $d1 ne '' && $d1 eq $d2;
	($d1) = $a1 =~ /\@([\w-]+\.[\w]+)$/;
	($d2) = $a2 =~ /\@([\w-]+\.[\w]+)$/;
	return 1 if $d1 ne '' && $d1 eq $d2;
	return 0;
}

package main;

