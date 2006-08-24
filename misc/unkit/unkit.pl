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
# $Log: unkit.pl,v $
# Revision 3.0.1.2  1995/01/03  18:22:55  ram
# patch24: now uses cf'email for the notification address
# patch24: fixed a typo in sv_kfrom variable spelling
#
# Revision 3.0.1.1  1994/04/25  15:26:37  ram
# patch7: make sure unkit directory is not hidden by leading dot
#
# Revision 3.0  1993/11/29  13:50:34  ram
# Baseline for mailagent 3.0 netwide release.
#

# This command automatically stores kit parts aside and runs unkit when all
# the kits have been received.
# Returns success if the file has been successfully stored onto disk, and a
# failure if the mail was not a kit part or could not be saved.
# The following (optional) config variables are used (~/.mailagent):
#
#  x_unkit_dir    : ~/tmp/unkit    # Directory where UNKIT works (default ~/kit)
#  x_unkit_remove : YES            # Remove temporary files upon exctraction
#  x_unkit_pname  : .kpart         # Leading temporary file name (default .kp)
#  x_unkit_opt    : -b             # Additional unkit option
#  x_unkit_log    : kitlog         # Logfile for UNKIT actions
#  x_unkit_notify : ~/mail/kitok   # Message to be sent when kit received
#  x_unkit_info   : README         # File name for kit-embeded instructions
#
# Not done yet but wanted:
#  x_unkit_sizemax: 1000000        # Do not automatically unkit past this size
#  x_unkit_timeout: 3d             # Timeout before discarding (3 days)
#  x_unkit_output : YES            # Do we want any output mailed back if ok?
#  x_unkit_trust  : ~/mail/trust   # Trusted people list (regexp form)
#
# The notify message recognizes the traditional mailagent set of macros, plus
# the following specific ones:
#
#  %-(name)   : kit name of the package received (from Subject: line)
#  %-(parts)  : number of parts received
#  %-(kitdir) : directory where files for this kit are stored
#
# Some reasonable defaults are hardwired within the command itself.
#
# BUGS:
#
# Will not save instructions embeded in each part, only when made separate as
# part #0. Moreover, if that information file arrives after all the other
# "real" parts, it will be silently saved and .frm and .cnt files will be
# recreated... That's a minor problem though.
#

