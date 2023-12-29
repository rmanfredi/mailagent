;#
;# Copyright 2023, Raphael Manfredi
;#
;#  You may redistribute only under the terms of the Artistic License,
;#  as specified in the README file that comes with the distribution.
;#  You may reuse parts of this distribution only within the terms of
;#  that same Artistic License; a copy of which may be found at the root
;#  of the source tree for mailagent 3.0.
;#
#
# Conversion of headers to UTF-8 for matching.
#

package as_utf8;

use Encode;

# Internal routine
sub as_utf8 {
	my ($c, $l) = @_;	# charset, line
	my $enc = Encode::find_encoding($c);
	my $utf8 = Encode::find_encoding("utf-8");
	if (ref $enc && ref $utf8 && $enc->name ne $utf8->name) {
		my $data = $enc->decode($l);
		$data = $utf8->encode($data);
		$l = $data if length $data;
	}
	return $l;
}

# Perload OFF

# Quoted-printable decoder
# MUST NOT be dataloaded (would mess $1 in the regexp)
sub to_txt {
	my ($c, $l) = @_;	# charset, line
	$l =~ s/=([\da-fA-F]{2})/pack('C', hex($1))/ge;
	return as_utf8($c, $l);
}

# Base64 decoder
# MUST NOT be dataloaded (would mess $1 in the regexp)
sub b64_to_txt {
	my ($c, $l) = @_;	# charset, line
	base64::reset(length $l);
	base64::decode($l);
	my $o = base64::output();
	return as_utf8($c, $$o);
}

# Perload ON

# Quick removal of quoted-printable escapes within the headers
# We pay attention to the charset and recode data as UTF-8.
sub recode {
	my ($l) = @_;
	return $l unless $l =~ /\?[BQ]\?/;		# Shortcut
	# The to_txt() routine being used MUST NOT be dataloaded or $1 would be
	# reset to '' on the first invocation.  It's a perl bug (seen in 5.10)
	# By precaution, we also do not dataload b64_to_txt().
	$l =~ s/=\?([\w-]+)\?Q\?(.*?)\?=/to_txt($1,$2)/sieg;
	$l =~ s/=\?([\w-]+)\?B\?(.*?)\?=/b64_to_txt($1,$2)/sieg;
	&'add_log("recoded '$_[0]' as UTF-8 '$l'") if $'loglvl > 19 && $_[0] ne $l;
	return $l;
}

package main;

