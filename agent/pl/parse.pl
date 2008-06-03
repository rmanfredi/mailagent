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
;# $Log: parse.pl,v $
;# Revision 3.0.1.16  2001/03/17 18:13:15  ram
;# patch72: use the "domain" config var instead of mydomain
;#
;# Revision 3.0.1.15  2001/03/13 13:15:43  ram
;# patch71: added fix for broken continuations in parse_mail()
;#
;# Revision 3.0.1.14  2001/01/10 16:55:56  ram
;# patch69: allow direct IP numbers in Received fields
;#
;# Revision 3.0.1.13  1999/07/12  13:53:30  ram
;# patch66: weird Received: logging moved to higher levels
;#
;# Revision 3.0.1.12  1998/07/28  17:04:44  ram
;# patch62: become even more knowledgeable about Received lines
;#
;# Revision 3.0.1.11  1998/03/31  15:25:16  ram
;# patch59: when "tofake" is turned off, disable faking of To:
;# patch59: allow for missing "host1" in the Received: line parsing
;#
;# Revision 3.0.1.10  1997/09/15  15:16:00  ram
;# patch57: improved Received: line parsing logic
;#
;# Revision 3.0.1.9  1997/02/20  11:45:34  ram
;# patch55: improved Received: header parsing
;#
;# Revision 3.0.1.8  1997/01/07  18:33:09  ram
;# patch52: now pre-extend memory by using existing message size
;# patch52: enhanced Received: lines parsing
;#
;# Revision 3.0.1.7  1996/12/24  14:57:30  ram
;# patch45: new relay_list() routine to parse Received lines
;# patch45: now creates two pseudo headers: Envelope and Relayed
;#
;# Revision 3.0.1.6  1995/03/21  12:57:06  ram
;# patch35: now allows spaces between header field name and the ':' delimiter
;#
;# Revision 3.0.1.5  1995/02/16  14:35:15  ram
;# patch32: new routines header_prepend and header_append
;# patch32: can now fake a missing From: line in header
;#
;# Revision 3.0.1.4  1995/01/25  15:27:08  ram
;# patch27: ported to perl 5.0 PL0
;#
;# Revision 3.0.1.3  1994/09/22  14:33:38  ram
;# patch12: builtins handled in &run_builtins to allow re-entrance
;#
;# Revision 3.0.1.2  1994/07/01  15:04:02  ram
;# patch8: now systematically escape leading From if fromall is ON
;#
;# Revision 3.0.1.1  1994/04/25  15:18:14  ram
;# patch7: global fix for From line escapes to make them configurable
;#
;# Revision 3.0  1993/11/29  13:49:05  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Parsing mail
#

