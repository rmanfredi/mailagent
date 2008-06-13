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
;# $Log: builtins.pl,v $
;# Revision 3.0.1.2  2001/03/17 18:11:16  ram
;# patch72: hostname computed via domain_addr() to honour hidenet
;#
;# Revision 3.0.1.1  1994/09/22  14:10:40  ram
;# patch12: added escapes in strings for perl5 support
;# patch12: builtins are now looked for in &run_builtins
;#
;# Revision 3.0  1993/11/29  13:48:35  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Executing builtin commands
#

# Send a receipt
sub send_receipt {
	local($subj) =			$Header{'Subject'};
	local($msg_id) =		$Header{'Message-Id'};
	local($from) =			$Header{'From'};
	local($sender) =		$Header{'Reply-To'};
	local($to) =			$Header{'To'};
	local($ack_dest) = @_;	# Were to send receipt
	local($dest);			# Return path to be used (derived from mail)

	# If no @PATH directive was found, use $sender as a return path
	$dest = $Userpath;				# Set by an @PATH
	$dest = $sender unless $dest;
	# Remove the <> if any (e.g. path derived from Return-Path)
	$dest =~ /<(.*)>/ && ($dest = $1);

	# Derive a correct return path for receipt
	$ack_dest = 'PATH' if $ack_dest eq '-';
	$ack_dest = "" if $ack_dest =~ /[=\$^&*([{}`\\|;><?]/;
	$ack_dest = $dest if ($ack_dest eq '' || $ack_dest =~ /PATH/);

	my $hostname = &domain_addr;
	my $date;
	chop($date = `date`);
	open(MAILER,"|$cf'sendmail $cf'mailopt $ack_dest");
	print MAILER <<EOM;
To: $ack_dest
Subject: Re: $subj (receipt)
$MAILER
EOM
	if ($msg_id ne '') {
		print MAILER "\nYour message $msg_id,\n";
	} else {
		print MAILER "\nYour message ";
	}
	print MAILER "addressed to $to,\n" if $to ne '';
	print MAILER "whose subject was \"$subj\",\n" if $subj ne '';
	print MAILER <<EOM;
has been received by $hostname on $date

-- mailagent speaking for $cf'user
EOM
	close MAILER;
	if ($?) {
		&add_log("ERROR couldn't send receipt to $ack_dest") if $loglvl > 0;
	} else {
		&add_log("SENT receipt to $ack_dest") if $loglvl > 2;
	}
}

#
# Deal with builtins
#

# Built-in commands are listed herein. Those commands being built-in are always
# dealt with during mail parsing and are taken care of at the beginning of the
# rules analysis. The code to be executed for each builtin is stored in the
# Builtcode array by those routines.
sub init_builtins {
	%Builtin = (
		'RR', 'builtin_rr',
		'PATH', 'builtin_path'
	);
	undef @Builtcode;
}

# Whenever a builtin command is recognized (on the fly) while parsing the mail
# body, the corresponding builtin function is called with the remaining of the
# line given as argument (leading spaces removed).

# The @RR command asks for a receipt
sub builtin_rr {
	local($_) = @_;
	&add_log("found an \@RR request to $_") if $loglvl > 18;
	# @RR request honored only if not from special user and directed to us
	unless (&special_user) {
		push(@Builtcode, "&send_receipt('$_')");
	} else {
		&add_log("ignoring \@RR request to $_") if $loglvl > 4;
	}
}

# The @PATH command sets a valid return path (recorded in $Userpath)
sub builtin_path {
	local($_) = @_;
	return if /[=\$^&*([{}`\\|;><?]/;		# Invalid character found
	$Userpath = $_;
	&add_log("found an \@PATH request to $_") if $loglvl > 18;
}

# Execute stacked builtins
sub run_builtins {
	undef @Builtcode;
	# Lookup for builtins. Code moved out of &parse_mail.
	# We scan the *decoded* body, not the original one
	foreach $line (split(/\n/, ${$Header{'=Body='}})) {
		if ($line =~ s/^@(\w+)\s*//) {			# A builtin command ?
			local($subroutine) = $Builtin{$1};
			&$subroutine($line) if $subroutine;	# Record it if known
		}
	}
	# End of original &parse_mail exerpt, beginning of original &run_builtins
	# NOTE: since builtins are now looked for here and run from there directly,
	# going through the burden of @Builtcode is not necessary. Will get fixed
	# one day, possibly.
	return if $#Builtcode < 0;		# No recorded builtins
	foreach (@Builtcode) {
		eval($_);					# Execute stacked builtin
	}
	undef @Builtcode;				# Reset builtcode array
}

