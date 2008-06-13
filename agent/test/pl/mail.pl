# Utilities to twinkle default mail message

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
;# $Log: mail.pl,v $
;# Revision 3.0.1.2  1997/09/15  15:19:30  ram
;# patch57: forgot to unlink mail.lock in cp_mail()
;#
;# Revision 3.0.1.1  1994/07/01  15:11:46  ram
;# patch8: fixed RCS leading comment string
;# patch8: now defines the cp_mail routine
;# patch8: the replace_header routine can now supersede header lines
;#
;# Revision 3.0  1993/11/29  13:50:25  ram
;# Baseline for mailagent 3.0 netwide release.
;#

# Add header line within message
sub add_header {
	local($header, $file) = @_;
	$file = 'mail' unless $file;
	local($_);
	open(NEW, ">$file.x");
	open(OLD, "$file");
	while (<OLD>) {
		print NEW $header, "\n" if (1../^$/) && /^$/;
		print NEW;
	}
	close NEW;
	close OLD;
	rename("$file.x", "$file");
}

# Change first matching header with new value. If $supersede is given, then
# the it is used instead. This enables:
#	&replace_header('To:', 'xxx', 'Cc: me')
# to replace the whole first To: line by a Cc: header. If this third argument
# is not supplied, then the first one is used verbatim, which is the case in
# most calls to this routine.
sub replace_header {
	local($header, $file, $supersede) = @_;
	$supersede = $header unless defined $supersede;
	$file = 'mail' unless $file;
	local($field) = $header =~ /^(\S+):/;
	local($_);
	open(NEW, ">$file.x");
	open(OLD, "$file");
	while (<OLD>) {
		if ((1../^$/) && eval "/^$field:/") {
			print NEW $supersede, "\n";
			next;
		}
		print NEW;
	}
	close NEW;
	close OLD;
	rename("$file.x", "$file");
}

# Add line at the end of the mail message
sub add_body {
	local($line, $file) = @_;
	$file = 'mail' unless $file;
	open(NEW, ">>$file");
	print NEW $line, "\n";
	close NEW;
}

# Copy mail in out/
sub cp_mail {
	my ($file) = @_;
	$file = "../mail" unless defined $file;
	local($_);
	open(MAIL, $file)	|| die "Can't open $file: $!";
	open(HERE, '>mail');
	print HERE while <MAIL>;
	close MAIL;
	close HERE;
	unlink 'mail.lock';
}

