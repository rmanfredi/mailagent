# Test backreferences

# $Id: backref.t,v 3.0 1993/11/29 13:49:56 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: backref.t,v $
# Revision 3.0  1993/11/29  13:49:56  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/filter.pl';
unlink 'output', 'comp.unix.wizards';

&add_header('X-Tag: backref #1');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Must have been deleted
-f 'output' || print "3\n";		# Created by RUN
chop($output = `cat output 2>/dev/null`);
$output eq 'ref,,ram@eiffel.com,melting technology' || print "4\n";

&replace_header('X-Tag: backref #2');
&add_header('Newsgroups: comp.mail.mh,comp.unix.wizards,talk.bizarre');
`$cmd`;
$? == 0 || print "5\n";
-f "$user" && print "6\n";				# Must have been saved
-f 'comp.unix.wizards' || print "7\n";	# Created by SAVE

unlink 'output', 'comp.unix.wizards';
print "0\n";
