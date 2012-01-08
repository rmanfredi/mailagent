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
echo "Extracting agent/pl/utmp/utmp.pl (with variable substitutions)"
$cat >utmp.pl <<!GROK!THIS!
;# $Id: utmp_pl.sh,v 3.0.1.2 1995/01/03 18:18:48 ram Exp ram $
;#
;#  Copyright (c) 1990-2006, Raphael Manfredi
;#  
;#  You may redistribute only under the terms of the Artistic License,
;#  as specified in the README file that comes with the distribution.
;#  You may reuse parts of this distribution only within the terms of
;#  that same Artistic License; a copy of which may be found at the root
;#  of the source tree for mailagent 3.0.
;#
;# $Log: utmp_pl.sh,v $
;# Revision 3.0.1.2  1995/01/03  18:18:48  ram
;# patch24: make sure old utmp list is gone when reloading from /etc/utmp
;#
;# Revision 3.0.1.1  1994/10/29  18:13:28  ram
;# patch20: craeted
;#
;#
;# Primitives to acess the utmp file (where active logins are recorded).
;#
;# The utmp file is kept in an @utmp array where user name and tty information
;# are stored, separated by a space. Each line of the @utmp array being a pair
;# user/tty in the utmp file. Hence the number of entries in this array is the
;# number of users currently logged on.
;#
#
# utmp file primitives
#

package utmp;

# Initialize constants
sub init {
	# (configured and automatically generated section)
	\$utmp = '$utmp';
!GROK!THIS!
./utmp_ph | $sed -e 's/^/	/' >>utmp.pl
$cat >>utmp.pl <<'!NO!SUBS!'
	# (end of configured section)

	undef @utmp;		# Array where user/tty pairs are stored
	$lmtime = 0;		# Last modification time
	$init = 1;			# Marks init as being done
}

# Update the vision of the utmp file, if changed.
# Returns the amount of records anyway.
sub update {
	&init unless $init;
	my $ST_MTIME = 9 + $[;	# Field st_mtime from inode structure
	local($mtime) = (stat($utmp))[$ST_MTIME];
	return 0 + @utmp unless $mtime > $lmtime;
	$lmtime = $mtime;
	&reload;
}

# Reload the utmp file into @utmp, returning the amount of records.
sub reload {
	&init unless $init;
	open(UTMP, $utmp) || warn "Can't open $utmp: $!\n";
	undef @utmp;		# Array where user/tty pairs are stored
	local($buf);		# Where each "line" of utmp is read
	local(%utmp);		# Used to extract user and line informations
	local(@uline);		# Where line is unpaked
	while (sysread(UTMP, $buf, $length)) {
		@uline = unpack($packfmt, $buf);
		foreach $field (@fields) {
			next if $field eq 'pad';		# Padding was not unpacked
			$utmp{$field} = shift(@uline);	# Decompile structure
		}
		push(@utmp, $utmp{'user'} . ' ' . $utmp{'line'});
	}
	close UTMP;
	return 0 + @utmp;	# Amount of records
}

# Return the ttys on which a given user is logged
sub ttys {
	local($user) = @_;			# User's login name
	&update;					# Make sure we use most recent data
	local(@u) = @utmp;			# Work on a copy
	grep(s/^$user\s//, @u);		# Returns array of ttys
}

package main;

!NO!SUBS!
