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
;# $Log: sendfile.pl,v $
;# Revision 3.0.1.3  1995/02/16  14:36:59  ram
;# patch32: indentation fix
;#
;# Revision 3.0.1.2  1994/10/10  10:25:40  ram
;# patch19: added various escapes in strings for perl5 support
;#
;# Revision 3.0.1.1  1994/10/04  17:55:43  ram
;# patch17: now uses the email config parameter to send messages to user
;#
;# Revision 3.0  1993/11/29  13:49:16  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
;# This file contains two subroutines:
;#   - sendfile, sends a set of files
;#   - abort, called when something got wrong
;#
;# A routine clean_tmp must be defined in the program, for removing
;# possible temporary files in case abort is called.
;#
# Send a set of files
sub sendfile {
	local($dest, $cf'tmpdir, $pack, $subject) = @_;
	&add_log("sending dir $cf'tmpdir to $dest, mode $pack") if $loglvl > 9;

	# A little help message
	local($mail_help) = "Detailed intructions can be obtained by:

	Subject: Command
	\@SH mailhelp $dest";

	# Go to tmpdir where files are stored
	chdir $cf'tmpdir || &abort("NO TMP DIRECTORY");

	# Build a list of files to send
	local($list) = "";		# List of plain files
	local($dlist) = "";		# List with directories (for makekit)
	local($nbyte) = 0;
	local($nsend) = 0;
	open(FIND, "find . -print |") || &abort("CANNOT RUN FIND");
	while (<FIND>) {
		chop;
		next if $_ eq '.';		# Skip current directory `.'
		s|^\./||;
		$dlist .= $_ . " ";		# Save file/dir name
		if (-f $_) {			# If plain file
			$list .= $_ . " ";	# Save plain file
			$nsend++;			# One more file to send
			($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
				$blksize,$blocks) = stat($_);
			$nbyte += $size;	# Update total size
		}
	}
	close FIND;

	&abort("NO FILE TO SEND") unless $nsend;
	if ($nsend > 1) {
		&add_log("$nsend files to pack ($nbyte bytes)") if $loglvl > 9;
	} else {
		&add_log("1 file to pack ($nbyte bytes)") if $loglvl > 9;
	}

	# Pack files
	if ($pack =~ /kit/) {
		system "kit -n Part $list" || &abort("CANNOT KIT FILES");
		$packed = "kit";
	} elsif ($pack =~ /shar/) {
		# Create a manifest, so that we can easily run maniscan
		# Leave a PACKNOTES file with non-zero length if problems.
		local($mani) = $dlist;
		$mani =~ s/ /\n/g;
		local($packlist) = "pack.$$";	# Pack list used as manifest
		if (open(PACKLIST, ">$packlist")) {
			print PACKLIST $mani;
			close PACKLIST;
			system 'maniscan', "-i$packlist",
				"-o$packlist", '-w0', '-n', '-lPACKNOTES';
			&add_log("ERROR maniscan returned non-zero status")
				if $loglvl > 5 && $?;
			if (-s 'PACKNOTES') {		# Files split or uu-encoded
				system 'makekit', "-i$packlist", '-t',
					"Now run 'sh PACKNOTES'." || &abort("CANNOT SHAR FILES");
			} else {
				system 'makekit', "-i$packlist" || &abort("CANNOT SHAR FILES");
			}
		} else {
			&add_log("ERROR cannot create packlist") if $loglvl > 5;
			system "makekit $dlist" || &abort("CANNOT SHAR FILES");
		}
		$packed = "shar";
	} else {
		if ($nbyte > $cf'maxsize) {		# Defined in ~/.mailagent
			system "kit -M -n Part $list" || &abort("CANNOT KIT FILES");
			$packed = "minikit";		# The minikit is included
		} else {
			# Try with makekit first
			if (system "makekit $dlist") {	# If failed
				system "kit -M -n Part $list" || &abort("CANNOT KIT FILES");
				$packed = "minikit";	# The minikit is included
			} else {
				$packed = "shar";
			}
		}
	}

	# How many parts are there ?
	@parts = <Part*>;
	$npart = $#parts + 1;		# Number of parts made
	&abort("NO PART TO SEND -- $packed failed") unless $npart;
	if ($npart > 1) {
		&add_log("$npart $packed parts to send") if $loglvl > 19;
	} else {
		&add_log("$npart $packed part to send") if $loglvl > 19;
	}

	# Now send the parts
	$nbyte = 0;				# How many bytes do we send ?
	$part_num = 0;
	$signal="";				# To signal parts number if more than 1
	local($partsent) = 0;	# Number of parts actually sent
	local($bytesent) = 0;	# Amount of bytes actually sent
	foreach $part (@parts) {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
			$blksize,$blocks) = stat($part);
		$nbyte += $size;	# Update total size

		&add_log("dealing with $part ($size bytes)") if $loglvl > 19;

		# See if we need to signal other parts
		$part_num++;			# Update part number
		if ($npart > 1) {
			$signal=" (Part $part_num/$npart)";
		}

		# Send part
		open(MAILER, "|$cf'sendmail $cf'mailopt $dest");
		print MAILER
"To: $dest
Subject: $subject$signal
Precedence: bulk
X-Mailer: mailagent [version $mversion-$revision]

Here is the answer to your request:

	$fullcmd


";
		if ($packed eq 'minikit') {		# Kit with minikit included
			print MAILER
"This is a kit file. It will be simpler to unkit it if you own the kit
package (latest patchlevel), but you can use the minikit provided with
this set of file (please see instructions provided by kit itself at the
head of each part). If you wish to get kit, send me the following mail:

";
		} elsif ($packed eq 'kit') {	# Plain kit files
			print MAILER
"This is a kit file. You need the kit package (latest patchlevel) to
unkit it. If you do not have kit, send me the following mail:

";
		}
		if ($packed =~ /kit/) {		# Kit parts
			print MAILER
"	Subject: Command
	\@PACK shar
	\@SH maildist $dest kit -

and you will get the latest release of kit as shell archives.

$mail_help

";
			# Repeat instructions which should be provided by kit anyway
			if ($npart > 1) {
				print MAILER
"Unkit:	Save this mail into a file, e.g. \"foo$part_num\" and wait until
	you have received the $npart parts. Then, do \"unkit foo*\". To see
	what will be extracted, you may wish to do \"unkit -l foo*\" before.
";
			} else {
				print MAILER
"Unkit:	Save this mail into a file, e.g. \"foo\". Then do \"unkit foo\". To see
	what will be extracted, you may wish to do \"unkit -l foo\" before.
";
			}
			# If we used the minikit, signal where instruction may be found
			if ($packed eq 'minikit') {
				print MAILER
"	This kit archive also contains a minikit which will enable you to
	extract the files even if you do not have kit. Please follow the
	instructions kit has provided for you at the head of each part. Should
	the minikit prove itself useless, you may wish to get kit.
";
			}
		} else {			# Shar parts
			print MAILER
"This is a shar file. It will be simpler to unshar it if you own the Rich Salz's
cshar package. If you do not have it, send me the following mail:

	Subject: Command
	\@PACK shar
	\@SH maildist $dest cshar 3.0

and you will get cshar as shell archives.

$mail_help

";
			if (-s 'PACKNOTES') {		# Problems detected by maniscan
				print MAILER
"
Warning:
	Some minor problems were encountered during the building of the
	shell archives. Perhaps a big file has been split, a binary has been
	uu-encoded, or some lines were too long. Once you have unpacked the
	whole distribution, see file PACKNOTES for more information. You can
	run it through sh by typing 'sh PACKNOTES' to restore possible splited
	or encoded files.

";
			}
			if ($npart > 1) {
				print MAILER
"Unshar: Save this mail into a file, e.g. \"foo$part_num\" and wait until
	you have received the $npart parts. Then, do \"unshar -n foo*\". If you
	do not own \"unshar\", edit the $npart files and remove the mail header
	by hand before feeding into sh.
";
			} else {
				print MAILER
"Unshar: Save this mail into a file, e.g. \"foo\". Then do \"unshar -n foo\". If
	you do not own \"unshar\", edit the file and remove the mail header by
	hand before feeding into sh.
";
			}
		}
		print MAILER
"
-- $prog_name speaking for $cf'user


";
		open(PART, $part) || &abort("CANNOT OPEN $part");
		while (<PART>) {
			print MAILER;
		}
		close PART;
		close MAILER;
		if ($?) {
			&add_log("ERROR couldn't send $size bytes to $dest")
				if $loglvl > 1;
		} else {
			&add_log("SENT $size bytes to $dest") if $loglvl > 2;
			$partsent++;
			$bytesent += $size;
		}
	}

	# Prepare log message
	local($partof) = "";
	local($byteof) = "";
	local($part);
	local($byte);
	if ($partsent > 1) {
		$part = "parts";
	} else {
		$part = "part";
	}
	if ($bytesent > 1) {
		$byte = "bytes";
	} else {
		$byte = "byte";
	}
	if ($partsent != $npart) {
		$partof = " (of $npart)";
		$byteof = "/$nbyte";
	}
	&add_log(
		"SENT $partsent$partof $packed $part ($bytesent$byteof $byte) to $dest"
	) if $loglvl > 4;
}

# In case something got wrong
# We call the clean_tmp routine, which must be defined in the
# main program that will use abort.
sub abort {
	local($reason) = shift;		# Why do we abort ?
	local($cmd) = $fullcmd =~ /^(\S+)/;
	open(MAILER, "|$cf'sendmail $cf'mailopt $path $cf'email");
	print MAILER
"To: $path
Subject: $cmd failed
X-Mailer: mailagent [version $mversion-$revision]

Sorry, the $prog_name command failed while sending files.

Your command was: $fullcmd
Error message I got:

	>>>> $reason <<<<

If $cf'name can figure out what you meant, he may answer anyway.

-- $prog_name speaking for $cf'user
";
	close MAILER;
	&add_log("FAILED ($reason)") if $loglvl > 1;
	&clean_tmp;
	exit 0;			# Scheduled error
}

