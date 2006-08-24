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
;# $Log: mailhook.pl,v $
;# Revision 3.0.1.2  1996/12/24  14:55:06  ram
;# patch45: correctly initializes @cc to be the Cc: field
;# patch45: added @relayed and $lines, $length
;#
;# Revision 3.0.1.1  1994/09/22  14:26:22  ram
;# patch12: propagates folder_saved as msgpath in PERL escapes
;#
;# Revision 3.0  1993/11/29  13:48:58  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# Various hook utilities
# (name in package hook, compiled in package mailhook)
#

package mailhook;

# Parse mail and initialize special variables. The perl script used as hook
# does not have (usually) to do any parsing on the mail. Headers of the mail
# are available via the %header array and some special variables are set as
# conveniences.
sub hook'initvar {
	local($package) = @_;		# Package into which variables should be set
	local($init) = &'q(<<'EOP');
:	*header = *main'Header;		# User may fetch headers via %header
:	$msgpath = $main'folder_saved;
:	$sender = $header{'Sender'};
:	$subject = $header{'Subject'};
:	$precedence = $header{'Precedence'};
:	$from = $header{'From'};
:	$to = $header{'To'};
:	$cc = $header{'Cc'};
:	$lines = $header{'Lines'};
:	$length = $header{'Length'};
:	$envelope = $header{'Envelope'};
:	($reply_to) = &'parse_address($header{'Reply-To'});
:	($address, $friendly) = &'parse_address($from);
:	$login = &'login_name($address);
:	@to = split(/,/, $to);
:	@cc = split(/,/, $cc);
:	@relayed = split(/,\s*/, $header{'Relayed'});
:	# Leave only the address part in @to and @cc
:	grep(($_ = (&'parse_address($_))[0], 0), @to);
:	grep(($_ = (&'parse_address($_))[0], 0), @cc);
EOP
	eval(<<EOP);				# Initialize variables inside package
	package $package;
	$init
EOP
}

# Load hook script and run it
sub hook'run {
	local($hook) = @_;
	open(HOOK, $hook) || &'fatal("cannot open $hook: $!");
	local($body) = ' ' x (-s HOOK);
	{
		local($/) = undef;
		$body = <HOOK>;			# Slurp whole file
	}
	close(HOOK);
	unshift(@INC, $'privlib);	# Files first searched for in mailagent's lib
	eval $body;					# Load, compile and execute within mailhook
	if (chop($@)) {
		$@ =~ s/ in file \(eval\)//;
		&'add_log("ERROR $@") if $'loglvl;
		die("$hook aborted");
	}
}

package main;

