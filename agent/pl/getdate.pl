;# From: rick@imd.sterling.com (Richard Ohnemus)
;# Newsgroups: comp.lang.perl
;# Subject: Re: Parsing a date/time string
;# Message-ID: <1992Jun26.133036.2077@sparky.imd.sterling.com>
;# Date: 26 Jun 92 13:30:36 GMT
;# References: <25116@life.ai.mit.edu>
;# Sender: news@sparky.imd.sterling.com (News Admin)
;# Organization: Sterling Software, IMD
;#
;# Here is the famous (or infamous) getdate routine adapted for use with
;# PERL. (This was a quick hack but, it is being used in a couple of
;# programs and no problems have shown up yet. 8-{)
;# 
;# Calling sequence:
;#   $seconds = &getdate($date_time_str, 
;#                       $time_in_seconds, 
;#                       $offset_from_GMT_in_minutes);
;# 
;# time_in_seconds and offset_from_GMT_in_minutes are optional arguments.
;# If time_in_seconds is not specified then the current time is used.
;# If offset_from_GMT_in_minutes is not specified then TZ is read from the
;# environment to get the offset.
;# 
;# Examples of use:
;#   require 'getdate.pl';
;#   seconds = &getdate('Apr 24 17:44');
;#   seconds = &getdate('2 Feb 1992 03:53:17');
;#   ... many more date/time formats supported ...
;#
;# getdate.pl was generated from getdate.y by a version of Berkeley Yacc
;# 1.8 that I modified to generate PERL output. (The patches are based on
;# Ray Lischner's patches to byacc 1.6.) If anyone would like a copy of
;# the patches I can e-mail them or make them available for anonymous FTP
;# if there is enough interest.
;#
;#
;# $yysccsid = "@(#)yaccpar	1.8 (Berkeley) 01/20/91 (Perl 2.0 04/23/92)";
;# 	Steven M. Bellovin (unc!smb)
;#	Dept. of Computer Science
;#	University of North Carolina at Chapel Hill
;#	@(#)getdate.y	2.13	9/16/86
;#
;#	Richard J. Ohnemus (rick@IMD.Sterling.COM)
;#	(Where do I work??? I'm not even sure who I am! 8-{)
;#	converted to PERL 4/24/92
;#
;# Below are logging information for this package as included in the
;# mailagent program.
;#
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
;# $Log: getdate.pl,v $
;# Revision 3.0.1.4  2001/01/10 16:53:42  ram
;# patch69: fixed wrong lexical attribute synthesis for numbers
;#
;# Revision 3.0.1.3  1999/07/12  13:50:59  ram
;# patch66: fixed Y2K bug
;#
;# Revision 3.0.1.2  1995/01/25  15:22:22  ram
;# patch27: fixed a typo in &yyerror and various code clean-up
;# patch27: ported to perl 5.0 PL0
;#
;# Revision 3.0.1.1  1994/09/22  14:21:31  ram
;# patch12: local() statement was missing in &getdate parameters fetch
;#
;# Revision 3.0  1993/11/29  13:48:48  ram
;# Baseline for mailagent 3.0 netwide release.
;#
package getdate;

# This package parses a date string and converts it into a number of seconds.
# I did minor editing on this code, mainly to remove all the YYDEBUG #if tests
# and to reformat some of the table. I also encapsulated all the initializations
# into init subroutines and reworked on the indentation of semantic actions.
# Oh yes, I also made some minor modifications in place (i.e. without running
# yacc again) to apply some small fixes Richard sent me via e-mail.
# Other than that, it's pretty verbatim--RAM.

