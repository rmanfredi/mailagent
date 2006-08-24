# -I: install configuration and perform sanity checks.

# $Id: I.t,v 3.0.1.2 1996/12/24 15:03:36 ram Exp ram $
#
#  Copyright (c) 1990-2006, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  You may reuse parts of this distribution only within the terms of
#  that same Artistic License; a copy of which may be found at the root
#  of the source tree for mailagent 3.0.
#
# $Log: I.t,v $
# Revision 3.0.1.2  1996/12/24  15:03:36  ram
# patch45: fixed test for fast CPUs
#
# Revision 3.0.1.1  1995/02/16  14:39:06  ram
# patch32: created
#

do '../pl/init.pl';
chdir '../out';
unlink 'agentlog';

$SIG{'INT'} = CATCH;

# Restore default configuration if interrupted
sub CATCH {
	rename('.mailconfig', '.mailagent') if -f '.mailconfig';
}

# Make sure initial mailagent -I creates a ~/.mailagent file
rename('.mailagent', '.mailconfig') || print "1\n";
$output = `$mailagent -I`;
print "2\n" if $?;
-f '.mailagent' || print "3\n";

# Now load the config into memory...
&load_config(4);	# uses 5

# Make sure the necessary directories and files have been created.
# Hopefully, the default test environment does not use the same
# configuration than the default mailagent.cf, so we can make some
# sanity checks here...

-d $cf'spool || print "6\n";
-d $cf'logdir || print "7\n";
-s $cf'comfile || print "8\n";
-d $cf'queue || print "9\n";

`rm -rf var`;	# Hardwired name!!

# If we run it again, it should NOT modify the existing one
($ino, $size, $mtime, ) = (stat('.mailagent'))[1,7,9];
$output2 = `$mailagent -I`;
print "10\n" if $?;
-f '.mailagent' || print "11\n";
($ino2, $size2, $mtime2, ) = (stat('.mailagent'))[1,7,9];
print "12\n" if $ino2 != $ino;
print "13\n" if $size2 != $size;
print "14\n" if $mtime2 != $mtime;
print "15\n" unless defined $ino;	# Make sure stat did not fail...

# Should have beed recreated
-d $cf'spool || print "16\n";
-d $cf'logdir || print "17\n";
-s $cf'comfile || print "18\n";
-d $cf'queue || print "19\n";

$output ne $output2 || print "20\n";
$output =~ /creating/ || print "21\n";
$output2 =~ /merging/ || print "22\n";

# Ensure missing parameters are merged properly...
rename('.mailagent', 'config') || print "23\n";
open(OLD, 'config') || print "24\n";
open(NEW, '>.mailagent') || print "25\n";
while (<OLD>) {
	next if /^#?com/;
	next if /^#?queue/;
	next if /^#?logdir/;
	print NEW;
}
close OLD;
close(NEW) || print "26\n";
unlink 'config';

# Make sure we can undefine the old config properly...
$cf'queue ne '' || print "27\n";
eval $cf'undef;
$cf'queue eq '' || print "28\n";

# ...and that the queue parameter was indeed undefined above in NEW.
&load_config(29);	# uses 30
$cf'queue eq '' || print "31\n";
eval $cf'undef;

($ino, $size, $mtime, ) = (stat('.mailagent'))[1,7,9];
$output3 = `$mailagent -I`;
print "32\n" if $?;
-f '.mailagent' || print "33\n";
($ino2, $size2, $mtime2, ) = (stat('.mailagent'))[1,7,9];

print "34\n" if $ino2 == $ino;
print "35\n" if $size2 == $size;
print "36\n" if $mtime2 < $mtime;	# May be equal if CPU is fast
print "37\n" unless defined $ino;	# Make sure stat did not fail...

&load_config(38);	# uses 39
$cf'queue ne '' || print "40\n";	# is now defined!!
$cf'comfile ne '' || print "41\n";
$cf'logdir ne '' || print "42\n";

`rm -rf var`;	# Hardwired name!!
&CATCH;			# Restore default configuration
print "0\n";

# May print 2 error numbers starting from $error
# Sets $cf'undef so that we may later on undefine the whole config...
sub load_config {
	local($error) = @_;
	package cf;
	$undef = "package cf;\n";
	$config = '';
	open(CONFIG, '.mailagent') || print "$error\n";
	while (<CONFIG>) {
		next if /^[ \t]*#/;			# skip comments
		next if /^[ \t]*\n/;		# skip empy lines
		s/([^\\](\\\\)*)@/$1\\@/g;	# escape all un-escaped @ in string
		$config .= $_;
	}
	close CONFIG;

	$myhome = $ENV{'HOME'};	# Set by TEST
	$eval = '';
	foreach (split(/\n/, $config)) {
		if (/^[ \t]*([^ \t\n:\/]*)[ \t]*:[ \t]*([^#\n]*)/) {
			$var = $1;
			$value = $2;
			$value =~ s/\s*$//;						# remove trailing spaces
			$eval .= "\$$var = \"$value\";\n";
			$eval .= "\$$var =~ s|~|\$myhome|g;\n";	# ~ substitution
			$undef .= "undef \$$var;\n";			# to reset config
		}
	}
	eval $eval;			# evaluate configuration parameters within package
	$error++;
	print "$error\n" if $@ ne '';
}

