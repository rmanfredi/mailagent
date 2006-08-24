# Set up mailagent and filter paths

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
;# $Log: init.pl,v $
;# Revision 3.0.1.3  1999/01/13  18:16:59  ram
;# patch64: cleanup agent.wait file since now always produced
;#
;# Revision 3.0.1.2  1995/08/07  16:28:52  ram
;# patch37: added support for locking on filesystems with short filenames
;#
;# Revision 3.0.1.1  1994/07/01  15:10:38  ram
;# patch8: fixed RCS leading comment string
;#
;# Revision 3.0  1993/11/29  13:50:24  ram
;# Baseline for mailagent 3.0 netwide release.
;#

$pwd = $ENV{'PWD'};					# Where TEST was invoked from
$lockext = $ENV{'LOCKEXT'};			# Locking extension
($up) = $pwd =~ m|^(.*)/.*|;
$mailagent_prog = $ENV{'MAILAGENT'};
$mailagent_path = "$up/$mailagent_prog";
$mailagent = "$mailagent_path -TEST";
$filter = "$up/filter/filter";

# Make sure no lock were left by previous test
unlink "$pwd/out/filter$lockext", "$pwd/out/perl$lockext";
unlink 'agent.wait';

