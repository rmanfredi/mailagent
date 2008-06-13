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
package base64;

#
# Simple base64 encoder/decoder.
#

# Initialialize the base64 decoding values
sub init {
	@values = (
	   # 0  1  2  3  4  5  6  7  8  9          0123456789
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            -  00 ->  09
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            -  10 ->  19
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            -  20 ->  29
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            -  30 ->  39
		
		-1,-1,-1,62,-1,-1,-1,63,             # ()*+'-./   -  40 ->  47
		52,53,54,55,56,57,58,59,60,61,       # 0123456789 -  48 ->  57
		-1,-1,-1,-1,-1,-1,-1, 0, 1, 2,       # :;<=>?@ABC -  58 ->  67
		 3, 4, 5, 6, 7, 8, 9,10,11,12,       # DEFGHIJKLM -  68 ->  77
		13,14,15,16,17,18,19,20,21,22,       # NOPQRSTUVW -  78 ->  87
		23,24,25,-1,-1,-1,-1,-1,-1,26,       # XYZ[\]^_`a -  88 ->  97
		27,28,29,30,31,32,33,34,35,36,       # bcdefghijk -  98 -> 107
		37,38,39,40,41,42,43,44,45,46,       # lmnopqrstu - 108 -> 117
		47,48,49,50,51,                      # vwxyz      - 118 -> 122

			  -1,-1,-1,-1,-1,-1,-1,-1,       #            - 123 -> 130
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 131 -> 140
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 141 -> 150
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 151 -> 160
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 161 -> 170
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 171 -> 180
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 181 -> 190
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 191 -> 200
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 201 -> 210
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 211 -> 220
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 221 -> 230
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 231 -> 240
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,       #            - 241 -> 250
		-1,-1,-1,-1,-1                       #            - 251 -> 255
	);
	$alphabet =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
}

# Reset the encoder/decoder
# Must be called before invoking encode() or decode().
# Once called, one must ONLY invoke encode() or decode() but never intermix
# calls to these two routines.  To switch, one must invoke reset() again.
sub reset {
	my ($len) = @_;
	&init unless $init_done++;
	my $data = " " x ($len || 64 * 1024);	# pre-extend
	$data = "";
	$output = \$data;
	$input = 0;
	$pad = 0;
	@byte = ();
	$offset = 0;
	undef $error;
	undef $op;
}

# Decode new data from the base64 stream
# Invoke as many times as necessary, until the end of the stream is reached.
# Call output() to actually fetch the decoded string.
sub decode {
	my ($data) = @_;
	return if defined $error;		# Stop as soon as an error occurred
	$op = "d" unless defined $op;
	if ($op ne "d") {
		$error = "mixed decode() within encode() calls";
		return;
	}
	my $len = length $data;
	for (my $i = 0; $i < $len; $i++) {
		my $c = substr($data, $i, 1);
		my $v;
		if ($c eq '=') {
			$v = 0;
			if ($pad++ >= 2) {
				$error = "too much padding";
				return;
			}
		} else {
			$v = $values[ord($c)];
			if ($v < 0) {
				$error = "invalid character '$c'";
				return;
			}
		}

		# In the following picture, we represent how the 4 bytes of input,
		# each consisting of only 6 bits of information forming a base64 digit,
		# are concatenated back into 3 bytes of binary information.
		#
		# input digit      0     1      2      3
		#               <----><-----><-----><---->
		#              +--------+--------+--------+
		#              |01234501|23450123|45012345|
		#              +--------+--------+--------+
		# output byte      0        1        2

		if ($input == 0) {
			$byte[0] = $v << 2;
		} elsif ($input == 1) {
			$byte[1] = ($v & 0x0f) << 4;
			$byte[0] |= $v >> 4;
		} elsif ($input == 2) {
			$byte[2] = ($v & 0x03) << 6;
			$byte[1] |= $v >> 2;
		} else {
			$byte[2] |= $v;
			$input = -1;
			$$output .= chr($byte[0]) . chr($byte[1]) . chr($byte[2]);
		}
		$input++;
		$offset++;
	}
}

# Encode new data into the base64 stream
# Invoke as many times as necessary, until the end of the stream is reached.
# Call output() to actually fetch the encoded string.
sub encode {
	my ($data) = @_;
	return if defined $error;		# Stop as soon as an error occurred
	$op = "e" unless defined $op;
	if ($op ne "e") {
		$error = "mixed encode() within decode() calls";
		return;
	}
	my $len = length $data;
	for (my $i = 0; $i < $len; $i++) {
		my $c = substr($data, $i, 1);
		my $v = unpack("C", $c);

		# In the following picture, we represent how the 3 bytes of input
		# are split into groups of 6 bits, each group being encoded as a
		# single base64 digit.
		#
		# input byte       0        1        2
		#              +--------+--------+--------+
		#              |01234501|23450123|45012345|
		#              +--------+--------+--------+
		#               <----><-----><-----><---->
		# output digit     0     1      2      3
		#
		# Every times we have 16 blocks of 4 chars, we emit a "\n" to avoid
		# too long lines.

		if ($input == 0) {
			$byte[0] = $v >> 2;
			$byte[1] = ($v & 0x3) << 4;
			$$output .= "\n" if $offset && 0 == $offset % 57;
		} elsif ($input == 1) {
			$byte[1] |= $v >> 4;
			$byte[2] |= ($v & 0xf) << 2;
		} else {
			$byte[2] |= $v >> 6;
			$byte[3] = $v & 0x3f;
			$input = -1;
			$$output .=
				substr($alphabet, $byte[0], 1) .
				substr($alphabet, $byte[1], 1) .
				substr($alphabet, $byte[2], 1) .
				substr($alphabet, $byte[3], 1);
			@byte = ();
		}
		$input++;
		$offset++;
	}
}

# Return a reference to the output of the encoded/decoded base64 stream
sub output {
	return $output unless defined $op;	# Neither encode() nor decode() called
	if ($op eq 'd') {
		&'add_log("WARNING truncated base64 input (length = $offset)")
			if $input && $'loglvl > 2;
		$$output =~ s/\0*$//;
	} elsif ($op eq 'e') {
		my $pad = $offset % 3;
		if ($pad == 1) {
			$$output .=
				substr($alphabet, $byte[0], 1) .
				substr($alphabet, $byte[1], 1) . "==";
		} elsif ($pad == 2) {
			$$output .=
				substr($alphabet, $byte[0], 1) .
				substr($alphabet, $byte[1], 1) .
				substr($alphabet, $byte[2], 1) . "=";
		}
		$$output .= "\n";
	} else {
		&'add_log("ERROR unknown base64 operation '$op'") if $'loglvl;
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

