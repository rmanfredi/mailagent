# Test selection on UTF-8 encoded subject

# Copyright (c) 2023, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#

do '../pl/cmd.pl';
unlink 'ok', 'bad';

my $file = 'mail.utf8';
cp_mail("../$file", $file);
add_header('X-Tag: utf8 #1', $file);
$cmd = testing_cmd($file);

`$cmd`;
$? == 0 || print "1\n";
-f 'bad' && print "2\n";	# Created only if filtering fails
-f 'ok' || print "3\n";
unlink 'ok', 'bad';

replace_header('X-Tag: utf8 #2', $file);
`$cmd`;
$? == 0 || print "4\n";
-f 'bad' && print "5\n";	# Created only if filtering fails
-f 'ok1' || print "6\n";
-f 'ok2' || print "7\n";
unlink $file, 'ok1', 'ok2', 'bad';
print "0\n";

# vi: set ts=4 sw=4 syn=perl:
