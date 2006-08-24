# Basic MTA/NTA for tests

# $Id$
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: mta.pl,v $
# Revision 3.0  1993/11/29  13:50:26  ram
# Baseline for mailagent 3.0 netwide release.
#

unlink 'send.mail', 'send.news';	# Output from our MTA and NTA

open(MSEND, '>msend');
print MSEND <<'EOM';
#!/bin/sh
echo "Recipients: $@" >> send.mail
exec cat >> send.mail
EOM
close MSEND;

open(NSEND, '>nsend');
print NSEND <<'EOM';
#!/bin/sh
exec cat >> send.news
EOM
close NSEND;

chmod 0755, 'msend', 'nsend';

sub clear_mta {
	unlink 'msend', 'nsend', 'send.mail', 'send.news';
}