# Parse the mail and fill-in the Header associative array. The special entries
# All, Body and Head respectively hold the whole message, the body and the
# header of the message.
sub parse_mail {
	local($file_name) = shift(@_);	# Where mail is stored ("" for stdin)
	local($head_only) = shift(@_);	# Optional parameter: parse only header
	local($last_header) = "";		# Name of last header (for continuations)
	local($first_from) = "";		# The first From line in mails
	local($lines) = 0;				# Number of lines in the body
	local($length) = 0;				# Length of body, in bytes
	local($last_was_nl) = 1;		# True when last line was a '\n' (1 for EOH)
	local($fd) = STDIN;				# Where does the mail come from ?
	local($field, $value);			# Field and value for current line
	local($_);
	local($preext) = 0;
	local($added) = 0;
	local($curlen) = 0;
	undef %Header;					# Reset the whole structure holding message

	if ($file_name ne '') {			# Mail spooled in a file
		unless(open(MAIL, $file_name)) {
			&add_log("ERROR cannot open $file_name: $!");
			return;
		}
		$fd = MAIL;
		$preext = -s MAIL;
	}
	$Userpath = "";					# Reset path from possible previous @PATH 

	# Pre-extend 'All', 'Body' and 'Head'
	if ($preext <= 0) {
		$preext = 100_000;
		&add_log("preext uses fixed value ($preext)") if $loglvl > 19;
	} else {
		&add_log("preext uses file size ($preext)") if $loglvl > 19;
	}
	$preext += 500;					# Extra room for From --> >From, etc...

	$Header{'All'} = ' ' x $preext;
	$Header{'Body'} = ' ' x $preext;
	$Header{'Head'} = ' ' x 500;
	$Header{'All'} = '';
	$Header{'Body'} = '';
	$Header{'Head'} = '';

	&add_log ("parsing mail") if $loglvl > 18;
	while (<$fd>) {
		$added += length($_);

		# If string extension goes beyond the pre-allocated space, re-extend
		# by a big amount instead of letting perl realloc space.
		if ($added > $preext) {
			$curlen = length($Header{'All'});
			&add_log ("extended after $curlen bytes") if $loglvl > 19;
			$Header{'All'} .= ' ' x $preext;
			substr($Header{'All'}, $curlen) = '';
			$curlen = length($Header{'Body'});
			$Header{'Body'} .= ' ' x $preext;
			substr($Header{'Body'}, $curlen) = '';
			$added = $added - $preext;
		}

		$Header{'All'} .= $_;
		if (1../^$/) {						# EOH is a blank line
			next if /^$/;					# Skip EOH marker
			chop;

			if (/^\s/) {					# It is a continuation line
				my $val = $_;
				$val =~ s/^\s+/ /;			# Swallow multiple spaces
				$Header{$last_header} .= $val if $last_header ne '';
				&add_log("WARNING bad continuation in header, line $.")
					if $last_header eq '' && $loglvl > 4;
			} elsif (($field, $value) = /^([!-9;-~\w-]+):\s*(.*)/) {
				# We found a new header field (i.e. it is not a continuation).
				# Guarantee only one From: header line. If multiple From: are
				# found, keep the last one.
				# Multiple headers like 'Received' are separated by a new-
				# line character. All headers end on a non new-line.
				# Case is normalized before recording, so apparently-to will
				# be recorded as Apparently-To but header is not changed.
				$last_header = &header'normalize($field);	# Normalize case
				if ($last_header eq 'From' && defined $Header{$last_header}) {
					$Header{$last_header} = $value;
					&add_log("WARNING duplicate From in header, line $.")
						if $loglvl > 4;
				} elsif ($Header{$last_header} ne '') {
					$Header{$last_header} .= "\n" . $value;
				} else {
					$Header{$last_header} .= $value;
				}
			} elsif (/^From\s+(\S+)/) {		# The very first From line
				$first_from = $1;
			} else {
				# Did not identify a header field nor a continuation
				# Maybe there was a wrong header split somewhere?
				# If we did not encounter a header yet, we're seeing garbage.
				if ($last_header eq '') {
					&add_log("ERROR ignoring header garbage, line $.: $_")
						if $loglvl > 1;
					next;					# Skip insertion to 'Head'
				} else {
					&add_log("WARNING ".
						"faking continuation for $last_header, line $."
					) if $loglvl > 4;
					$_ = " " . $_;			# Patch line for 'Head'
					$Header{$last_header} .= $_;
				}
			}

			$Header{'Head'} .= $_ . "\n";	# Record line in header

		} else {
			last if $head_only;		# Stop parsing if only header wanted
			$lines++;								# One more line in body
			$length += length($_);					# Update length of message
			# Protect potentially dangerous lines when asked to do so
			# From could normally be mis-interpreted only after a blank line,
			# but some "broken" User Agents also look for them everywhere...
			# That's where fromall must be set to ON to escape all of them.
			s/^From(\s)/>From$1/ if $last_was_nl && $cf'fromesc =~ /on/i;
			$last_was_nl = /^$/ || $cf'fromall =~ /on/i;
			$Header{'Body'} .= $_;
		}
	}
	close MAIL if $file_name ne '';
	&header_prepend("$FAKE_FROM\n") unless $first_from;
	&header_check($first_from, $lines);	# Sanity checks
}

