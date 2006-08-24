# Common actions at the top of each filtering test

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
;# $Log: filter.pl,v $
;# Revision 3.0.1.1  1994/07/01  15:10:19  ram
;# patch8: now uses the cp_mail routine to copy mail
;#
;# Revision 3.0  1993/11/29  13:50:23  ram
;# Baseline for mailagent 3.0 netwide release.
;#

do '../pl/init.pl';
chdir '../out';
do '../pl/mail.pl';
&cp_mail;				# From mail.pl
$user = $ENV{'USER'};
unlink $user, 'agentlog';
$cmd = "$mailagent -L $ENV{'LEVEL'} -r ../rules mail 2>/dev/null";

# Re-create pattern list
open(PATTERN, ">pattern-list");
print PATTERN <<'EOP';
no-match-possible
another-impossible-match
# This will match
pattern
EOP
close PATTERN;
