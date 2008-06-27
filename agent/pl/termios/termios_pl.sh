case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting agent/pl/termios/termios.pl (with variable substitutions)"
$cat >termios.pl <<!GROK!THIS!
;# $Id: utmp_pl.sh,v 3.0.1.2 1995/01/03 18:18:48 ram Exp ram $
;#
;#  Copyright (c) 2008, Raphael Manfredi
;#  
;#  You may redistribute only under the terms of the Artistic License,
;#  as specified in the README file that comes with the distribution.
;#  You may reuse parts of this distribution only within the terms of
;#  that same Artistic License; a copy of which may be found at the root
;#  of the source tree for mailagent 3.0.
;#
;# Primitives to acess the terminal through the POSIX termios interface
;#
#
# termios primitives
#

package termios;

# Initialize constants
sub init {
	# (configured and automatically generated section)
!GROK!THIS!
./termios_ph | $sed -e 's/^/	/' >>termios.pl
$cat >>termios.pl <<'!NO!SUBS!'
	# (end of configured section)

	$inited = 1;
}

# Decompile the winsize structure, returning (row, col)
sub decompile {
	my ($buf) = @_;
	my @f = unpack($packfmt, $buf);
	my %win;
	foreach my $field (@fields) {
		next if $field eq 'pad';		# Padding just skipped over
		$win{$field} = shift @f;		# This field was decoded by unpack()
	}
	return ($win{'row'}, $win{'col'});
}

# Determine the tty size, returning (row, col).
# Returns () if we cannot determine the size due to missing termios.
# Returns an (error) if there was an error during size computation.
sub size {
	my ($tty) = @_;
	&init unless $inited;
	return () unless defined $TIOCGWINSZ;	# No termios
	local *TTY;
	open(TTY, $tty) || return ("cannot open $tty: $!");
	my $win = ' ' x $length;
	my $res = ioctl(TTY, $TIOCGWINSZ, $win);
	close TTY;
	return ("ioctl(TIOCGWINSZ) on $tty failed: $!") unless defined $res;
	return decompile($win);
}

package main;

!NO!SUBS!
