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
;# $Log: read_conf.pl,v $
;# Revision 3.0.1.11  2001/03/17 18:13:41  ram
;# patch72: computes suitable defaults for new "domain" and "hidenet"
;#
;# Revision 3.0.1.10  1997/01/07  18:33:25  ram
;# patch52: new execsafe variable defaults to OFF when missing
;#
;# Revision 3.0.1.9  1996/12/24  14:59:00  ram
;# patch45: default for locksafe is now OFF
;#
;# Revision 3.0.1.8  1995/09/15  14:04:08  ram
;# patch43: added suitable defaults for compspec, comptag and locksafe
;#
;# Revision 3.0.1.7  1995/08/07  16:21:43  ram
;# patch37: added comment explaining why mailboxes are locked with a .lock
;#
;# Revision 3.0.1.6  1995/01/25  15:27:51  ram
;# patch27: escape all @ in config file for perl 5.0
;#
;# Revision 3.0.1.5  1994/10/10  10:25:32  ram
;# patch19: variable mboxlock was systematically set to %f.lock
;# patch19: email setting relied on mailagent-specific &'email_addr
;#
;# Revision 3.0.1.4  1994/10/04  17:54:38  ram
;# patch17: added defaults for new email and mboxlock parameters
;# patch17: no longer add duplicates to the @INC array
;#
;# Revision 3.0.1.3  1994/09/22  14:34:51  ram
;# patch12: do not attempt parsing of config if variable is undefined
;#
;# Revision 3.0.1.2  1994/07/01  15:04:50  ram
;# patch8: set proper default values for new optional config variables
;#
;# Revision 3.0.1.1  1994/04/25  15:21:34  ram
;# patch7: made sure new variable 'fromesc' has a meaningful default
;#
;# Revision 3.0  1993/11/29  13:49:12  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
use Encode;

package cf;

# This package is responsible for keeping track of the configuration variables.

# Read configuration file (usually in ~/.mailagent)
sub main'read_config {
	local($file) = @_;				# where config file is located
	local($_);
	$file = '~/.mailagent' unless $file;
	local($myhome) = $ENV{'HOME'};	# must be correctly set by filter
	$file =~ s/~/$myhome/;			# ~ substitution
	local($main'config) = $file;	# Save it: could be modified by config
	open(CONFIG, "$file") ||
		&'fatal("can't open config file $file");
	local($config) = ' ' x 2000;	# pre-extend to avoid realloc()
	$config = '';
	while (<CONFIG>) {
		next if /^[ \t]*#/;			# skip comments
		next if /^[ \t]*\n/;		# skip empy lines
		s/([^\\](\\\\)*)@/$1\\@/g;	# escape all un-escaped @ in string
		$config .= $_;
	}
	&parse($config) || &'fatal('bad configuration');
	close CONFIG;

	# Security checks, pending of those performed by the C filter. They are
	# somewhat necessary, even though the mailagent does not run setuid
	# (because anybody may activate the mailagent for any user by sending him
	# a mail, and world writable configuration files makes the task too easy
	# for a potential hacker). The tests are performed once the configuration
	# file has been parsed, so logging of fatal errors may occur.

	local($unsecure) = 0;

	$unsecure++ unless &'file_secure($'config, 'config');
	$unsecure++ unless &'file_secure($rules, 'rule');
	&'fatal("unsecure configuration!") if $unsecure;

	return unless -f "$rules";		# No rule file
}

