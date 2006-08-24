# Test QUEUE command

# $Id: queue.t,v 3.0 1993/11/29 13:49:41 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: queue.t,v $
# Revision 3.0  1993/11/29  13:49:41  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/cmd.pl';

unlink <queue/*>;

&add_header('X-Tag: queue');
`$cmd`;
$? == 0 || print "1\n";
-f "$user" && print "2\n";		# Mail queued -> saved

@queue = <queue/qm*>;
@queue == 4 || print "3\n";
$size = -s 'mail';
$ok = 1;
foreach (@queue) {
	$ok == 0 if $size != -s $_;
}
$ok || print "4\n";

unlink <queue/*>;
unlink 'mail';
print "0\n";