sub yyinit {
	$daysec = 24 * 60 * 60;

	$AM = 1;
	$PM = 2;
	$DAYLIGHT = 1;
	$STANDARD = 2;
	$MAYBE = 3;

	$ID=257;
	$MONTH=258;
	$DAY=259;
	$MERIDIAN=260;
	$NUMBER=261;
	$UNIT=262;
	$MUNIT=263;
	$SUNIT=264;
	$ZONE=265;
	$DAYZONE=266;
	$AGO=267;
	$YYERRCODE=256;
	@yylhs = (                                               -1,
		0,    0,    1,    1,    1,    1,    1,    1,    7,    2,
		2,    2,    2,    2,    2,    2,    3,    3,    5,    5,
		5,    4,    4,    4,    4,    4,    4,    4,    4,    4,
		6,    6,    6,    6,    6,    6,    6,
	);
	@yylen = (                                                2,
		0,    2,    1,    1,    1,    1,    1,    1,    1,    2,
		3,    4,    4,    5,    6,    6,    1,    1,    1,    2,
		2,    3,    5,    2,    4,    5,    7,    3,    2,    3,
		2,    2,    2,    1,    1,    1,    2,
	);
	@yydefred = (                                             1,
		0,    0,    0,    0,   34,   35,   36,   17,   18,    2,
		3,    4,    5,    6,    0,    8,    0,   20,    0,   21,
	   10,   31,   32,   33,    0,    0,   37,    0,    0,   30,
		0,    0,    0,   25,   12,   13,    0,    0,    0,    0,
	   23,    0,   15,   16,   27,
	);
	@yydgoto = (                                              1,
	   10,   11,   12,   13,   14,   15,   16,
	);
	@yysindex = (                                             0,
	 -241, -255,  -37,  -47,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0, -259,    0,  -42,    0, -252,    0,
		0,    0,    0,    0, -249, -248,    0,  -44, -246,    0,
	  -55,  -31, -235,    0,    0,    0, -234, -232,  -28, -256,
		0, -230,    0,    0,    0,
	);
	@yyrindex = (                                             0,
		0,    0,    1,   79,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,   10,    0,   46,    0,   55,    0,
		0,    0,    0,    0,    0,    0,    0,   19,    0,    0,
	   64,   28,    0,    0,    0,    0,    0,    0,   37,   73,
		0,    0,    0,    0,    0,
	);
	@yygindex = (                                             0,
		0,    0,    0,    0,    0,    0,    0,
	);
	@yytable = (                                             26,
	   19,   29,   37,   43,   44,   17,   18,   27,   30,    7,
	   25,   31,   32,   33,   34,   38,    2,    3,   28,    4,
		5,    6,    7,    8,    9,   39,   40,   22,   41,   42,
	   45,    0,    0,    0,    0,    0,   26,    0,    0,    0,
		0,    0,    0,    0,    0,   24,    0,    0,    0,    0,
		0,    0,    0,    0,   29,    0,    0,    0,    0,    0,
		0,    0,    0,   11,    0,    0,    0,    0,    0,    0,
		0,    0,   14,    0,    0,    0,    0,    0,    9,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,   35,   36,    0,    0,    0,    0,
	   19,   20,   21,    0,   22,   23,   24,    0,   28,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
		0,    0,    0,    0,    0,    0,    0,    0,   19,   19,
		0,   19,   19,   19,   19,   19,   19,    7,    7,    0,
		7,    7,    7,    7,    7,    7,   28,   28,    0,   28,
	   28,   28,   28,   28,   28,   22,   22,    0,   22,   22,
	   22,   22,   22,   22,   26,   26,    0,   26,   26,   26,
	   26,   26,   26,   24,   24,    0,    0,   24,   24,   24,
	   24,   24,   29,   29,    0,    0,   29,   29,   29,   29,
	   29,   11,   11,    0,    0,   11,   11,   11,   11,   11,
	   14,   14,    0,    0,   14,   14,   14,   14,   14,    9,
		0,    0,    0,    9,    9,
	);
	@yycheck = (                                             47,
		0,   44,   58,  260,  261,  261,   44,  267,  261,    0,
	   58,  261,  261,   58,  261,   47,  258,  259,    0,  261,
	  262,  263,  264,  265,  266,  261,  261,    0,  261,   58,
	  261,   -1,   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,    0,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,    0,   -1,   -1,   -1,   -1,   -1,    0,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,  260,  261,   -1,   -1,   -1,   -1,
	  258,  259,  260,   -1,  262,  263,  264,   -1,  261,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
	   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  258,  259,
	   -1,  261,  262,  263,  264,  265,  266,  258,  259,   -1,
	  261,  262,  263,  264,  265,  266,  258,  259,   -1,  261,
	  262,  263,  264,  265,  266,  258,  259,   -1,  261,  262,
	  263,  264,  265,  266,  258,  259,   -1,  261,  262,  263,
	  264,  265,  266,  258,  259,   -1,   -1,  262,  263,  264,
	  265,  266,  258,  259,   -1,   -1,  262,  263,  264,  265,
	  266,  258,  259,   -1,   -1,  262,  263,  264,  265,  266,
	  258,  259,   -1,   -1,  262,  263,  264,  265,  266,  261,
	   -1,   -1,   -1,  265,  266,
	);
	$YYFINAL=1;
	$YYSTACKSIZE = $YYSTACKSIZE || $YYMAXDEPTH || 500;
	$YYMAXDEPTH = $YYMAXDEPTH || $YYSTACKSIZE || 500;
	$yyss[$YYSTACKSIZE] = 0;
	$yyvs[$YYSTACKSIZE] = 0;
}

