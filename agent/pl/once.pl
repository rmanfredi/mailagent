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
;# $Log: once.pl,v $
;# Revision 3.0.1.1  1994/09/22  14:28:42  ram
;# patch12: removed useless test which prevented correct processing
;#
;# Revision 3.0  1993/11/29  13:49:04  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Handling of the "once" directory for ONCE commands. A once command is
;# tagged with a tuple (name,ruletag). The name is used for hashing, and
;# the ruletag sepecifies the entry to be used by the command for timestamp
;# recording. The dbr package is used to maintain the database
;#
# Given a tuple (name, tag) and a period, make sure the command may be
# executed. If it can, update the timestamp and return true. false otherwise.
sub once_check {
	local($hname, $tag, $period) = @_;
	$hname =~ s/\s//g;					# There cannot be spaces in the name
	local($ok) = 1;						# Is once ok ?
	local($timestamp) = 0;				# Time stamp attached to entry
	local($linenum) = 0;				# Line where entry was found
	($timestamp, $linenum) = &dbr'info($hname, 'ONCE', $tag);
	return 0 if $timestamp == -1;		# An error occurred
	local($now) = time;					# Number of seconds since The Epoch
	if (($timestamp + $period) > $now) {
		&'add_log("we have to wait for ($hname, $tag)") if $'loglvl > 18;
		return 0;
	}
	# Now we know we can execute the command. So update the database entry.
	# If the timestamp is 0, then an append has to be done, otherwise it's
	# a single replacement.
	if ($timestamp > 0) {
		&dbr'update($hname, 'ONCE', $linenum, $tag);
	} else {
		&dbr'update($hname, 'ONCE', 0, $tag);
	}
	1;
}

