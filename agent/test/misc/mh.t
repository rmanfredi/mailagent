# Test MH-style folders

# $Id: mh.t,v 3.0.1.1 1995/01/25 15:33:59 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: mh.t,v $
# Revision 3.0.1.1  1995/01/25  15:33:59  ram
# patch27: added checks for Msg-Protect and PROTECT
#
# Revision 3.0  1993/11/29  13:50:09  ram
# Baseline for mailagent 3.0 netwide release.
#

do '../pl/misc.pl';
unlink "$user", 'always';

-d 'mh' || mkdir('mh', 0700) || print "1\n";
-d 'mh/tmp' || mkdir('mh/tmp', 0700) || print "2\n";
unlink <mh/tmp/*>;
open(MSG, '>mh/tmp/3') || print "3\n";
print MSG <<'EOF';
From: mailagent
To: ram
Subject: message #3

Message #3
EOF
close MSG;
open(MSG, '>mh/tmp/7') || print "4\n";
print MSG <<'EOF';
From: mailagent
To: ram
Subject: message #7

Message #7
EOF
close MSG;
open(MSG, '>mh/tmp/.mh_sequences') || print "5\n";
print MSG <<'EOF';
cur: 1
pseq: 3 7
unseen: 1 3-4 12
another: 1 3-7 12
hole: 1 3 5 7 9
full: 1-9
last: 3-6 9-12
EOF
close MSG;
open(MSG, '>mh/tmp/.mh_seqnew') || print "6\n";
print MSG <<'EOF';
cur: 1
pseq: 3 7
unseen: 1 3-4 8 12
another: 1 3-8 12
hole: 1 3 5 7-8 9
full: 1-9
last: 3-6 8-12
new: 8
EOF
close MSG;
open(MSG, '>.mh_prof') || print "7\n";
print MSG <<'EOF';
Path: mh
Unseen-Sequence: unseen, another, hole, full, last, new
Msg-Protect: 0647
EOF
close MSG;

-d 'dir' || mkdir('dir', 0700) || print "8\n";
unlink <dir/*>;
open(MSG, '>dir/.prefix') || print "9\n";
print MSG "msg\nanother\n";
close MSG;
open(MSG, '>dir/msg4') || print "10\n";
close MSG;
open(MSG, '>dir/other5') || print "11\n";
close MSG;
open(MSG, '>dir/5') || print "12\n";
close MSG;

`rm -rf mh/new`;
-d 'mh/new' && print "13\n";

-d 'simple' || mkdir('simple', 0700) || print "14\n";
open(MSG, '>simple/3') || print "15\n";
close MSG;

unlink 'mh/tmp/8', 'dir/msg5', 'simple/4', $user;

&add_option("-o 'mhprofile: ~/.mh_prof' -o 'msgprefix: .prefix'");
&add_header('X-Tag: mh');
`$cmd`;
$? == 0 || print "16\n";
-f "$user" && print "17\n";
-s 'mh/tmp/8' || print "18\n";
system "cmp -s mh/tmp/.mh_sequences mh/tmp/.mh_seqnew >/dev/null 2>&1";
$? == 0 || print "19\n";
-f 'mh/new/1' || print "20\n";
-s 'mh/new/.mh_sequences' || print "21\n";
-s 'dir/msg5' || print "22\n";
-s 'simple/4' || print "23\n";

sub st_mode {
	(stat($_[0]))[2] & 0777;
}

&st_mode('mh/tmp/8') == oct("0647") || print "24\n";	# Default Msg-Protect
&st_mode('mh/new/1') == oct("0567") || print "25\n";	# PROTECT command
&st_mode('dir/msg5') == oct("0567") || print "26\n";	# idem
&st_mode('simple/4') == oct("0644") || print "27\n";	# Default umask

system "rm -rf mh dir simple >/dev/null 2>&1";
unlink $user, 'mail';
print "0\n";
