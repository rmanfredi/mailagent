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
;# $Log: macros.pl,v $
;# Revision 3.0.1.5  1999/01/13  18:14:25  ram
;# patch64: new %Y macro for 4-digit year, %y being year modulo 100
;#
;# Revision 3.0.1.4  1995/01/25  15:24:32  ram
;# patch27: ported to perl 5.0 PL0
;#
;# Revision 3.0.1.3  1995/01/03  18:12:26  ram
;# patch24: the %=config variables were not properly substituted
;#
;# Revision 3.0.1.2  1994/10/29  17:48:03  ram
;# patch20: now uses ^B! characters in macro substitution for %
;# patch20: added support for local (internal) macro overriding
;#
;# Revision 3.0.1.1  1994/10/04  17:53:06  ram
;# patch17: new %e macro to get the user's e-mail address
;#
;# Revision 3.0  1993/11/29  13:48:57  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Macros:
;# %%     A real percent sign
;# %A     Sender's main address (host.domain.ct in user@loc.host.domain.ct)
;# %C     CPU name, fully qualified with domain name
;# %D     Day of the week (0-6)
;# %H     Host name (name of the machine on which the mailagent runs)
;# %I     Internet domain from sender (domain.ct in user@host.domain.ct)
;# %L     Length of the message in bytes (without header, no transfer encoding)
;# %N     Full name of sender (login name if none)
;# %O     Organization name from sender address (domain in user@host.domain.ct)
;# %R     Subject of orginal message with leading Re: suppressed
;# %S     Re: subject of original message
;# %T     Time of last modification on mailed file (value taken from $macro_T)
;# %U     Full name of the user
;# %Y     Year (yyyy format)
;# %_     A white space
;# %#reg  Value of user-defined variable 'reg'
;# %&     List of selectors which incurred match (among regexps ones) 
;# %~     A null character
;# %1     Value of the corresponding backreference (limited to 99 per rule)
;# %d     Day of the month (01-31)
;# %e     User's email address
;# %f     Contents of the "From:" line, something like %N <%r> or %r (%N)
;# %h     Hour of the day (00-23)
;# %i     Message ID if available
;# %l     Number of lines in the message
;# %m     Month of the year (01-12)
;# %n     Lower-case login name of sender
;# %o     Organization (where mailagent runs)
;# %r     Return address of message
;# %s     Subject of original message
;# %t     Current hour and minute (in HH:MM format)
;# %u     Login name of the user
;# %y     Year (last two digits)
;# %[To]  Value of the field in header (here To:)
;# %=var  Value of the configuration variable (from ~/.mailagent)
;# %-(x)  User-defined macro (x stands for an arbitrary name)
;# %-x    Short-cut for single letter user-defined macros
;#
;# An interface is defined internally to overrride or extend the set of
;# macros recognized by &macros_subst. The &macro'overload routine is used
;# to specify new macros, and &macro'unload *must* be called to restore the
;# default behaviour. It is not possible to stack overloadings.
;#
#
# Macro handling (system)
#

