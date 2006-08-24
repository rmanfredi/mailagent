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
;# $Log: history.pl,v $
;# Revision 3.0.1.4  2001/03/13 13:14:32  ram
;# patch71: message ids are now cleaned-up via msgid_cleanup()
;#
;# Revision 3.0.1.3  1994/10/29  17:46:13  ram
;# patch20: now supports internet numbers in message IDs
;#
;# Revision 3.0.1.2  1994/09/22  14:22:10  ram
;# patch12: added escapes in regexp for perl5 support
;#
;# Revision 3.0.1.1  1994/01/26  09:32:54  ram
;# patch5: history can now handle distinct tags on messages
;#
;# Revision 3.0  1993/11/29  13:48:50  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
;# Handle the message history mechanism, which is used to reject duplicates.
;# Each message-id tag is stored in a file, along with a time-stamp (to enable
;# its removal after a given period.
;#
# Record the message ID of the current message and return 0 if the
# message was recorded for the first time or if there is no valid message ID.
# Return 1 if the message was already recorded, and hence was already seen.
# If tags are provided (string list of words, separated by commas), then
# information is only fetched/recorded for those tags.
sub history_tag {
	local($tags) = @_;
	local($msg_id) = $Header{'Message-Id'};		# Message-ID header

	# If there is no message ID, use the concatenation of date + from fields.
	if ($msg_id) {
		# Keep only the first ID stored within <> brackets, clean it up
		($msg_id) = $msg_id =~ m|(<[^>]*>)\s*|;
		&header'msgid_cleanup(\$msg_id);	# Requires <> in message ID
		$msg_id =~ s/^<//;					# Remove leading "<"
		chop($msg_id);						# and trailing ">"
	} else {
		# Use date + from iff there is a date. We cannot use the from field
		# alone, obviously!! We also have to ensure there is an '@' in the
		# message id, which is the case unless the address is in uucp form.
		$msg_id = $Header{'Date'};
		local($from, $comment) = &parse_address($Header{'From'});
		$from =~ s/^([\w-.]+)!([\w-.]+)/\@$1:$2/;	# host!user -> @host:user
		$msg_id .= '.' . $from if $msg_id;
	}
	$msg_id =~ s/\s+/./g;			# Suppress all spaces
	$msg_id =~ s/\(a\)/@/;			# X-400 gateways sometimes use (a) for @
	return 0 unless $msg_id;		# Cannot record message without an ID

	# Hashing of the message ID is done based on the two first letters of
	# the host name (assuming message ID has the form whatever@host or
	# whatever@[internet.number]).
	local($stamp, $host) = $msg_id =~ m|^(.*)@([.\w]+)|;
	($stamp, $host) = $msg_id =~ m|^(.*)@\[([.\d]+)\]| unless $stamp;
	unless ($stamp) {
		&add_log("WARNING incorrect message ID <$msg_id>") if $loglvl > 5;
		return 0;					# Cannot record message if invalid ID
	}

	# Compute a tag array. If no tag given, insert a null tag so that we
	# enter the loop below anyway.

	$tags =~ s/\s+//g;
	local(@tags) = split(/,+/, $tags);
	push(@tags, '') unless @tags;

	# Now loop for each tag given. We record the message ID stamp followed
	# by a tab, then the tag between <>. If no tag is given, we look for any
	# occurence.

	local($time, $line);			# Time stamp, line number of DBR entry
	local(@regexp);					# DBR regular expression lookup
	local($seen) = 0;				# Assume new instance
	
	foreach $tag (@tags) {
		@regexp = ($stamp);
		push(@regexp, "<$tag>") if $tag ne '';
		($time, $line) = &dbr'info($host, 'HISTORY', @regexp);
		if ($time == -1) {			# An error occurred
			&add_log("ERROR while dbr-looking for '@regexp'") if $loglvl > 1;
			next;
		}
		if ($time > 0) {			# Message already recorded
			local($tagmsg) = $tag eq '' ? '' : " ($tag)";
			&add_log("history duplicate <$msg_id>" . $tagmsg) if $loglvl > 6;
			$seen++;
		} else {					# Record message (appending)
			&dbr'update($host, 'HISTORY', 0, @regexp);
		}
	}
	return $seen;					# Return seen status
}

# Obsolete -- will be removed in next release
sub history_record {
	&history_tag();
}

