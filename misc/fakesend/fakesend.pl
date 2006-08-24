# $Id$
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log

#
# fakesend		-- new mailagent command
#
# Resend message as if it were being sent locally as a brand new message,
# removing all traces of origin from the one we got. 
#
# This comannd parses the first few lines of the body as a new header, that
# should contain at least a To: line, but that can contain also a Cc: and
# other header information. The only information kept from the original
# messages are Subject, Date, References and In-Reply-To.
#
# A new message is built and resent appropriately by letting sendmail
# parse the new To: and Cc: fields.
#
sub fakesend {
	my ($cmd_line) = @_;
	my @body = split(/\n/, $header{'Body'});
	my $x;
	my %nhead;						# New header
	my $last_header;
	local $_;
	my $cont = ' ' x 4;
	while (defined ($_ = shift(@body))) {
		last if /^\s*$/ || /^-+$/;	# End of new header (blank or --- line)
		if (/^\s/) {				# Continuation line
			s/^\s+/ /;
			$nhead{$last_header} .= "\n$cont$_" if $last_header ne '';
		} elsif (/^([\w-]+):\s*(.*)/) {
			my $value = $2;
			$last_header = header::normalize($1);
			if ($nhead{$last_header} ne '') {
				$nhead{$last_header} .= "\n$cont$value";
			} else {
				$nhead{$last_header} .= $value;
			}
		}	
	}
	unless ($nhead{'To'} || $nhead{'Cc'}) {
		&'add_log("FAKESEND found no To nor Cc line in new header");
		return 1;	# Failed
	}
	local *MAILER;
	unless (open(MAILER, "| /usr/lib/sendmail -t")) {
		&'add_log("ERROR cannot launch sendmail: $!") if $'loglvl;
		return 1;	# Failed
	}
	# Fake a from from ~/.mailagent, unless there was an extra From already
	print MAILER "From: $cf'name <$cf'email>\n" unless defined $nhead{'From'};

	# Propage old fields from original message
	foreach my $field (qw(Subject Date References In-Reply-To)) {
		next if $header{$field} eq '';
		print MAILER "$field: ", $header{$field}, "\n";
	}
	# Add all fields from new header
	foreach my $field (keys %nhead) {
		next if $nhead{$field} eq '';
		print MAILER "$field: ", $nhead{$field}, "\n";
	}
	print MAILER "\n";				# EOH
	foreach my $body (@body) {
		print MAILER $body, "\n";
	}
	&'add_log("FAKESEND To: $nhead{'To'}") if $'loglvl > 5 && $nhead{'To'};
	&'add_log("FAKESEND Cc: $nhead{'Cc'}") if $'loglvl > 5 && $nhead{'Cc'};
	close MAILER;
	my $status = $?;
	&'add_log("ERROR while closing sendmail: status = $status")
		if $status && $'loglvl;
	return $status != 0;			# Failure status
}

