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
;# $Log: forward.pl,v $
;# Revision 3.0.1.1  1996/12/24  14:52:11  ram
;# patch45: created
;#
;#
;# The following is meant to apply to the following commands:
;#     maildist
;#     mailpatch
;#     package
;#
;# When the author of a package wishes to relinquish all maintenance duty, he
;# is most often stuck by the weight of the past: Configure scripts have his
;# e-mail address hardwired (see unit MailAuthor.U) and Command mails for
;# package registration and/or patch requests will continue to reach him.
;#
;# The "solution" is to leave a .forward file at the top of the package
;# tree and mailagent will automatically forge new requests and forward
;# them to the address listed in the .forward file. Now the recipient
;# surely needs a mailagent at the other end to deal with forwarded requests!
;#
;# Only plain e-mail address(es) are allowed in the .forward. The "|command"
;# processing hook is not supported. That's because interpretation of the
;# .forward file is not done by mailagent itself but rather by the underlying
;# command, which does not have all those powerful mailagent routines at its
;# disposal.
;#
;# This file relies on the following external conditions:
;#    - operation &clean_tmp() available to remove existing temporary files.
;#    - the configuration variables are properly set
;#    - logging is done via &add_log()
;#    - address checking is done via &addr'valid()
;#    - forking errors while launching sendmail are reported via &nofork
;#
#
# Find whether there is a .forward file and if there is, forge a new command
# mail and send it to the address(es) listed in this file, then exit.
# To forge the command message, we rely on the three global variables that
# should have been set from the environment passed by mailagent:
#
#   fullcmd: the shell command itself (without its leading @SH prefix)
#   pack   : the packing mode requested via @PACK (or default value)
#   path   : the path to be used to expand - addresses (@PATH or derived value)
#
# The recipient(s) will get a message which seems to come from us, but since
# there will be an explicit @PATH command and a leading message telling (in the
# body of the message itself) what has hapened, there should be no confusion
# possible. Automatic processing via mailagent of those forwarded requests is
# naturally possible transparently, without wondering about their origin.
#
# A note is sent to the originator of the command telling him his request has
# been forwarded, and to whom it was. That way, he may contact the other
# party if something wrong occurs.
sub check_forward {
	local(@addr) = &forward_list;
	return unless @addr;
	&add_log("NOTICE forwarding to @addr") if $loglvl > 6;
	local($es) = @addr == 1 ? '' : 'es';
	local($address) = join("\t\n", @addr);
	local(*MAIL);
	open(MAIL, "|$cf'sendmail $cf'mailopt $path $cf'email") || &nofork;
	print MAIL
"To: $path
Subject: Your command '$fullcmd' was forwarded
X-Mailer: mailagent [version $mversion PL$patchlevel]

You have sent $cf'email the following command:

	$fullcmd

It has been forwarded to the following address$es:

	$address

under the following (expanded) form:

	\@PATH $path
	\@PACK $pack
	\@SH $fullcmd

so that the remote end may interpret your command properly, if done
at all anyway.

-- $prog_name speaking for $cf'user
";
	close MAIL;
	if ($?) {
		&add_log("ERROR cannot notify $path about forwarding") if $loglvl;
	} else {
		&add_log("MSG forwarded to @addr") if $loglvl > 6;
	}
	local($addr) = join(", ", @addr);
	open(MAIL, "|$cf'sendmail $cf'mailopt @addr") || &nofork;
	print MAIL
"To: $addr
Subject: Command
X-Mailer: mailagent [version $mversion PL$patchlevel]

[Forwarded by $cf'email via mailagent $mversion PL$patchlevel]

\@PATH $path
\@PACK $pack
\@SH $fullcmd

-- $prog_name speaking for $cf'user
";
	close MAIL;
	if ($?) {
		&add_log("ERROR cannot forward command to @addr") if $loglvl;
	}

	# Final cleanup and exit
	&clean_tmp;
	exit 0;
}

# Returns the forwarding address list, or the empty list if none.
sub forward_list {
	return () unless -f '.forward';
	local(*FORWARD);
	unless (open(FORWARD, '.forward')) {
		&add_log("ERROR can't open .forward: $!") if $loglvl;
		return ();
	}
	local($_);
	local(@addr);
	push(@addr, split(/\s*,\s*/)) while chop($_ = <FORWARD>);
	close FORWARD;
	local(@valid);
	foreach $addr (@addr) {
		unless (&addr'valid($addr)) {
			&add_log("WARNING ignoring hostile forward address $addr")
				if $loglvl > 5;
			next;
		}
		push(@valid, $addr);
	}
	&add_log("WARNING empty forwarding address set!")
		if @valid == 0 && $loglvl > 5;
	return @valid;
}

