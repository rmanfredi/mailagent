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
;# $Log: power.pl,v $
;# Revision 3.0  1993/11/29  13:49:08  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Power manipulation package. Each power is stored in the 'passwd' file and
;# is protected by a password. Additionally, a list of authorized e-mail
;# addresses is stored in 'powedir'. When the power name is longer than 12
;# characters, it is aliased in the 'powerlist' file. This is to ensure that
;# no filesystem limit will get into the way, ever (2 characters are reserved
;# at the end for temporary backup, hence the limit fixed to 12).
;#
#
# Power control
#

package power;

# Grant power to user, returning 1 if ok, 0 if failed.
sub grant {
	local($name, $clear_passwd, $user) = @_;
	unless (&'file_secure($cf'passwd, 'password')) {
		&add_log("WARNING cannot grant power '$name'") if $'loglvl > 5;
		return 0;		# Failed
	}
	unless (&valid($name, $clear_passwd)) {
		&add_log("ERROR user '$user' gave invalid password for power '$name'")
			if $'loglvl > 1;
		return 0;		# Power not granted
	}
	unless (&authorized($name, $user)) {
		&add_log("ERROR user '$user' may not request power '$name'")
			if $'loglvl > 1;
		return 0;		# Power not granted
	}
	1;			# Power may be granted
}

# Check whether user is authorized to get this power or change its password.
# Returns 1 if user may proceed, 0 otherwise.
sub authorized {
	local($name, $user) = @_;
	local($auth) = &authfile($name);
	unless (&'file_secure($auth, 'authentication')) {
		&add_log("WARNING cannot authenticate power '$name'") if $'loglvl > 5;
		return 0;		# Failed
	}
	unless (open(AUTH, $auth)) {
		&add_log("ERROR cannot open auth file $auth for power '$name': $!")
			if $'loglvl > 1;
		return 0;		# Cannot verify identity -> cannot grant power
	}
	local($_);
	local($ok) = 0;
	study $user;				# Various searches will be attempted
	while (<AUTH>) {
		chop;
		$_ = &'perl_pattern($_);	# Shell style patterns may be used
		if ($user =~ /^$_$/) {		# User may request for this power
			$ok = 1;				# Ok, we found him
			last;
		}
	}
	close(AUTH);
	$ok;			# Boolean status
}

# Check whether a power password is valid or not. Returns 0 if password is
# invalid or the power is undefined, 1 when password is ok.
sub valid {
	local($name, $clear_passwd) = @_;
	unless (&'file_secure($cf'passwd, 'password')) {
		&add_log("WARNING cannot verify password for power '$name'")
			if $'loglvl > 5;
		return 0;		# Failed
	}
	local($power, $passwd, $comment) = &getpwent($name);
	return 0 unless defined $power;			# Unknown power -> illegal password
	if ($passwd =~ s/^<(.*)>$/$1/) {		# Password given as <clear>
		$clear_passwd eq $passwd;
	} else {								# Password encrypted
		crypt($clear_passwd, $passwd) eq $passwd;
	}
}

#
# Power aliases
#