sub yyclearin { $yychar = -1; }
sub yyerrok { $yyerrflag = 0; }
sub YYERROR { ++$yynerrs; &yy_err_recover; }
sub yy_err_recover {
  if ($yyerrflag < 3)
  {
    $yyerrflag = 3;
    while (1)
    {
      if (($yyn = $yysindex[$yyss[$yyssp]]) && 
          ($yyn += $YYERRCODE) >= 0 && 
          $yycheck[$yyn] == $YYERRCODE)
      {
        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        next yyloop;
      }
      else
      {
        return(1) if $yyssp <= 0;
        --$yyssp;
        --$yyvsp;
      }
    }
  }
  else
  {
    return (1) if $yychar == 0;
    $yychar = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse {
  $yynerrs = 0;
  $yyerrflag = 0;
  $yychar = (-1);

  $yyssp = 0;
  $yyvsp = 0;
  $yyss[$yyssp] = $yystate = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($yyn = $yydefred[$yystate]);
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }
      }
      if (($yyn = $yysindex[$yystate]) && ($yyn += $yychar) >= 0 &&
              $yycheck[$yyn] == $yychar)
      {
        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        $yychar = (-1);
        --$yyerrflag if $yyerrflag > 0;
        next yyloop;
      }
      if (($yyn = $yyrindex[$yystate]) && ($yyn += $yychar) >= 0 &&
            $yycheck[$yyn] == $yychar)
      {
        $yyn = $yytable[$yyn];
        last yyreduce;
      }
      if (! $yyerrflag) {
        &yyerror('syntax error');
        ++$yynerrs;
      }
      return(1) if &yy_err_recover;
    } # yyreduce
    $yym = $yylen[$yyn];
    $yyval = $yyvs[$yyvsp+1-$yym];
    switch:
    {
		if ($yyn == 3) {
			$timeflag++;
			last switch;
		}
		if ($yyn == 4) {
			$zoneflag++;
			last switch;
		}
		if ($yyn == 5) {
			$dateflag++;
			last switch;
		}
		if ($yyn == 6) {
			$dayflag++;
			last switch;
		}
		if ($yyn == 7) {
			$relflag++;
			last switch;
		}
		if ($yyn == 9) {
			if ($timeflag && $dateflag && !$relflag) {
				$year = $yyvs[$yyvsp-0];
			}
			else {
				$timeflag++;
				$hh = int($yyvs[$yyvsp-0] / 100);
				$mm = $yyvs[$yyvsp-0] % 100;
				$ss = 0;
				$merid = 24;
			}
			last switch;
		}
		if ($yyn == 10) {
			$hh = $yyvs[$yyvsp-1];
			$mm = 0;
			$ss = 0;
			$merid = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 11) {
			$hh = $yyvs[$yyvsp-2];
			$mm = $yyvs[$yyvsp-0];
			$merid = 24;
			last switch;
		}
		if ($yyn == 12) {
			$hh = $yyvs[$yyvsp-3];
			$mm = $yyvs[$yyvsp-1];
			$merid = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 13) {
			$hh = $yyvs[$yyvsp-3];
			$mm = $yyvs[$yyvsp-1];
			$merid = 24;
			$daylight = $STANDARD;
			$ourzone = $yyvs[$yyvsp-0] % 100 + 60 * int($yyvs[$yyvsp-0] / 100);
			last switch;
		}
		if ($yyn == 14) {
			$hh = $yyvs[$yyvsp-4];
			$mm = $yyvs[$yyvsp-2];
			$ss = $yyvs[$yyvsp-0];
			$merid = 24;
			last switch;
		}
		if ($yyn == 15) {
			$hh = $yyvs[$yyvsp-5];
			$mm = $yyvs[$yyvsp-3];
			$ss = $yyvs[$yyvsp-1];
			$merid = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 16) {
			$hh = $yyvs[$yyvsp-5];
			$mm = $yyvs[$yyvsp-3];
			$ss = $yyvs[$yyvsp-1];
			$merid = 24;
			$daylight = $STANDARD;
			$ourzone = $yyvs[$yyvsp-0] % 100 + 60 * int($yyvs[$yyvsp-0] / 100);
			last switch;
		}
		if ($yyn == 17) {
			$ourzone = $yyvs[$yyvsp-0];
			$daylight = $STANDARD;
			last switch;
		}
		if ($yyn == 18) {
			$ourzone = $yyvs[$yyvsp-0];
			$daylight = $DAYLIGHT;
			last switch;
		}
		if ($yyn == 19) {
			$dayord = 1;
			$dayreq = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 20) {
			$dayord = 1;
			$dayreq = $yyvs[$yyvsp-1];
			last switch;
		}
		if ($yyn == 21) {
			$dayord = $yyvs[$yyvsp-1];
			$dayreq = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 22) {
			$month = $yyvs[$yyvsp-2];
			$day = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 23) {
			#
			# HACK ALERT!!!!
			# The 1000 is a magic number to attempt to force
			# use of 4 digit years if year/month/day can be
			# parsed. This was only done for backwards
			# compatibility in rh.
			#
			if ($yyvs[$yyvsp-4] > 1000) {
				$year = $yyvs[$yyvsp-4];
				$month = $yyvs[$yyvsp-2];
				$day = $yyvs[$yyvsp-0];
			}
			else {
				$month = $yyvs[$yyvsp-4];
				$day = $yyvs[$yyvsp-2];
				$year = $yyvs[$yyvsp-0];
			}
			last switch;
		}
		if ($yyn == 24) {
			$month = $yyvs[$yyvsp-1];
			$day = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 25) {
			$month = $yyvs[$yyvsp-3];
			$day = $yyvs[$yyvsp-2];
			$year = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 26) {
			$month = $yyvs[$yyvsp-4];
			$day = $yyvs[$yyvsp-3];
			$hh = $yyvs[$yyvsp-2];
			$mm = $yyvs[$yyvsp-0];
			$merid = 24;
			$timeflag++;
			last switch;
		}
		if ($yyn == 27) {
			$month = $yyvs[$yyvsp-6];
			$day = $yyvs[$yyvsp-5];
			$hh = $yyvs[$yyvsp-4];
			$mm = $yyvs[$yyvsp-2];
			$ss = $yyvs[$yyvsp-0];
			$merid = 24;
			$timeflag++;
			last switch;
		}
		if ($yyn == 28) {
			$month = $yyvs[$yyvsp-2];
			$day = $yyvs[$yyvsp-1];
			$year = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 29) {
			$month = $yyvs[$yyvsp-0];
			$day = $yyvs[$yyvsp-1];
			last switch;
		}
		if ($yyn == 30) {
			$month = $yyvs[$yyvsp-1];
			$day = $yyvs[$yyvsp-2];
			$year = $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 31) {
			$relsec +=  60 * $yyvs[$yyvsp-1] * $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 32) {
			$relmonth += $yyvs[$yyvsp-1] * $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 33) {
			$relsec += $yyvs[$yyvsp-1];
			last switch;
		}
		if ($yyn == 34) {
			$relsec +=  60 * $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 35) {
			$relmonth += $yyvs[$yyvsp-0];
			last switch;
		}
		if ($yyn == 36) {
			$relsec++;
			last switch;
		}
		if ($yyn == 37) {
			$relsec = -$relsec;
			$relmonth = -$relmonth;
			last switch;
		}
    } # switch
    $yyssp -= $yym;
    $yystate = $yyss[$yyssp];
    $yyvsp -= $yym;
    $yym = $yylhs[$yyn];
    if ($yystate == 0 && $yym == 0) {
      $yystate = $YYFINAL;
      $yyss[++$yyssp] = $YYFINAL;
      $yyvs[++$yyvsp] = $yyval;
      if ($yychar < 0) {
        if (($yychar = &yylex) < 0) { $yychar = 0; }
      }
      return(0) if $yychar == 0;
      next yyloop;
    }
    if (($yyn = $yygindex[$yym]) && ($yyn += $yystate) >= 0 &&
        $yyn <= $#yycheck && $yycheck[$yyn] == $yystate)
    {
        $yystate = $yytable[$yyn];
    } else {
        $yystate = $yydgoto[$yym];
    }
    $yyss[++$yyssp] = $yystate;
    $yyvs[++$yyvsp] = $yyval;
  } # yyloop
} # yyparse