# Parse config file held in variable and return 1 if ok, 0 for errors
sub parse {
	local($config) = @_;
	return 1 unless defined $config;
	local($eval) = ' ' x 1000;		# Pre-extend
	local($myhome) = $ENV{'HOME'};	# must be correctly set by filter
	local($var, $value);
	local($_);
	$eval = '';
	foreach (split(/\n/, $config)) {
		if (/^[ \t]*([^ \t\n:\/]*)[ \t]*:[ \t]*([^#\n]*)/) {
			$var = $1;
			$value = $2;
			$value =~ s/\s*$//;						# remove trailing spaces
			$eval .= "\$$var = \"$value\";\n";
			$eval .= "\$$var =~ s|~|\$myhome|g;\n";	# ~ substitution
		}
	}
	eval $eval;			# evaluate configuration parameters within package

	if ($@ ne '') {				# Parsing error detected
		local($error) = $@;		# Logged error
		$error = (split(/\n/, $error))[0];		# Keep only first line
		# Dump error message on stderr, as well as faulty configuration file.
		# The original is restored out of the perl form to avoid surprise.
		$eval =~ s/^\$.* =~ s\|~\|.*\n//gm;		# Remove added ~ substitutions
		$eval =~ s/^\$//gm;						# Remove leading '$'
		$eval =~ s/ = "(.*)";/: $1/gm;			# Keep only variable value
		chop($eval);
		print STDERR <<EOM;
**** Syntax error in configuration:
$error

---- Begin of Faulty Configuration
$eval
---- End of Faulty Configuration

EOM
		&'add_log("syntax error in configuration: $error") if $'loglvl > 1;
		return 0;
	}

	# Define the mailagent parameters from those in config file
	$logfile = $logdir . "/$log";
	$seqfile = $spool . "/$seq";
	$hashdir = $spool . "/$hash";
	$main'loglvl = int($level);		# This one is visible in the main package
	$main'track_all = 1 if $track =~ /on/i;		# Option -t set by config
	$sendmail = $'mailer if $sendmail eq '';	# No sendmail program specified
	$sendnews = $'inews if $sendnews eq '';		# No news posting program
	$mailopt = '-odq -i' if $mailopt eq '' && $sendmail =~ /sendmail/;

	# Backward compatibility -- RAM, 25/04/94
	$fromesc = 'ON' unless defined $fromesc;	# If absent from ~/.mailagent
	$lockmax = 20 unless defined $lockmax;
	$lockdelay = 2 unless defined $lockdelay;
	$lockhold = 3600 unless defined $lockhold;
	$queuewait = 60 unless defined $queuewait;
	$queuehold = 1800 unless defined $queuehold;
	$queuelost = 86400 unless defined $queuelost;
	$runmax = 3600 unless defined $runmax;
	$umask = 077 unless defined $umask;
	$email = $user unless defined $email;
	$compspec = "$spool/compressors" unless defined $compspec;
	$comptag = 'gzip' unless defined $comptag;
	$locksafe = 'OFF' unless defined $locksafe;
	$execsafe = 'OFF' unless defined $execsafe;

	# For backward compatibility, we force a .lock locking on mailboxes.
	# For system ones (name = login), there's no problem because the lock
	# file is still under the 14 characters limit. If mail is saved in folders
	# whose name is longer, there might be problems though. There's little we
	# can do about it here, lest they choose an alternate locking name.
	# Note that mailagent's $lockext global variable setting depends on the
	# fact that the target system supports flexible filenames or not, so only
	# mailbox locking is a problem -- RAM, 18/07/95

	$mboxlock = '%f.lock' unless defined $mboxlock;

	# Backward compatibility -- RAM, 17/03/2001
	$domain = $main::hiddennet || $main::mydomain unless defined $domain;
	$hidenet = $main::hiddennet eq '' ? 'OFF' : 'ON' unless defined $hidenet;

	$umask = oct($umask) if $umask =~ /^0/;	 # Translate umask into decimal
	$domain =~ s/^\.*//;					 # Strip leading '.'

	# Backward compatibility -- RAM, 2016-09-13

	$biffchars = 'iso-8859-1' unless defined $biffchars;

	# Update @INC perlib search path with the perlib variable. Paths not
	# starting by a '/' are supposed to be under the mailagent private lib
	# directory.

	local(%seen);		# Avoid dups in @INC (might be called more than once)

	foreach (@INC) { $seen{$_}++; }

	if (defined $perlib) {
		foreach (split(':', $perlib)) {
			s/^~/$home/;
			$_ = $'privlib . '/' . $_ unless m|^/|;
			push(@INC, $_) unless $seen{$_}++;
		}
	}

	# Make sure the "biffchars" encoding is known if biff is set.

	if ($biff =~ /^on/i) {
		my $enc = Encode::find_encoding($biffchars);
		unless (ref $enc) {
			&'add_log("WARNING unknown biff charset '$biffchars', using latin1")
				if $'loglvl > 1;
			$biffchars = 'iso-8859-1';
		}
	}

	1;		# Ok
}

package main;