# Compute file name where list of authorized users is kept.
sub authfile {
	local($name) = @_;
	return $cf'powerdir . "/$name" if length($name) <= 12;
	unless (open(ALIASES, $cf'powerlist)) {
		&add_log("ERROR cannot open power list $cf'powerlist: $!")
			if $'loglvl > 1;
		return '/dev/null';
	}
	local($_);
	local($power, $alias);
	while (<ALIASES>) {
		($power, $alias) = split(' ');
		if ($power eq $name) {
			close ALIASES;
			return $cf'powerdir . "/$alias"
		}
	}
	close ALIASES;
	return '/dev/null';
}

# Set clearance file, returning 1 for success, 0 for failure
sub set_auth {
	local($name, *text) = @_;
	local($file) = &authfile($name);
	if (-e $file) {
		unless (unlink $file) {
			&add_log("SYSERR unlink: $!") if $'loglvl;
			&add_log("WARNING appending to $file (should have replaced it)")
				if $'loglvl > 5;
		}
	}
	local($ok) =
		&'file_edit($file, 'power clearance', undef, join("\n", @text));
	$ok;
}

# Append users to clearance file, returning 1 on success and 0 on failure
sub add_auth {
	local($name, *text) = @_;
	local($file) = &authfile($name);
	local($ok) =
		&'file_edit($file, 'power clearance', undef, join("\n", @text));
	$ok;
}

# Remove users from clearance file, returning 1 on success and 0 on failure
sub rem_auth {
	local($name, *text) = @_;
	local($file) = &authfile($name);
	local(@pairs);	# Search/replace pairs for file_edit
	foreach $addr (@text) {
		push(@pairs, $addr, undef);
	}
	local($ok) = &'file_edit($file, 'power clearance', @pairs);
	$ok;
}

# Is alias already used?
sub used_alias {
	local($alias) = @_;
	open(ALIAS, $cf'powerlist) || return 0;
	local($_);
	local($pow, $ali);
	local($found) = 0;
	while (<ALIAS>) {
		($pow, $ali) = split(' ');
		$found = 1 if $ali eq $alias;
		last if $found;
	}
	close ALIAS;
	$found;		# Return true when alias already used
}

# Add new power alias, returning 1 for ok and 0 for failure.
sub add_alias {
	local($power, $alias) = @_;
	local($ok) =
		&'file_edit($cf'powerlist, 'power aliases', undef, "$power $alias");
	&add_log("aliased power '$power' into '$alias'") if $'loglvl > 6 && $ok;
	$ok;
}

# Delete power from alias file, returning 1 for ok and 0 for failure.
sub del_alias {
	local($power) = @_;
	local($ok) =
		&'file_edit($cf'powerlist, 'power aliases', "/^$power\\s/", undef);
	&add_log("ERROR cannot delete power '$power' from aliases")
		if $'loglvl > 1 && !$ok;
	&add_log("deleted power '$power' from aliases")
		if $'loglvl > 6 && $ok;
	$ok;
}

#
# Setting password information
#

# Set power password, returning 0 if ok, -1 for failure
sub set_passwd {
	local($name, $clear_newpasswd) = @_;

	# Make sure entry already exists (i.e. power is defined)
	local($power, $passwd, $comment) = &getpwent($name);
	return -1 unless defined $power;		# Unknown power

	# Choose a salt randomly, using the two lowest bytes of current time stamp
	local($t) = time;
	local($c1, $c2) = ($t, $t & 0xffff);
	$c1 -= ($t & 0xff) * ($c2 + (($t & 0xffff0000) >> 16));
	$c1 = $c1 > 0 ? $c1 : -$c1;
	local(@saltset) = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '/');
	local($salt) = $saltset[$c1 % @saltset] . $saltset[$c2 % @saltset];
	$passwd = crypt($clear_newpasswd, $salt);

	# Set new password entry
	&setpwent($power, $passwd, $comment);	# Propagate status
}

# Get password entry, and return ($power, $password, $comment) if found or
# undef if error or not found.
sub getpwent {
	local($wanted) = @_;		# Power entry wanted
	unless (open(PASSWD, "$cf'passwd")) {
		&add_log("ERROR cannot open password file: $!") if $'loglvl;
		return undef;
	}
	local($power, $password, $comment);
	local($_);
	while (<PASSWD>) {
		chop;
		($power, $password, $comment) = split(/:/);
		if ($power eq $wanted) {
			close PASSWD;
			return ($power, $password, $comment);
		}
	}
	close PASSWD;
	undef;			# Not found
}

# Set password entry, given ($power, $password, $comment) and return 0 for
# success, -1 on failure.
sub setpwent {
	local($power, $password, $comment) = @_;
	local($ok) = &'file_edit(
		$cf'passwd, 'password',
		"?^$power:?", "$power:$password:$comment"
	);
	&add_log("ERROR cannot set new password entry for '$power'")
		if $'loglvl > 1 && !$ok;
	$ok ? 0 : -1;
}

# Remove passoword entry, returning 0 for success and -1 on failure.
sub rempwent {
	local($power) = @_;
	local($ok) = &'file_edit(
		$cf'passwd, 'password',
		"/^$power:/", undef
	);
	&add_log("ERROR cannot remove password entry for '$power'")
		if $'loglvl > 1 && !$ok;
	$ok ? 0 : -1;
}

#
# Logging control
#

# Replaces main'add_log by remapping to powerlog...
# Opens new user-defined logfile 'powerlog' to extract power-related
# messages there. If not defined in ~/.mailagent, messages will go to the
# default log file. A copy of the log message is kept there anyway.
sub add_log {
	local($msg) = @_;
	&usrlog'new('powerlog', $cf'powerlog, 'COPY') if $cf'powerlog;
	&'usr_log('powerlog', $msg);
}

package main;

