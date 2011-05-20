# Test compression feature

# $Id: compress.t,v 3.0.1.1 1995/01/25 15:33:37 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: compress.t,v $
# Revision 3.0.1.1  1995/01/25  15:33:37  ram
# patch27: ported to perl 5.0 PL0
#
# Revision 3.0  1993/11/29  13:50:08  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';
sub cleanup {
	unlink "$user", "$user.gz", 'always', 'always.gz', 'another', '.compress';
}
&cleanup;

# Look whether compress is available. If not, do not perform this test.
unlink 'mail.gz';
`gzip mail`;
`gunzip mail` if $? == 0 && -f mail.gz;
if ($? != 0) {		# No compress available in path, sorry
	print "-1\n";	# Do not perform any tests
	exit 0;
}
&cp_mail;			# Get a new fresh mail message, seems required for perl5?

&add_option("-o 'compress: ~/.compress'");
open(COMPRESS, '>.compress') || print "1\n";
print COMPRESS <<EOF || print "2\n";
a[lm]*
$user
test*
EOF
close COMPRESS || print "3\n";

&add_header('X-Tag: compress');
`$cmd`;
$? == 0 || print "4\n";
-f "$user" && print "5\n";		# Should be compressed
-f "$user.gz" || print "6\n";
-f 'always' && print "7\n";		# Should also be compressed
-f 'always.gz' || print "8\n";
-f 'another' || print "9\n";	# This one is not compressed
-f 'another.gz' && print "10\n";
$msize = -s "$user.gz";

`cp $user.gz $user >/dev/null 2>&1`;
`$cmd`;
$? == 0 || print "11\n";
-f "$user" || print "12\n";		# Should be not be recompressed
-f "$user.gz" || print "13\n";	# Should still be there
-f 'always' && print "14\n";	# Should also be compressed
-f 'always.gz' || print "15\n";
-f 'another' || print "16\n";	# This one is not compressed
-f 'another.gz' && print "17\n";
(-s $user != $msize) || print "18\n";		# Mail saved there
(-s "$user.gz" == $msize) || print "19\n";	# This one left undisturbed

unlink 'mail';
&cleanup;
print "0\n";
