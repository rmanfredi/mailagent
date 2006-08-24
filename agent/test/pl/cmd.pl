# Common actions at the top of each command test

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
;# $Log: cmd.pl,v $
;# Revision 3.0.1.1  1994/07/01  15:09:44  ram
;# patch8: the cp_mail routine is now located in mail.pl
;#
;# Revision 3.0  1993/11/29  13:50:22  ram
;# Baseline for mailagent 3.0 netwide release.
;#

do '../pl/init.pl';
chdir '../out';
do '../pl/mail.pl';
&cp_mail;				# From mail.pl
$user = $ENV{'USER'};
unlink "$user", 'agentlog', 'send.mail', 'send.news';
$cmd = "$mailagent -L $ENV{'LEVEL'} -r ../actions mail 2>/dev/null";

# We might need this
do '../pl/logfile.pl';