# Now do some sanity checks:
# - if there is no From: header, fill it in with the first From
# - if there is no To: but an Apparently-To:, copy it also as a To:
# - if an Envelope field was defined in the header, override it (sorry)
# - likewise for Relayed, which is the list of relaying hosts, first one first.
#
# We guarantee the following header entries:
#   Envelope:     the actual sender of the message, empty if cannot compute
#   From:         the value of the From field
#   To:           to whom the mail was sent
#   Lines:        number of lines in the message
#   Length:       number of bytes in the message
#   Relayed:      the list of relaying hosts deduced from Received: lines
#   Reply-To:     the address we may use to reply
#   Sender:       the value of the Sender field, same as From usually
#
sub header_check {
	local($first_from, $lines) = @_;	# First From line, number of lines
	unless (defined $Header{'From'}) {
		&add_log("WARNING no From: field, assuming $first_from") if $loglvl > 4;
		$Header{'From'} = $first_from;
		# Fake a From: header line unless prevented to do so. That way, when
		# saving in an MH or MMDF folder (where the leading From is stripped),
		# the user will still be able to identify the source of the message!
		if ($first_from && $cf'fromfake !~ /^off/i) {
			&add_log("NOTICE faking a From: header line") if $loglvl > 5;
			&header_append("From: $first_from\n");
		}
	}

	# There is usually one Apparently-To line per address. Remove all new lines
	# in the header line and replace them with ','. Likewise for To: and Cc:.
	# although it is far less likely to occur.
	foreach $field ('Apparently-To', 'To', 'Cc') {
		$Header{$field} =~ s/\n/,/gm;	# Remove new-lines
		$Header{$field} =~ s/,$/\n/m;	# Restore last new-line
	}

	# If no To: field, then maybe there is an Apparently-To: instead. If so,
	# make them identical. Otherwise, assume the mail was directed to the user.
	#
	# This changes the way filtering is done, so it's not always a good idea
	# to do it. Some people may want to explicitely check that there is no
	# To: line, but if we fake one, they'll never know. So check for tofake,
	# and if OFF, don't do anything.
	unless ($cf'tofake =~ /^off/i) {
		if (!$Header{'To'} && $Header{'Apparently-To'}) {
			$Header{'To'} = $Header{'Apparently-To'};
		}
		unless ($Header{'To'}) {
			&add_log("WARNING no To: field, assuming $cf'user") if $loglvl > 4;
			$Header{'To'} = $cf'user;
		}
	}

	# Set number of lines in body, unless there is already a Lines:
	# header in which case we trust it. Same for Length.
	$Header{'Lines'} = $lines unless defined($Header{'Lines'});
	$Header{'Length'} = length($Header{'Head'}) + length($Header{'Body'}) + 1
		unless defined($Header{'Length'});

	# If there is no Reply-To: line, then take the address in From, if any.
	# Otherwise use the address found in the return-path
	if (!$Header{'Reply-To'}) {
		local($tmp) = (&parse_address($Header{'From'}))[0];
		$Header{'Reply-To'} = $tmp if $tmp ne '';
		$Header{'Reply-To'} = (&parse_address($Header{'Return-Path'}))[0]
			if $tmp eq '';
	}

	# Unless there is already a sender line, fake one using From field
	if (!$Header{'Sender'}) {
		$Header{'Sender'} = $first_from;
		$Header{'Sender'} = $Header{'From'} unless $first_from;
	}

	# Now override any Envelope header and grab it from the first From field
	# If such a field was defined in the message header, then sorry but it
	# was a mistake: RFC 822 doesn't define it, so it should have been
	# an X-Envelope instead.

	$Header{'Envelope'} = $first_from;

	# Finally, compute the list of relaying hosts. The first host which saw
	# this message comes first, the last one (normally the machine receiving
	# the mail) coming last.

	unless ($Header{'Relayed'} = &relay_list) {
		&add_log("WARNING no valid Received: indication") if $loglvl > 4;
	}
}

