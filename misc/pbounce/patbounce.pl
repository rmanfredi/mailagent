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
# $Log: patbounce.pl,v $
# Revision 3.0.1.3  1997/09/15  15:20:33  ram
# patch57: also handle bounced output from @SH package
#
# Revision 3.0.1.2  1997/01/07  18:37:43  ram
# patch52: strip out trailing > on addresses, since matching is greedy
#
# Revision 3.0.1.1  1996/12/26  10:47:38  ram
# patch51: created
#

# This command automatically handles bounce error messages resulting from
# massive mailing via patnotify and patsend.
#
# It scans the message and tries to figure out the failing address, if any.
# If found, it attempts to figure out the package name and version number,
# and sends the 'package ... badaddress' Command mail to remove this
# address from further massive mailings.
#
# Returns success if we were able to figure out the necessary information
# to send the Command message, a failure otherwise, whith the message being
# saved for further inspection (to figure out why we could not handle it).
#
# The following (optional) config variables are used (~/.mailagent):
#
#  x_pbounce_bad  : +pbad 		# Folder where unknown error messages are saved
#  x_pbounce_ok   : +pok 		# Folder where processed messages are saved
#  x_pbounce_save : OFF 		# Save in $x_pbounce_ok after good handling?
#  x_pbounce_log  : badlog		# Where PATBOUNCE logs what it does
#
# Some reasonable defaults are hardwired within the command itself.

sub patbounce {
	local($cmd_line) = @_;			# The filter command line

	# Options currently available at the ~/.mailagent level
	local($badfolder) = $cf'x_pbounce_bad || 'pbad';
	local($okfolder) = $cf'x_pbounce_ok || 'pok';
	local($autosave) = $cf'x_pbounce_save =~ /^on/i;
	local($bl) = 'patbounce';

	# If special logfile must be used, then open it right now. Otherwise,
	# logs will be redirected to agentlog. The 'patbounce' logfile (that's the
	# user-level name, which has "no" link to the x_pbounce_log name specified)
	# does not cc to the 'default' log agentlog.

	&usrlog'new($bl, "$cf'x_pbounce_log", 0)
		if $cf'x_pbounce_log ne '';

	local($via);
	$via = " (via $envelope)" if $envelope ne $address;
	&'usr_log($bl, "bounce message from $address$via");

	# Determine the failing address by looking at SMTP failure reports.
	local($failing) = &pbounce_failaddr;

	# If we are unable to guess the failing address, annotate the message
	# and save it in the bad folder, then return a failure status.
	unless ($failing ne '') {
		&'usr_log($bl, "WARNING cannot determine failing address")
			if $'loglvl > 5;
		&pbounce_error('No failing address found');
		return 1;	# Failed
	}

	# Determine target package and version by looking at the embeded subject.
	local($package, $version) = &pbounce_package;

	unless ($package ne '' && $version ne '') {
		&'usr_log($bl, "only got package = $package")
			if $'loglvl > 5 && $package ne '';
		&'usr_log($bl, "only got version = $version")
			if $'loglvl > 5 && $version ne '';
		&'usr_log($bl, "WARNING cannot determine target package")
			if $'loglvl > 5;
		&pbounce_error('No package/version found');
		return 1;	# Failed
	}

	&'usr_log($bl, "bad address $failing ($package $version user)")
		if $'loglvl > 6;

	# Send Command message to the user running mailagent
	local(*MAILER);
	unless (open(MAILER, "|$cf'sendmail $cf'mailopt $cf'email")) {
		&'usr_log($bl, "SYSERR fork: $!") if $'loglvl;
		&'usr_log($bl, "ERROR no mail sent for $failing ($package $version)")
			if $'loglvl;
		&pbounce_error('No Command mail sent (cannot fork)');
		return 1;	# Failed
	}

	print MAILER <<EOM;
To: $cf'email
Subject: Command

\@SH package $failing $package $version - badaddress

-- mailagent speaking for $cf'user (via PATBOUNCE)
EOM
	close MAILER;
	if ($?) {
		&'usr_log($bl, "ERROR no mail sent for $failing ($package $version)")
			if $'loglvl;
		&pbounce_error('No Command mail sent (sendmail error)');
		return 1;	# Failed
	} else {
		&'usr_log($bl,
			"SENT \@SH package $failing $package $version - badaddress")
			if $'loglvl > 2;
	}

	# Save message in OK folder, only when told to do so
	if ($autosave && ! &mailhook'save($okfolder)) {
		&'usr_log($bl, "ERROR cannot save message in $okfolder")
			if $'loglvl > 1;
	}

	0;		# If we came here, we did fine!
}

#
# pbounce_failaddr
#
# Determine the failing address by looking at SMTP failure reports.
# We handle the following cases:
#
# 550 <pauck@rs3.wmd.de>... Host unknown
# 550 pauck@rs3.wmd.de... Host unknown
# 550 ek@kiddy.mmc.co.jp.JIS... Host unknown
#
# >>> RCPT To:<august@gaea.synopsys.com>
# 554 august@bouncer... Service unavailable
#
# 550 0 glm@unify.com... User unknown
# 500 0 <glm@gilligan.unify.unify.com>... Bad usage
#
# 501 <root@minerva.nissho-ele.co.jp>...  550 Host unknown
#
# SMTP <sebas@noc.noc.unam.mx>
#
# Returns the failing address, or undef if none found.
#
sub pbounce_failaddr {
	local($addr);
	local($*) = 1;
	if ($header{'Body'} =~ /^5\d\d\s+(\d+\s+)?<?(\S+)>?\.\.\.\s/) {
		$addr = $2;
		$addr =~ s/>$//g;
		$addr =~ s/\.JIS$//;	# Remove trailing .JIS indication
		# If the name is not fully qualified at this point, parse RCPT
		unless ($addr =~ /\.\w{2,4}$/) {
			$addr = $1 if $header{'Body'} =~ /^>>>\s+RCPT\s+To:\s*<?(\S+)>?/;
		}
	} else {
		$addr = $1 if $header{'Body'} =~ /^SMTP\s+<?(\S+)>?/;
	}
	$addr =~ s/>$//g;
	return $addr;
}

#
# pbounce_package
#
# Dertmine package and version number of this bounce notification. We look
# within the body of the message for the following subject lines:
#
# Subject: Patches 45 thru 50 for mailagent version 3.0 have been released.
# Subject: Patch 42 for mailagent version 3.0 has been released.
# Subject: mailagent 3.0 patch #45
#
# If the above fail, then it may be an "@SH package" command that failed.
# They requested 'mailpatches' or 'notifypatches' and our reply to them
# failed miserably. Look for:
#
#	package xxx@yyy mailagent 3.0 ...
#
# Returns ($package, $version) or an empty array if we can't figure it out.
#
sub pbounce_package {
	local($*) = 1;
	return ($1, $2) if $header{'Body'} =~
		/^Subject:\s+Patch.*for\s+([\w-]+)\s+version\s+([\d.]+)/;
	return ($1, $2) if $header{'Body'} =~
		/^Subject:\s+([\w-]+)\s+([\d.]+)\s+patch #\d+/;
	return ($1, $2) if $header{'Body'} =~
		/^\s+package\s+\S+\s+([\w-]+)\s+([\d.]+)/;
	return ();
}

#
# pbounce_error
#
# Annotate error and save in bad folder.
#
sub pbounce_error {
	local($error) = @_;
	&mailhook'annotate('-d', 'X-Patbounce', $error);
	unless (&mailhook'save($badfolder)) {
		&'usr_log($bl, "ERROR cannot save message in $badfolder")
			if $'loglvl > 1;
	}
}