# Macros substitutions (in-place)
sub macros_subst {
	local(*str) = shift(@_);			# The string
	local($_) = $str;					# Work on a copy
	return $_ unless /%/;				# Return immediately if no macros

	local($sender);							# The from field
	local(@from);							# The rfc-822 parsed from line
	$sender = $Header{'From'};				# Header-derived From address
	@from = &parse_address($sender);		# Get (address, comment)
	local($login) = &login_name($from[0]);	# Keep only login name
	local($fullname) = $from[1];			# The comment part of address
	$fullname = $login unless $fullname;	# Use login name if no comment part
	local($reply_to) = $Header{'Reply-To'}; # Return path derived
	local($subject) = $Header{'Subject'};	# Original subject header
	$subject =~ s/^\s*Re:\s*(.*)/$1/;		# Strip off leading Re:
	$subject = "<empty subject>" unless $subject;
	$reply_to = (&parse_address($reply_to))[0];	# Keep only e-mail address

	# Time computations
	local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
			localtime(time);
	$mon = sprintf("%.2d", $mon + 1);
	$mday = sprintf("%.2d", $mday);
	local($timenow) = sprintf("%.2d:%.2d", $hour, $min);
	$hour = sprintf("%.2d", $hour);
	$year += 1900;

	# The following dummy block is here only to force perl interpreting
	# the $ variables in the substitutions correctly...
	if (0) {
		$Header{'a'} = 'a';
		$Variable{'a'} = 'a';
		$Backref[0] = 0;
	}

	s/%%/\01/g;							# Protect double percent signs
	s/%/\02!/g;							# Make sure substitutions do not add %

	&macro'over if defined &macro'over;	# Allow for internal override

	# In the following, substitutions marked as "workaround for perl 5.0 bug"
	# are fixing the fact that $1 will get clobbered if the routine used in
	# the substitution part is dataloaded.

	s/\02!A/&macro'internet/eg;			# Main internet address of sender
	s/\02!d/$mday/g;					# Day of the month (01-31)
	s/\02!C/&domain_addr/eg;			# CPU name, fully qualified with domain
	s/\02!D/$wday/g;					# Day of the week (0-6)
	s/\02!e/$cf'email/go;				# The user's email address
	s/\02!f/$Header{'From'}/g;			# The "From:" line
	s/\02!h/$hour/g;					# Hour of the day (00-23)
	s/\02!H/&myhostname/eg;				# Hostname on which mailagent runs
	s/\02!i/$Header{'Message-Id'}/g;	# Message-Id (null string if none)
	s/\02!I/&macro'domain/eg;			# Internet domain name of sender
	s/\02!l/$Header{'Lines'}/g;			# Number if lines in message
	s/\02!L/$Header{'Length'}/g;		# Length of message, in bytes
	s/\02!m/$mon/g;						# Month of the year
	s/\02!n/$login/g;					# Lower-cased login name of sender
	s/\02!N/$fullname/g;				# Full name of sender (login if none)
	s/\02!o/$orgname/g;					# Organization name
	s/\02!O/&macro'org/eg;				# Organization part of sender's address
	s/\02!r/$reply_to/g;				# Return path of message
	s/\02!R/$subject/g;					# Subject with leading Re: suppressed
	s/\02!s/$Header{'Subject'}/g;		# Subject of message
	s/\02!S/Re: $Header{'Subject'}/g;	# Re: subject of original message
	s/\02!t/$timenow/g;					# Current time HH:MM
	s/\02!T/$macro_T/g;					# Time of last modification on file
	s/\02!u/$cf'user/go;				# User login name (does not change)
	s/\02!U/$cf'name/go;				# User's name (does not change)
	s/\02!y/$year % 100/eg;				# Year (last two digits)
	s/\02!Y/$year/g;					# Year (yyyy format)
	s/\02!_/ /g;						# A white space
	s/\02!~//g;							# A null character
	s/\02!&/$macro_ampersand/g;			# List of matched generic selectors
	s/\02!(\d\d?)/$Backref[$1 - 1]/g;	# A pattern matching backreference
	s/\02!#:(\w+)/local($x) = $1; &extern'val($x)/eg;
		# A persistent user-defined variable (workaround for perl 5.0 PL0 bug)
	s/\02!#(\w+)/$Variable{$1}/g;		# A user-defined variable
	s/\02!\[([\w-]+)\]/$Header{$1}/g;	# The %[Field] macro
	s/\02!=(\w+)/"\$cf'$1"/gee;			# The %=config_var variable
	s/\02!-([^\s(])/local($x) = $1; &macro'usr($x)/ge;
		# A %-x single letter user macro (workaround for perl 5.0 PL0 bug)
	s/\02!-\(([^\s)]+)\)/local($x) = $1; &macro'usr($x)/ge;
		# A %-(complex) user-defined macro (workaround for perl 5.0 PL0 bug)

	s/\02!/%/g;							# Any remaining percent is kept
	s/\01/%/g;							# A double percent expands to %
	$str = $_;							# Update string in-place
}

package macro;

# Return the internet information of the From address
sub info {
	local($addr) = (&'parse_address($'Header{'From'}))[0];
	&'internet_info($addr);
}

# Return the organization name
sub org {
	local($host, $domain, $country) = &info;
	$domain;
}

# Return the domain name
sub domain {
	local($host, $domain, $country) = &info;
	$domain .'.'. $country;
}

# Return the qualified internet address
sub internet {
	local($host, $domain, $country) = &info;
	$host ne '' ? $host .'.'. $domain .'.'. $country : $domain .'.'. $country;
}

#
# Internal override feature
#

# Record a new set of macros within the &over routine. Macros are defined
# using a low-level (ok, perl) description, but hey! this is an internal
# feature not intended to be used by others. The argument is a single string
# formatted this way:
#   <l> <value> <mod>
# where <l> is a single letter or group of letters, <value> is what will be
# substituted when the macro is seen, and <mod> are the perl modifiers that
# should be added at the end of the substitute perl statement.
sub overload {
	local($macros) = @_;
	local(@macs) = split(/\n/, $macros);
	local($_);
	local($fn);					# Where the &over routine is built
	local($l, $value, $mod);
	$fn = "sub over {\n";
	foreach (@macs) {
		($l, $value, $mod) = split;
		$fn .= 's/\02!'.$l.'/'.$value."/g$mod;\n";
	}
	$fn .= "}\n";
	undef &over if defined &over;
	eval $fn;
	&'add_log("ERROR in &macro'overload: $@") if chop($@) && $'loglvl;
}

# Free routine defined by &overload
sub unload { undef &over }

;#
;# User-defined macro handled by &macro'usr, which is defined in the usrmac.pl
;# file to emphasize there the link with &macros_subst.
;#

package main;

