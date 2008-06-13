# Check quoted-printable body decoding for matching

# $Id$
#
#  Copyright (c) 2008, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.

do '../pl/filter.pl';
do '../pl/logfile.pl';
unlink 'always';
&cp_mail("../qp");

&add_header('x-tag: qp');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# No default action
-f 'always' || print "3\n";		# Recognized both X-Tag and Body

&get_log(4, 'always');
&not_log('broken', 5);		# Body NOT decoded
&check_log('brok=', 6);

unlink 'always', "$user";
print "0\n";
