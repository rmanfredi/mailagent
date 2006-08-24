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
;# $Log: rangeargs.pl,v $
;# Revision 3.0  1993/11/29  13:49:11  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;#
# Expand a patch list
sub rangeargs {
	local(@val);
	local($maxspec) = shift;	# maximum patch value
	local($args) = $#_;			# number of parameters

	while ($args-- >= 0) {
		$_ = shift;		# first value remaining in @_
		while (/./) {
			if (s/^(\d+)-(\d+)//) {
				$min = $1;
				$max = $2;
			} elsif (s/^(\d+)-//) {
				$min = $1;
				$max = $maxspec;
			} elsif (s/^-(\d+)//) {
				$max = $1;
				$min = 1;
			} elsif (s/^(\d+)//) {
				$max = $min = $1;
			} elsif (s/^,//) {
				$min = 1;
				$max = 0;	# won't print anything
			} else {
				# error in format: skip char
				s/.//;
			}
			for ($i = $min; $i <= $max; ++$i) {
				push(@val, $i) unless $wanted{$i};	# record only once
				$wanted{$i} = 1;
			}
		}
	}
	join(' ', @val);
}