sub dateconv {
	local($mm, $dd, $yy, $h, $m, $s, $mer, $zone, $dayflag) = @_;
	local($time_of_day, $jdate);
	local($i);

	if ($yy < 0) {
		$yy = -$yy;
	}
	if ($yy < 138) {
		$yy += 1900;
	}
	$mdays[1] =
		28 + (($yy % 4) == 0 && (($yy % 100) != 0 || ($yy % 400) == 0));
	if ($yy < $epoch || $yy > 2037 || $mm < 1 || $mm > 12
		|| $dd < 1 || $dd > $mdays[--$mm]) {
		return -1;
	}
	$jdate = $dd - 1;
	for ($i = 0; $i < $mm; $i++) {
		$jdate += $mdays[$i];
	}
	for ($i = $epoch; $i < $yy; $i++) {
		$jdate += 365 + (($i % 4) == 0);
	}
	$jdate *= $daysec;
	$jdate += $zone * 60;
	if (($time_of_day = &timeconv($h, $m, $s, $mer)) < 0) {
		return -1;
	}
	$jdate += $time_of_day;
	if ($dayflag == $DAYLIGHT
		|| ($dayflag == $MAYBE && (localtime($jdate))[8])) {
		$jdate -= 60 * 60;
	}
	return $jdate;
}