# Compute the relaying hosts by looking at the Received: lines and parsing
# them to deduce which host saw and relayed the message. We parse things
# like this:
#
#	Received: from host1 (host2 [xx.yy.zz.tt]) by host3
#	Received: from host1 ([xx.yy.zz.tt]) by host3
#	Received: from ?host1? ([xx.yy.zz.tt]) by host3
#	Received: from host1 by host3
#	Received: from (host2 [xx.yy.zz.tt]) by host3
#	Received: from (host1) [xx.yy.zz.tt] by host3
#	Received: from host1 [xx.yy.zz.tt] by host3
#	Received: from host2 [xx.yy.zz.tt] (host1) by host3
#	Received: from (user@host1) by host3
#
# The host2, when present, is the reverse DNS mapping of the IP address.
# It can be different from host1 in case of local /etc/host aliasing for
# instance. This is used when present, otherwise we must trust host1.
# The host3 information is never used here. It is possible for host1 to
# be a simple IP address [xx.yy.zz.tt].
#
# The latest Received: line inserted in the header is the one added by
# the host receiving the message. For local messages, it may be the
# only line present. It is the only line for which host3 is used, since
# it is probable we can trust our local delivery mailer.
# 
# The returned comma-separated list is sorted to have the first relaying
# host come first (whilst Received headers are normally prepended, which
# yields a reverse host chain).
sub relay_list {
	local(@received) = split(/\n/, $Header{'Received'});
	return '' unless @received;
	local(@hosts);					# List of relaying hosts
	local($host, $real);
	local($islast) = 1;				# First line we see is the "last" inserted
	local($received);				# Received line, verbatim
	local($i);
	local($_);

	# All the known top-level domains as of 2006-08-15
	# with the addition of "loc" and "private".
	# See http://data.iana.org/TLD/tlds-alpha-by-domain.txt
	my $tlds_re = qr/
		a(?:ero|rpa|[c-gil-oq-uwxz])|
		b(?:iz|[abd-jmnorstvwyz])|
		c(?:at|o(?:m|op)|[acdf-ik-oruvxyz])|
		d[ejkmoz]|
		e(?:du|[cegr-u])|
		f[ijkmor]|
		g(?:ov|[abd-ilmnp-uwy])|
		h[kmnrtu]|
		i(?:n(?:fo|t)|[del-oq-t])|
		j(?:obs|[emop])|
		k[eghimnrwyz]|
		l(?:[abcikr-vy]|oc)|
		m(?:il|obi|useum|[acdghk-z])|
		n(?:ame|et|[acefgilopruz])|
		o(?:m|rg)|
		p(?:r(?:ivate|o)|[ae-hk-nrstwy])|
		qa|
		r[eouw]|
		s[a-eg-ortuvyz]|
		t(?:ravel|[cdfghj-prtvwz])|
		u[agkmsyz]|
		v[aceginu]|
		w[fs]|
		y[etu]|
		z[amw]
	/ix;

	for ($i = 0; $i < @received; $i++) {
		$received = $_ = $received[$i];

		# Handle first Received line (the last one added) specially.
		if ($islast) {
			if (
				/\bby\s+(\[\d+\.\d+\.\d+\.\d+\])/i	||
				/\bby\s+([\w-.]+)/i
			) {
				$host = $1;
				$host .= ".$cf::domain"
					if $host =~ /^\w/ && $host !~ /\.$tlds_re$/;
				push(@hosts, $host);
			} else {
				&add_log("WARNING no by in first Received: line '$received'")
					if $loglvl > 4;
			}
			$islast = 0;
		}

		next unless s/^\s*from\s+//i;
		next if s/^by\s+//i;		# Host name missing

		# Look for host1, which must be there somehow since we found a 'from'
		# Some sendmails like to add a leading 'login@' before the address,
		# so strip that out before being fancy...
		# The only case host1 was seen to be missing was when it is replaced
		# by an (host2 [ip]) specification instead.

		s/^\w+\@//;
		# [xx.yy.zz.tt]
		if (s/^(\[\d+\.\d+\.\d+\.\d+\])\s*//) {
			$host = $1;				# IP address [xx.yy.zz.tt]
		}
		# ?xx.yy.zz.tt? ( [XX.YY.ZZ.TT])
		elsif (s/^\?[\d\.]+\?\s*\(\s*(\[\d+\.\d+\.\d+\.\d+\])\s*\)\s*//) {
			$host = $1;
		}
		# foo.domain.com (optional)
		elsif (s/^([\w-.]+)(\(\S+\))?\s*//) {
			$host = $1;				# host name
		}
		# (user@foo.domain.com)
		elsif (s/^\(\w+\@([\w-.]+)\)\s*//) {
			$host = $1;				# host name
		}
		# (foo.domain.com) [xx.yy.zz.tt]
		#  foo.domain.com  [xx.yy.zz.tt]
		elsif (s/^\(?([\w-.]+)\)?\s*\[\d+\.\d+\.\d+\.\d+\]\s*//) {
			$host = $1;				# host name
		}
		# Unrecognized, but starting with a parenthesis, hinting for host2...
		elsif (m/^\(/) {
			$host = undef;			# host1 missing, but host2 should be there
		} else {
			&add_log("WARNING invalid from in Received: line '$received'")
				if $loglvl > 4;
			next;
		}

		# There may be an IP or reverse DNS mapping, which will be used to
		# supersede the current $host if found. Note that some (local) mailers
		# insert host as login@host, so we remove the login part.
		# Also handle things like (really foo.com) or (actually real.host), i.e
		# allow an adjective to qualify the real host name.
		#
		# Note: we don't anchor the match at the beginning of the string
		# since we want to parse the 'user@255.190.143.3' as in:
		#   from foo.net (HELO master.foo.org) (user@255.190.143.3) by bar.net
		# and it may not come first... Later on, we'll remove all remaining
		# leading unrecognized () information.
		#
		# The cryptic regexps below attempt to recognize things like:
		#    (user@foo.domain.com [xx.yy.zz.tt])
		#    (WORD user@foo.domain.com [xx.yy.zz.tt])

		$real = '';
		$real = $1 eq '' ? $2 : $1 if
			s/\(([\w-.@]*)?\s*(\[\d+\.\d+\.\d+\.\d+\])?\)\s*// ||
			s/\(\w+\s+([\w-.@]*)?\s*(\[\d+\.\d+\.\d+\.\d+\])?\)\s*//;
		$real =~ s/^.*\@//;
		$real = '' if $real =~ /^[\d.]+$/;		# A sendmail version number!

		# Supersede the host name computed in the previous parsing only
		# if the "real" host name we attempted to guess is an IP address
		# or looks like a fully qualified domain name.

		$host = $real if $real =~ /\.$tlds_re$/ || $real =~ /^\[[\d.]+\]$/;

		if ($host eq '') {
			&add_log("NOTICE no relaying origin in Received: line '$received'")
				if $loglvl > 6;
			next;
		}

		# If we have not recognized anything above, then we don't want to
		# handle anything between () that may follow the original host name.
		# There are just too many formats out there and we can't definitively
		# parse them all. There may even be multiple such occurrences like:
		#   from foo.net (HELO master.foo.org) (user@255.190.143.3) by bar.net
		# Just skip them.

		s/^\([^)]*\)\s+//g;

		# At this point, we should have a 'by ' string somewhere, or an EOS.
		# We're not checking the 'by' immediately (as in /^by/) because some
		# mailers like inserting comments such as 'with ESMTP' or 'via xyzt'.
		# Also, I have seen stange things like 'from xxx from xxx by yyy'.
		#
		# Otherwise we have an unknown Received line format.
		# This is not as bad as not being able to deduce host1 or host2.
		# The full line is logged, so that we may improve our fuzzy matching
		# policy.
		#
		# Note: the lack of 'by' is only allowed for the first Received line
		# stacked, i.e. the last one we parse here...

		unless (/\s*by\s+/i || /^\s*$/ || $i == $#received) {
			&add_log("weird Received: line '$received'") if $loglvl > 8;
		}

		# Validate the host. It must be either an internet [xx.yy.zz.tt] form,
		# or a domain name. This also skips things like 'localhost'.  We
		# also accept pure xx.yy.zz.tt (i.e. without surrounding brackets)

		unless (
			$host =~ /^\[[\d.]+\]$/							||
			$host =~ /^[\w-.]+\.$tlds_re$/					||
			$host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
		) {
			next if $host =~ /^[\w-]+$/;	# No message for unqualified hosts
			&add_log("ignoring bad host $host in Received: line '$received'")
				if $loglvl > 6;
			next;
		}

		push(@hosts, $host);
	}

	# Remove duplicate consecutive hosts in the list, since this is probably
	# an internal relaying (where we don't have real names but only aliases,
	# otherwise the message would have looped forever!) and does not bring
	# us much.

	local($last, $dup);
	local(@unique) = grep(($dup = $last ne $_, $last = $_, $dup), @hosts);

	return join(', ', reverse @unique);
}


# Append given field to the header structure, updating the whole mail
# text at the same time, hence keeping the %Header table.
# The argument must be a valid formatted RFC-822 mail header field.
sub header_append {
	local($hline) = @_;
	$Header{'Head'} .= $hline;
	$Header{'All'} = $Header{'Head'} . "\n" . $Header{'Body'};
}

# Prepend given field to the whole mail, updating %Header fields accordingly.
sub header_prepend {
	local($hline) = @_;
	$Header{'Head'} = $hline . $Header{'Head'};
	$Header{'All'} = $hline . $Header{'All'};
}

