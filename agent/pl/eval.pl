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
;# $Log: eval.pl,v $
;# Revision 3.0.1.2  1995/01/03  18:07:10  ram
;# patch24: simplified hash table initialization -- code still unused
;#
;# Revision 3.0.1.1  1994/09/22  14:18:11  ram
;# patch12: replaced all deprecated 'do sub' calls with '&sub'
;#
;# Revision 3.0  1993/11/29  13:48:42  ram
;# Baseline for mailagent 3.0 netwide release.
;#
;# 
#
# The built-in expression interpreter
#

# Initialize the interpreter
sub init_interpreter {
	&set_priorities;		# Fill in %Priority
	&set_functions;			# Fill in %Function
	$macro_T = "the Epoch";	# Default value for %T macro substitution
}

# Priorities for operators -- magic numbers :-)
# An operator with higher priority will evaluate before another with a lower
# one. For instance, given the priorities listed hereinafter, a && b == c
# would evaluate as a && (b == c).
sub set_priorities {
	%Priority = (
		'&&',		4,
		'||',		3,
		'>=',		6,
		'<=',		6,
		'<',		6,
		'>',		6,
		'==',		6,
		'!=',		6,
		'=~',		6,
		'!~',		6,
	);
}

# Perl functions handling operators
sub set_functions {
	%Function = (
		'&&',		'f_and',			# Boolean AND
		'||',		'f_or',				# Boolean OR
		'>=',		'f_ge',				# Greated or equal
		'<=',		'f_le',				# Lesser or equal
		'>',		'f_gt',				# Greater than
		'<',		'f_lt',				# Lesser than
		'==',		'f_eq',				# Equal as strings
		'!=',		'f_ne',				# Different (not equal)
		'=~',		'f_match',			# Match
		'!~',		'f_nomatch',		# No match
	);
}

# Print error messages -- asssumes $unit and $. correctly set.
sub error {
	&add_log("ERROR @_") if $loglvl > 1;
}

# Add a value on the stack, modified by all the monadic operators.
# We use the locals @val and @mono from eval_expr.
sub push_val {
	local($val) = shift(@_);
	while ($#mono >= 0) {
		# Cheat... the only monadic operator is '!'.
		pop(@mono);
		$val = !$val;
	}
	push(@val, $val);
}

# Execute a stacked operation, leave result in stack.
# We use the locals @val and @op from eval_expr.
# If the value stack holds only one operand, do nothing.
sub execute {
	return unless $#val > 0;
	local($op) = pop(@op);			# The operator
	local($val2) = pop(@val);		# Right value in algebraic notation
	local($val1) = pop(@val);		# Left value in algebraic notation
	local($func) = $Function{$op};	# Function to be called
	&macros_subst(*val1);			# Expand macros
	&macros_subst(*val2);
	push(@val, eval("&$func($val1, $val2)") ? 1: 0);
}

# Given an operator, either we add it in the stack @op, because its
# priority is lower than the one on top of the stack, or we first execute
# the stacked operations until we reach the end of stack or an operand
# whose priority is lower than ours.
# We use the locals @val and @op from eval_expr.
sub update_stack {
	local($op) = shift(@_);		# Operator
	if (!$Priority{$op}) {
		&error("illegal operator $op");
		return;
	} else {
		if ($#val < 0) {
			&error("missing first operand for '$op' (diadic operator)");
			return;
		}
		# Because of a bug in perl 4.0 PL19, I'm using a loop construct
		# instead of a while() modifier.
		while (
			$Priority{$op[$#op]} > $Priority{$op}	# Higher priority op
			&& $#val > 0							# At least 2 values
		) {
			&execute;	# Execute an higer priority stacked operation
		}
		push(@op, $op);		# Everything at higher priority has been executed
	}
}

# This is the heart of our little interpreter. Here, we evaluate
# a logical expression and return its value.
sub eval_expr {
	local(*expr) = shift(@_);	# Expression to parse
	local(@val) = ();			# Stack of values
	local(@op) = ();			# Stack of diadic operators
	local(@mono) =();			# Stack of monadic operators
	local($tmp);
	$_ = $expr;
	while (1) {
		s/^\s+//;				# Remove spaces between words
		# A perl statement <<command>>
		if (s/^<<//) {
			if (s/^(.*)>>//) {
				&push_val((system
					('perl','-e', "if ($1) {exit 0;} else {exit 1;}"
					))? 0 : 1);
			} else {
				&error("incomplete perl statement");
			}
		}
		# A shell statement <command>
		elsif (s/^<//) {
			if (s/^(.*)>//) {
				&push_val((system
					("if $1 >/dev/null 2>&1; then exit 0; else exit 1; fi"
					))? 0 : 1);
			} else {
				&error("incomplete shell statement");
			}
		}
		# The '(' construct
		elsif (s/^\(//) {
			&push_val(&eval_expr(*_));
			# A final '\' indicates an end of line
			&error("missing final parenthesis") if !s/^\\//;
		}
		# Found a ')' or end of line
		elsif (/^\)/ || /^$/) {
			s/^\)/\\/;						# Signals: left parenthesis found
			$expr = $_;						# Remove interpreted stuff
			&execute while $#val > 0;		# Executed stacked operations
			while ($#op >= 0) {
				$_ = pop(@op);
				&error("missing second operand for '$_' (diadic operator)");
			}
			return $val[0];
		}
		# Diadic operators
		elsif (s/^(\|\||&&|>=|<=|>|<|==|!=|=|\/=)//) {
			&update_stack($1);
		}
		# Unary operator '!'
		elsif (s/^!//) {
			push(@mono,'!');
		}
		# Everything else is a value which stands for itself (atom)
		elsif (s/^([\w'"%]+)//) {
			&push_val($1);
		}
		# Syntax error
		else {
			print "Syntax error: remaining is >>>$_<<<\n";
			$_ = "";
		}
	}
}

# Call eval_expr and check that everything is ok (e.g. the stack must be empty)
sub evaluate {
	local($val);					# Value returned
	local(*expr) = shift(@_);		# Expression to be parsed
	while ($expr) {
		$val = &eval_expr(*expr);	# Expression will be modified
		print "extra closing parenthesis ignored.\n" if $expr =~ s/^\\\)*//;
		$expr = $val . $expr if $expr ne '';
	}
	$val;
}

#
# Boolean functions used by the interpreter. They all take two arguments
# and return 0 if false and 1 if true.
#

sub f_and { $_[0] && $_[1]; }		# Boolean AND
sub f_or { $_[0] || $_[1]; }		# Boolean OR
sub f_ge { $_[0] >= $_[1]; }		# Greater or equal
sub f_le { $_[0] <= $_[1]; }		# Lesser or equal
sub f_lt { $_[0] < $_[1]; }			# Lesser than
sub f_gt { $_[0] > $_[1]; }			# Greater than
sub f_eq { "$_[0]" eq "$_[1]"; }	# Equal
sub f_ne { "$_[0]" ne "$_[1]"; }	# Not equal
sub f_match { $_[0] =~ /$_[1]/; }	# Pattern matches
sub f_nomatch { $_[0] !~ /$_[1]/; }	# Pattern does not match