sub dayconv {
	local($ordday, $day, $now) = @_;
	local(@loctime);
	local($time_of_day);

	$time_of_day = $now;
	@loctime = localtime($time_of_day);
	$time_of_day += $daysec * (($day - $loctime[6] + 7) % 7);
	$time_of_day += 7 * $daysec * ($ordday <= 0 ? $ordday : $ordday - 1);
	return &daylcorr($time_of_day, $now);
}

sub timeconv {
	local($hh, $mm, $ss, $mer) = @_;

	return -1 if ($mm < 0 || $mm > 59 || $ss < 0 || $ss > 59);

	if ($mer == $AM) {
		return -1 if ($hh < 1 || $hh > 12);
		return 60 * (($hh % 12) * 60 + $mm) + $ss;
	}
	if ($mer == $PM) {
		return -1 if ($hh < 1 || $hh > 12);
		return 60 * (($hh % 12 + 12) * 60 + $mm) + $ss;
	}
	if ($mer == 24) {
		return -1 if ($hh < 0 || $hh > 23);
		return 60 * ($hh * 60 + $mm) + $ss;
	}
	return -1;
}

sub monthadd {
	local($sdate, $relmonth) = @_;
	local(@ltime);
	local($mm, $yy);
	
	return 0 if ($relmonth == 0);

	@ltime = localtime($sdate);
	$mm = 12 * $ltime[5] + $ltime[4] + $relmonth;
	$yy = int($mm / 12);
	$mm = $mm % 12 + 1;
	return &daylcorr(&dateconv($mm, $ltime[3], $yy, $ltime[2],
							   $ltime[1], $ltime[0], 24, $ourzone, $MAYBE),
					 $sdate);
}

sub daylcorr {
	local($future, $now) = @_;
	local($fdayl, $nowdayl);

	$nowdayl = ((localtime($now))[2] + 1) % 24;
	$fdayl = ((localtime($future))[2] + 1) % 24;
	return ($future - $now) + 60 * 60 * ($nowdayl - $fdayl);
}

