# Get log file (by default) or any other file into @log

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
;# $Log: logfile.pl,v $
;# Revision 3.0.1.2  1995/08/07  16:29:15  ram
;# patch37: simplified matching by removing spurious eval
;#
;# Revision 3.0.1.1  1994/07/01  15:10:42  ram
;# patch8: fixed RCS leading comment string
;#
;# Revision 3.0  1993/11/29  13:50:24  ram
;# Baseline for mailagent 3.0 netwide release.
;#

sub get_log {
	local($num, $file) = @_;
	$file = 'agentlog' unless $file;
	open(LOG, $file) || print "$num\n";
	@log = <LOG>;
	close LOG;
}

# Make sure a pattern is within @log, return number of matches
sub check_log {
	local($pattern, $num) = @_;
	local(@matches);
	@matches = grep(/$pattern/, @log);
	print "$num\n" unless @matches;
	0 + @matches;
}

# Make sure a pattern is NOT within @log, return number of matches
sub not_log {
	local($pattern, $num) = @_;
	local(@matches);
	@matches = grep(/$pattern/, @log);
	print "$num\n" if @matches;
	0 + @matches;
}

