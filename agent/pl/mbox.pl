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
;# $Log: mbox.pl,v $
;# Revision 3.0  1993/11/29  13:49:01  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# This package enables the mailagent to incorporate mail from a UNIX-style
;# mailbox (i.e. those produced by standard mail utilities with a leading From
;# line stating sender and date) into the mailagent's queue. This will be
;# especially useful on those sites where users are not allowed to have a
;# .forward file. By using the -f option on the mailbox in /usr/spool/mail,
;# mail will be queued and filtered as if it had come from filter via .forward.
package mbox;

# Get mail from UNIX mailbox and queue each item
sub main'mbox_mail {
	local($mbox) = @_;			# Where mail is stored
	unless (open(MBOX, "$mbox")) {
		&'add_log("ERROR cannot open $mbox: $!") if $'loglvl > 1;
		return -1;				# Failed
	}
	local(@buffer);				# Buffer used for look-ahead
	local(@blanks);				# Trailing blank lines are ignored
	local(@mail);				# Where mail is stored
	while (<MBOX>) {
		chop;
		if (/^\s*$/ && 0 == @buffer) {
			push(@blanks, $_);
			next;				# Remove empty lines before end of mail
		}
		if (/^From\s/) {
			push(@buffer, $_);
			next;
		}
		if (@buffer > 0) {
			if (/^$/) {
				&flush(1);		# End of header
				push(@mail, $_);
				next;
			}
			if (/^[\w\-]+:/) {
				$last_was_header = 1;
				push(@buffer, $_);
				next;
			}
			if (/^\s/ && $last_was_header) {
				push(@buffer, $_);
				next;
			}
			&flush(0);			# Not a header
			push(@mail, $_);
			next;
		}
		&flush_blanks;
		push(@mail, $_);
	}
	close MBOX;
	&flush(1);			# Flush mail buffer at end of file
	&flush_buffer;		# Maybe header was incomplete?
	&'add_log("WARNING incomplete last mail discarded")
		if $'loglvl > 5 && @mail > 0;
	0;					# Ok (but there might have been some queue problems)
}

# Flush blanks into @mail
sub flush_blanks {
	return unless @blanks;
	foreach $blank (@blanks) {
		push(@mail, $blank);
	}
	@blanks = ();
}

# Flush look-ahead buffer into @mail
sub flush_buffer {
	return unless @buffer;
	foreach $buffer (@buffer) {
		push(@mail, $buffer);
	}
	@buffer = ();
}

# Flush mail buffer onto queue
sub flush {
	local($was_header) = @_;	# Did we reach a new header
	# NB: we don't have to worry if the very first mail does not have a From
	# line, as qmail will add a faked one if necessary.
	if ($was_header && @mail > 0) {
		&main'qmail(*mail);
		@mail = ();				# Reset mail buffer
	}
	&flush_buffer;				# Fill @mail with what we got so far in @buffer
	@blanks = ();				# Discard trailing blanks
}

package main;

