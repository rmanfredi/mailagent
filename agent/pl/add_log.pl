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
;# $Log: add_log.pl,v $
;# Revision 3.0.1.3  1999/01/13  18:12:37  ram
;# patch64: only use last two digits from year in logfiles
;#
;# Revision 3.0.1.2  1995/02/16  14:33:04  ram
;# patch32: new routine stdout_log for -I switch usage
;#
;# Revision 3.0.1.1  1994/09/22  14:08:11  ram
;# patch12: now escapes square brackets in strings for perl5
;#
;# Revision 3.0  1993/11/29  13:48:34  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# Logging facilities. Normally, logs are appended into the agentlog file by
;# a call to &add_log. For plain mailagent actions, this is fine. However,
;# when user-defined commands are run or when the generic server is used, it
;# could be desirable to write the logs to some other file.
;#
;# Therefore, this package provides a generic logging interface (usr_log) while
;# keeping the previous add_log routine for backward compatibility. The user
;# may record alternative log files, with or without a copy to the global log.
;#
;# The following interface functions in the usrlog package are available:
;#
;#   . new(name, file, flag)
;#       records a log file. If flag is true, a copy to the main log
;#       is also written. The name parameter refers to the global name
;#       under which the log is known from now on. If an existing log file
;#       has already been defined under this name, nothing is done.
;#   . delete(name)
;#       deletes a log file by name.
;#
;# All files given as a relative path name (i.e. not starting with /) are
;# rooted in the 'logdir' directory as defined in the ~/.mailagent file.
;#
;# To log something, the user calls:
;#
;#   . usr_log(name, string)
;#
;# The logfile name 'default' is reserved to refer to the default system-wide
;# logfile. Trying to log something to a non-existent logfile will log to the
;# default logfile instead.
;#
# Add an entry to logfile
# There is no need to lock logfile as print is sandwiched betweeen
# an open and a close (kernel will flush at the end of the file).
sub add_log {
	# Indirection needed, so that we may remap add_log on stderr_log via a
	# type glob assignment.
	&usrlog'write_log($cf'logfile, $_[0], undef);
}

# When mailagent is used interactively, log messages are also printed on
# the standard error.
# NB: this function is not called directly, but via a type glob *add_log.
sub stderr_log {
	print STDERR "$prog_name: $_[0]\n";
	&usrlog'write_log($cf'logfile, $_[0], undef);
}

# Routine used to emit logs when no logging has been configured yet.
# As soon as a valid configuration has been loaded, logs will also be
# duplicated into the logfile. Used solely by &cf'setup.
# NB: this function is not called directly, but via a type glob *add_log.
sub stdout_log {
	print STDOUT "$prog_name: $_[0]\n";
	&usrlog'write_log($cf'logfile, $_[0], undef) if defined $cf'logfile;
}

#
# User-defined log files
#

package usrlog;

# Record a new logfile by storing its pathname in the %Logpath hash table
# indexed by names and the carbon-copy flag in the %Cc table.
sub new {
	local($name, $path, $cc) = @_;
	return if defined $Logpath{$name};	# Logfile already recorded
	return if $name eq 'default';		# Cannot redefined defaul log
	$path = "$cf'logdir/$path" unless $path =~ m|^/|;
	$Logpath{$name} = $path;			# Where logfile should be stored
	$Cc{$name} = $cc ? 1 : 0;			# Should we cc the default logfile?
	$Map{$path} = $name;				# Two-way hash table
}

# Delete user-defined logfile.
sub delete {
	local($name) = @_;
	return unless defined $Logpath{$name};
	local($path) = $Logpath{$name};
	delete $Logpath{$name};
	delete $Cc{$name};
	delete $Map{$path};
}

# User-level logging main entry point
sub main'usr_log {
	local($name, $message) = @_;	# Logfile name and message to be logged
	local($file);
	$file = ($name eq 'default' || !defined $Logpath{$name}) ?
		$cf'logfile : $Logpath{$name};
	&write_log($file, $message, $Cc{$name});
}

# Log message into logfile, using jobnum to identify process.
sub write_log {
	local($file, $msg, $cc) = @_;	# Logfile, message to be logged, cc flag
	local($date);
	local($log);

	return unless length $file;

	local ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
		localtime(time);
	$date = sprintf("%.2d/%.2d/%.2d %.2d:%.2d:%.2d",
		$year % 100,++$mon,$mday,$hour,$min,$sec);
	$log = $date . " $'prog_name\[$'jobnum\]: $msg\n";

	# If we cannot append to the logfile, first check whether it is the default
	# logfile or not. If it is not, then add a log entry to state the error in
	# the default log and then delete that user logname entry, assuming the
	# fault we get is of a permanent nature and not an NFS failure for instance.

	unless (open(LOGFILE, ">>$file")) {
		if ($file ne $cf'logfile) {
			local($name) = $Map{$file};	# Name under which it was registered
			&'add_log("ERROR cannot append to $name logfile $file: $!")
				if $'loglvl > 1;
			&'add_log("NOTICE removing logging to $file") if $'loglvl > 6;
			&delete($Map{$file});
			$cc = 1;				# Force logging to default file
		} else {					# We were already writing to default log
			return;					# Cannot log message at all
		}
	}

	print LOGFILE $log;
	close LOGFILE;

	# If $cc is set, a copy of the same log message (same time stamp guaranteed)
	# is made to the default logfile. If called with $file set to that default
	# logfile, $cc will be undef by construction.

	if ($cc) {
		open(LOGFILE, ">>$cf'logfile");
		print LOGFILE $log;
		close LOGFILE;
	}
}

package main;

