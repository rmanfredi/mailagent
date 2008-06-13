;# $Id$
;#
;#  Copyright (c) 2008, Raphael Manfredi
;#  
;#  You may redistribute only under the terms of the Artistic License,
;#  as specified in the README file that comes with the distribution.
;#  You may reuse parts of this distribution only within the terms of
;#  that same Artistic License; a copy of which may be found at the root
;#  of the source tree for mailagent 3.0.
;#
package qp;

#
# Simple quoted-printable encoder/decoder.
#

# Reset the encoder/decoder
# Must be called before invoking encode() or decode().
# Once called, one must ONLY invoke encode() or decode() but never intermix
# calls to these two routines.  To switch, one must invoke reset() again.
sub reset {
	my ($len) = @_;
	my $data = " " x ($len || 64 * 1024);	# pre-extend
	$data = "";
	$output = \$data;
	$offset = 0;
	undef $error;
	undef $op;
}

# Decode new line from the quoted-printable stream
# Invoke as many times as necessary, until the end of the stream is reached.
# Call output() to actually fetch the decoded string.
sub decode {
	local ($_) = @_;
	return if defined $error;		# Stop as soon as an error occurred
	$op = "d" unless defined $op;
	if ($op ne "d") {
		$error = "mixed decode() within encode() calls";
		return;
	}
	my $soft = 0;
	s/[ \t]+$//;					# Trailing white spaces
	$soft = 1 if s/^=$//;			# Soft line break
	$soft = 1 if s/([^=])=$/$1/;	# Soft line break, but not for trailing ==
	s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
	$$output .= $_;
	$$output .= "\n" unless $soft;
	$offset += length($_);
}

# Encode new line into the base64 stream
# Invoke as many times as necessary, until the end of the stream is reached.
# Call output() to actually fetch the encoded string.
sub encode {
	local ($_) = @_;
	return if defined $error;		# Stop as soon as an error occurred
	$op = "e" unless defined $op;
	if ($op ne "e") {
		$error = "mixed encode() within decode() calls";
		return;
	}
	s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/
		sprintf("=%02X", ord($1))/eg;
	# Trailing white space must be encoded or will be stripped at decode time
	s/([ \t]+)$/join('', map { sprintf("=%02X", ord($_)) } split('', $1))/egm;

	# Ensure lines are smaller than 76 chars
	# No one-liner here as we cannot break up =xx escapes!
	# The trick is to break after 73 chars (76 - 3) and then add 1 or 2 chars
	# if they are not '=', thereby ensuring we're not breaking up in the
	# middle of a sequence.

	while (length($_) >= 76) {
		my $str = substr($_, 0, 73);
		s/^.{73}//;
		$str .= $1 if substr($_, 0, 1) ne "=" && s/^(.)//;
		$str .= $1 if substr($_, 0, 1) ne "=" && s/^(.)//;
		$$output .= "$str=\n";
	}
	$$output .= $_ . "\n" if length $_;

	$offset += length $_;
}

# Return a reference to the output of the encoded/decoded base64 stream
sub output {
	return $output unless defined $op;	# Neither encode() nor decode() called
	if ($op eq 'd') {
		# Nothing to be done
	} elsif ($op eq 'e') {
		$$output .= "\n" unless $$output =~ /\n$/s;
	} else {
		&'add_log("ERROR unknown quoted-printable operation '$op'") if $'loglvl;
	}
	return $output;
}

# Check whether output is valid so far
sub is_valid {
	return defined($error) ? 0 : 1;
}

# Generate error message for non-valid base64
sub error_msg {
	return "" unless defined $error;
	return "$error at offset $offset";
}

package main;