sub yylex {
	local($pcnt, $sign);

	while (1) {
		$dtstr =~ s/^\s*//;
		
		if ($dtstr =~ /^([-+])/) {
			$sign = ($1 eq '-') ? -1 : 1;
			$dtstr =~ s/^.\s*//;
			if ($dtstr =~ /^(\d+)/) {
				# Fixed buggy and needless eval "" in case $1 is 09
				# (would fail complaining about bad octal) -- RAM, 10/01/2001
				$yylval = $1 * $sign;
				$dtstr =~ s/^\d+//;
				return $NUMBER;
			}
			else {
				return &yylex;
			}
		}
		elsif ($dtstr =~ /^(\d+)/) {
			# Fixed buggy and needless eval "" in case $1 is 09
			# (would fail complaining about bad octal) -- RAM, 10/01/2001
			$yylval = $1 + 0;
			$dtstr =~ s/^\d+//;
			return $NUMBER;
		}
		elsif ($dtstr =~ /^([a-zA-z][a-zA-Z.]*)/) {
			# Perl 5.0 bug: $1 may be reset to null if &lookup is dataloaded
			$sign = $1;		# Save it for perl 5.0 PL0
			$dtstr = substr($dtstr, length($sign));
			return &lookup($sign);
		}
		elsif ($dtstr =~ /^\(/) {
			$pcnt = 0;
			do {
				$dtstr = s/^(.)//;
				return 0 if !defined($1);
				$pcnt++ if ($1 eq '(');
				$pcnt-- if ($1 eq ')');
			} while ($pcnt > 0);
		}
		else {
			$yylval = ord(substr($dtstr, 0, 1));
			$dtstr =~ s/^.//;
			return $yylval;
		}
	}
}
		
sub lookup_init {
	%mdtab = (
		"January",		"$MONTH,1",
		"February",		"$MONTH,2",
		"March",		"$MONTH,3",
		"April",		"$MONTH,4",
		"May",			"$MONTH,5",
		"June",			"$MONTH,6",
		"July",			"$MONTH,7",
		"August",		"$MONTH,8",
		"September",	"$MONTH,9",
		"Sept",			"$MONTH,9",
		"October",		"$MONTH,10",
		"November",		"$MONTH,11",
		"December",		"$MONTH,12",

		"Sunday",		"$DAY,0",
		"Monday",		"$DAY,1",
		"Tuesday",		"$DAY,2",
		"Tues",			"$DAY,2",
		"Wednesday",	"$DAY,3",
		"Wednes",		"$DAY,3",
		"Thursday",		"$DAY,4",
		"Thur",			"$DAY,4",
		"Thurs",		"$DAY,4",
		"Friday",		"$DAY,5",
		"Saturday",		"$DAY,6"
	);

	$HRS='*60';
	$HALFHR='30';

	%mztab = (
		"a.m.",		"$MERIDIAN,$AM",
		"am",		"$MERIDIAN,$AM",
		"p.m.",		"$MERIDIAN,$PM",
		"pm",		"$MERIDIAN,$PM",
		"nst",		"$ZONE,3 $HRS + $HALFHR",		# Newfoundland
		"n.s.t.",	"$ZONE,3 $HRS + $HALFHR",
		"ast",		"$ZONE,4 $HRS",			# Atlantic
		"a.s.t.",	"$ZONE,4 $HRS",
		"adt",		"$DAYZONE,4 $HRS",
		"a.d.t.",	"$DAYZONE,4 $HRS",
		"est",		"$ZONE,5 $HRS",			# Eastern
		"e.s.t.",	"$ZONE,5 $HRS",
		"edt",		"$DAYZONE,5 $HRS",
		"e.d.t.",	"$DAYZONE,5 $HRS",
		"cst",		"$ZONE,6 $HRS",			# Central
		"c.s.t.",	"$ZONE,6 $HRS",
		"cdt",		"$DAYZONE,6 $HRS",
		"c.d.t.",	"$DAYZONE,6 $HRS",
		"mst",		"$ZONE,7 $HRS",			# Mountain
		"m.s.t.",	"$ZONE,7 $HRS",
		"mdt",		"$DAYZONE,7 $HRS",
		"m.d.t.",	"$DAYZONE,7 $HRS",
		"pst",		"$ZONE,8 $HRS",			# Pacific
		"p.s.t.",	"$ZONE,8 $HRS",
		"pdt",		"$DAYZONE,8 $HRS",
		"p.d.t.",	"$DAYZONE,8 $HRS",
		"yst",		"$ZONE,9 $HRS",			# Yukon
		"y.s.t.",	"$ZONE,9 $HRS",
		"ydt",		"$DAYZONE,9 $HRS",
		"y.d.t.",	"$DAYZONE,9 $HRS",
		"hst",		"$ZONE,10 $HRS",		# Hawaii
		"h.s.t.",	"$ZONE,10 $HRS",
		"hdt",		"$DAYZONE,10 $HRS",
		"h.d.t.",	"$DAYZONE,10 $HRS",

		"gmt",		"$ZONE,0 $HRS",
		"g.m.t.",	"$ZONE,0 $HRS",
		"bst",		"$DAYZONE,0 $HRS",		# British Summer Time
		"b.s.t.",	"$DAYZONE,0 $HRS",
		"eet",		"$ZONE,-2 $HRS",		# European Eastern Time
		"e.e.t.",	"$ZONE,-2 $HRS",
		"eest",		"$DAYZONE,-2 $HRS",		# European Eastern Summer Time
		"e.e.s.t.",	"$DAYZONE,-2 $HRS",
		"met",		"$ZONE,-1 $HRS",		# Middle European Time
		"m.e.t.",	"$ZONE,-1 $HRS",
		"mest",		"$DAYZONE,-1 $HRS",		# Middle European Summer Time
		"m.e.s.t.",	"$DAYZONE,-1 $HRS",
		"wet",		"$ZONE,0 $HRS ",		# Western European Time
		"w.e.t.",	"$ZONE,0 $HRS ",
		"west",		"$DAYZONE,0 $HRS",		# Western European Summer Time
		"w.e.s.t.",	"$DAYZONE,0 $HRS",

		"jst",		"$ZONE,-9 $HRS",		# Japan Standard Time
		"j.s.t.",	"$ZONE,-9 $HRS",		# Japan Standard Time

		"aest",		"$ZONE,-10 $HRS",		# Australian Eastern Time
		"a.e.s.t.",	"$ZONE,-10 $HRS",
		"aesst",	"$DAYZONE,-10 $HRS",	# Australian Eastern Summer Time
		"a.e.s.s.t.",	"$DAYZONE,-10 $HRS",
		"acst",			"$ZONE,-(9 $HRS + $HALFHR)",	# Austr. Central Time
		"a.c.s.t.",		"$ZONE,-(9 $HRS + $HALFHR)",
		"acsst",		"$DAYZONE,-(9 $HRS + $HALFHR)",	# Austr. Central Summer
		"a.c.s.s.t.",	"$DAYZONE,-(9 $HRS + $HALFHR)",
		"awst",			"$ZONE,-8 $HRS",	# Australian Western Time
		"a.w.s.t.",		"$ZONE,-8 $HRS"		# (no daylight time there)
	);

	%unittab = (
		"year",		"$MUNIT,12",
		"month",	"$MUNIT,1",
		"fortnight","$UNIT,14*24*60",
		"week",		"$UNIT,7*24*60",
		"day",		"$UNIT,1*24*60",
		"hour",		"$UNIT,60",
		"minute",	"$UNIT,1",
		"min",		"$UNIT,1",
		"second",	"$SUNIT,1",
		"sec",		"$SUNIT,1"
	);

	%othertab = (
		"tomorrow",	"$UNIT,1*24*60",
		"yesterday","$UNIT,-1*24*60",
		"today",	"$UNIT,0",
		"now",		"$UNIT,0",
		"last",		"$NUMBER,-1",
		"this",		"$UNIT,0",
		"next",		"$NUMBER,2",
		"first",	"$NUMBER,1",
		# "second",	"$NUMBER,2",
		"third",	"$NUMBER,3",
		"fourth",	"$NUMBER,4",
		"fifth",	"$NUMBER,5",
		"sixth",	"$NUMBER,6",
		"seventh",	"$NUMBER,7",
		"eigth",	"$NUMBER,8",
		"ninth",	"$NUMBER,9",
		"tenth",	"$NUMBER,10",
		"eleventh",	"$NUMBER,11",
		"twelfth",	"$NUMBER,12",
		"ago",		"$AGO,1"
	);

	%milzone = (
		"a",		"$ZONE,1 $HRS",
		"b",		"$ZONE,2 $HRS",
		"c",		"$ZONE,3 $HRS",
		"d",		"$ZONE,4 $HRS",
		"e",		"$ZONE,5 $HRS",
		"f",		"$ZONE,6 $HRS",
		"g",		"$ZONE,7 $HRS",
		"h",		"$ZONE,8 $HRS",
		"i",		"$ZONE,9 $HRS",
		"k",		"$ZONE,10 $HRS",
		"l",		"$ZONE,11 $HRS",
		"m",		"$ZONE,12 $HRS",
		"n",		"$ZONE,-1 $HRS",
		"o",		"$ZONE,-2 $HRS",
		"p",		"$ZONE,-3 $HRS",
		"q",		"$ZONE,-4 $HRS",
		"r",		"$ZONE,-5 $HRS",
		"s",		"$ZONE,-6 $HRS",
		"t",		"$ZONE,-7 $HRS",
		"u",		"$ZONE,-8 $HRS",
		"v",		"$ZONE,-9 $HRS",
		"w",		"$ZONE,-10 $HRS",
		"x",		"$ZONE,-11 $HRS",
		"y",		"$ZONE,-12 $HRS",
		"z",		"$ZONE,0 $HRS"
	);

	@mdays = (31, 0, 31,  30, 31, 30,  31, 31, 30,  31, 30, 31);
	$epoch = 1970;
}

sub lookup {
	local($id) = @_;
	local($abbrev, $idvar, $key, $token);

	$idvar = $id;
	if (length($idvar) == 3) {
		$abbrev = 1;
	}
	elsif (length($idvar) == 4 && substr($idvar, 3, 1) eq '.') {
		$abbrev = 1;
		$idvar = substr($idvar, 0, 3);
	}
	else {
		$abbrev = 0;
	}

	substr($idvar, 0, 1) =~ tr/a-z/A-Z/;
	if (defined($mdtab{$idvar})) {
		($token, $yylval) = split(/,/,$mdtab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	foreach $key (keys %mdtab) {
		if ($idvar eq substr($key, 0, 3)) {
			($token, $yylval) = split(/,/,$mdtab{$key});
			$yylval = eval "$yylval";
			return $token;
		}
	}
	
	$idvar = $id;
	if (defined($mztab{$idvar})) {
		($token, $yylval) = split(/,/,$mztab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	
	$idvar =~ tr/A-Z/a-z/;
	if (defined($mztab{$idvar})) {
		($token, $yylval) = split(/,/,$mztab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	
	$idvar = $id;
	if (defined($unittab{$idvar})) {
		($token, $yylval) = split(/,/,$unittab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	
	if ($idvar =~ /s$/) {
		$idvar =~ s/s$//;
	}
	if (defined($unittab{$idvar})) {
		($token, $yylval) = split(/,/,$unittab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	
	$idvar = $id;
	if (defined($othertab{$idvar})) {
		($token, $yylval) = split(/,/,$othertab{$idvar});
		$yylval = eval "$yylval";
		return $token;
	}
	
	if (length($idvar) == 1 && $idvar =~ /[a-zA-Z]/) {
		$idvar =~ tr/A-Z/a-z/;
		if (defined($milzone{$idvar})) {
			($token, $yylval) = split(/,/,$milzone{$idvar});
			$yylval = eval "$yylval";
			return $token;
		}
	}
	
	return $ID;
}

sub main'getdate {
	local($dtstr, $now, $timezone) = @_;
	local(@lt);
	local($sdate);
	local($TZ);

	$odtstr = $dtstr;		# Save it for error report--RAM
	&yyinit;
	&lookup_init unless $lookup_init++;

	if (!$now) {
		$now = time;
	}

	if (!$timezone) {
		$TZ = defined($ENV{'TZ'}) ? ($ENV{'TZ'} ? $ENV{'TZ'} : '') : '';
		if( $TZ =~
		   /^([^:\d+\-,]{3,})([+-]?\d{1,2}(:\d{1,2}){0,2})([^\d+\-,]{3,})?/) {
			$timezone = $2 * 60;
		}
		else {
			$timezone = 0;
		}
	}

	@lt = localtime($now);
	$year = 0;
	$month = $lt[4] + 1;
	$day = $lt[3];
	$relsec = $relmonth = 0;
	$timeflag = $zoneflag = $dateflag = $dayflag = $relflag = 0;
	$daylight = $MAYBE;
	$hh = $mm = $ss = 0;
	$merid = 24;
	
	$dtstr =~ tr/A-Z/a-z/;
	return -1 if &yyparse;
	return -1 if $timeflag > 1 || $zoneflag > 1 || $dateflag > 1 || $dayflag > 1;

	if (!$year) {
		$year = ($month > ($lt[4] + 1)) ? ($lt[5] - 1) : $lt[5];
	}

	if ($dateflag || $timeflag || $dayflag) {
		$sdate = &dateconv($month, $day, $year, $hh, $mm, $ss,
						   $merid, $timezone, $daylight);
		if ($sdate < 0) {
			return -1;
		}
	}
	else {
		$sdate = $now;
		if ($relflag == 0) {
			$sdate -= ($lt[0] + $lt[1] * 60 + $lt[2] * (60 * 60));
		}
	}
	
	$sdate += $relsec + &monthadd($sdate, $relmonth);
	$sdate += &dayconv($dayord, $dayreq, $sdate) if ($dayflag && !$dateflag);
	
	return $sdate;
}

# Mark error within date string with a '^' cursor--RAM
sub yyerror {
	local($parsed) = length($odtstr) - length($dtstr);
	substr($odtstr, $parsed) = '^' .  substr($odtstr, $parsed + 1);
	&'add_log("syntax error in date: $odtstr") if $'loglvl > 5;
}

package main;