sub unkit {
	local($cmd_line) = @_;			# The filter command line

	# Options currently available at the ~/.mailagent level
	local($kitdir) = $cf'x_unkit_dir || "$cf'home/kit";
	local($remove) = $cf'x_unkit_remove =~ /^y/i;
	local($sizemax) = $cf'x_unkit_sizemax || 0;
	local($timeout) = $cf'x_unkit_timeout || '0d';
	local($info) = $cf'x_unkit_info || 'INFO';
	local($kl) = 'kitlog';

	# If special logfile must be used, then open it right now. Otherwise,
	# logs will be redirected to agentlog. The 'kitlog' logfile (that's the
	# user-level name, which has "no" link to the x_unkit_log name specified)
	# does not cc to the 'default' log agentlog.

	&usrlog'new($kl, "$cf'x_unkit_log", 0)
		if $cf'x_unkit_log ne '';

	# Make sure it is a standard kit subject, otherwise reject mail message
	# immediately. Standard subjects follow this template:
	# Subject: package name - kit #5 / 7

	local($name, $part, $total) = $subject =~ m|^(.*) - kit #(\d+) / (\d+)\s*$|;
	if ($name ne '') {
		&'usr_log($kl, "receiving $subject") if $'loglvl > 6;
	} else {
		&'usr_log($kl, "ERROR bad subject line: $subject") if $'loglvl > 1;
		return 1;			# Signal failure
	}

	local($pname) = $cf'x_unkit_pname || '.kp';
	local($options) = $cf'x_unkit_opt;
	local($origname) = $name;	# Save name before mangling into 14 chars

	# Escape all spaces in name, transforming them into '.'. Keep only the
	# first 14 characters and use that as a directory name.

	$name =~ s/^\s+//;		# Strip leading spaces
	$name =~ s/\s+$//;		# Strip trailing spaces
	$name =~ s/\s+/./g;		# Escape all other spaces
	$name =~ s|/$||g;		# Remove trailing /
	$name =~ s|/|_|g;		# And transform all others into _
	$name =~ s/^\.+//;		# Avoid hidden directories
	$name = substr($name, 0, 14) if length($name) > 14;

	$kitdir .= "/$name";	# Directory where unkit will proceed
	&'makedir($kitdir);		# Make directory if it does not exist

	# Problem: we have to make sure there is no alien code in the directory.
	# If we were to receive to kits labelled the same way (say 'doc'), we must
	# not mix them in the same directory. The heuristic used here is not 100%
	# reliable, but at least will not lead to irreversible mixups:
	#
	# Temporaries are stored in a file 'kp.005' for part #5, and a count
	# of the parts already received is kept in 'kp.cnt'. A track of the total
	# amount of kits to be received is stored in 'kp.max' and the From: line
	# is stored in 'kp.frm'. If we receive a kit from someone else (as computed
	# by kp.frm) or we receive some kit with a different part count, we reject
	# it.

	$pname = substr($pname, 0, 10) if length($pname) > 10;
	local($folder) = $kitdir . "/$pname" . sprintf(".%.3d", $part);
	$folder = "$kitdir/$info" if $part == 0;	# Part zero is info file

	# Compute kp.max and kp.frm if they do not exist already or check if they
	# do. It is not really needed to make sure those files are created correctly
	# since the next time we'll receive a kit part, we will fail anyway if they
	# are not consistent. However, not being able to create them is an obvious
	# error we are catching immediately.

	local($kmax) = "$kitdir/$pname.max";
	local($kfrom) = "$kitdir/$pname.frm";

	if (-f $kmax) {
		local($sv_kmax, $sv_kfrom);
		open(KMAX, $kmax);
		chop($sv_kmax = <KMAX>);
		close KMAX;
		open(KFROM, $kfrom);
		chop($sv_kfrom = <KFROM>);
		close KFROM;
		if ($total != $sv_kmax) {
			&'usr_log($kl, "ERROR kit $name had $sv_kmax parts, now has $total")
				if $'loglvl > 1;
			return 1;
		}
		if ($from ne $sv_kfrom) {
			&'usr_log($kl, "ERROR kit $name was from $sv_kfrom, now from $from")
				if $'loglvl > 1;
			return 1;
		}
	} else {
		unless (open(KMAX, ">$kmax")) {
			&'usr_log($kl, "ERROR cannot create $kmax: $!") if $'loglvl;
			return 1;
		}
		print KMAX "$total\n";
		close KMAX;
		unless (open(KFROM, ">$kfrom")) {
			&'usr_log($kl, "ERROR cannot create $kfrom: $!") if $'loglvl;
			return 1;
		}
		print KFROM "$from\n";
		close KFROM;
	}

	# Make sure there are no duplicates...
	if (-f $folder) {
		&'usr_log($kl, "WARNING duplicate part #$part for kit $name discarded")
			if $'loglvl > 5;
		return 1;			# Signal failure
	}

	# Call the SAVE mailagent routine via the mailhook interface, which return
	# a success status, i.e. 0 for failure and 1 if ok.
	unless (&mailhook'save($folder)) {
		&'usr_log($kl, "ERROR cannot save part #$part for kit $name")
			if $'loglvl > 1;
		return 1;
	}

	return 0 if $part == 0;		# Information file does not count...

	# Now increase number of received parts
	local($received) = &unkit'one_more($kitdir, $pname);
	return 0 if $received < $total;		# Some parts still missing

	# Everything was received, run unkit. Make sure the PATH variable is
	# correctly set by your ~/.mailagent.
	unless (opendir(DIR, $kitdir)) {
		&'usr_log($kl, "ERROR (unkit) cannot open directory $kitdir: $!")
			if $'loglvl > 1;
		&unkit'error;
		return 0;						# Not really an UNKIT error
	}
	local(@contents) = readdir DIR;		# Slurp the whole thing
	close DIR;
	@contents = grep(/^$pname\.\d+$/, @contents);

	# Time to actually run unkit... Its output will be mailed back to the user.

	if (0 == &main'shell_command(
		"unkit $option -Sd $kitdir @contents",
		$'NO_INPUT, $'NO_FEEDBACK)
	) {
		&'usr_log($kl, "OK kit $name left in dir $kitdir") if $'loglvl > 2;
		if (chdir $kitdir) {
			unlink "$pname.cnt";			# Unlink kit count anyway
			unlink @contents if $remove;	# Remove parts if unkit successful
		} else {
			&'usr_log($kl, "WARNING cannot chdir to $kitdir to cleanup: $!")
				if $'loglvl > 5;
		}

		# Send mail to user if x_unkit_notify option is set. Special macros
		# needed by the UNKIT context are first declared before calling the
		# NOTIFY function via the perl interface.

		&usrmac'push('name', $origname, 'SCALAR');
		&usrmac'push('parts', $total, 'SCALAR');
		&usrmac'push('kitdir', $kitdir, 'SCALAR');

		&mailhook'notify($cf'x_unkit_notify, $cf'email) if $cf'x_unkit_notify;
		
		&usrmac'pop('name');
		&usrmac'pop('parts');
		&usrmac'pop('kitdir');

	} else {
		&'usr_log($kl, "FAILED unkit returned non-zero status") if $'loglvl > 1;
		&unkit'error;
	}
	
	0;		# If we came here, then no error can really be reported
}

# Maintain an accurate count of the parts received sofar. Return the actual
# number of parts we got.
sub unkit'one_more {
	local($dir, $name) = @_;	# Dirname, basename for parts
	local($file) = $dir . "/$name.cnt";
	local($count) = 0;			# Actual number of files
	if (-1 == &main'acs_rqst($file)) {
		&'usr_log($kl, "WARNING cannot lock $file") if $'loglvl > 5;
	}
	if (-f $file) {				# Already a count
		open(COUNT, "$file");
		$count = int(<COUNT>);
		close COUNT;
	}
	$count++;
	unless (open(COUNT, ">$file")) {
		&'usr_log($kl, "ERROR cannot create $file: $!") if $'loglvl > 1;
	}
	local($error) = 0;
	(print COUNT "$count\n") || ($error++);
	close(COUNT) || ($error++);
	if ($error) {
		&'usr_log($kl, "ERROR cannot update file count (now $count)")
			if $'loglvl > 1;
	}
	&main'free_file($file);
	$count;						# Return new count
}

# Report error in unkiting process
sub unkit'error {
	&'usr_log($kl, "ERROR package $name left unkited in $kitdir")
		if $'loglvl > 1;
}

