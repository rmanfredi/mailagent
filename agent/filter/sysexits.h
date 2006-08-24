/*

  ####    #   #   ####   ######  #    #     #     #####   ####           #    #
 #         # #   #       #        #  #      #       #    #               #    #
  ####      #     ####   #####     ##       #       #     ####           ######
      #     #         #  #         ##       #       #         #   ###    #    #
 #    #     #    #    #  #        #  #      #       #    #    #   ###    #    #
  ####      #     ####   ######  #    #     #       #     ####    ###    #    #

	Standard exit codes for sendmail and friends.
	Original list maintained by Eric Allman <eric@berkeley.edu>.
*/

/*
 * $Id$
 *
 *  Copyright (c) 1990-2006, Raphael Manfredi
 *  
 *  You may redistribute only under the terms of the Artistic License,
 *  as specified in the README file that comes with the distribution.
 *  You may reuse parts of this distribution only within the terms of
 *  that same Artistic License; a copy of which may be found at the root
 *  of the source tree for mailagent 3.0.
 *
 * $Log: sysexits.h,v $
 * Revision 3.0  1993/11/29  13:48:21  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _sysexits_h_
#define _sysexits_h_

#define EX_OK			0
#define EX_USAGE		64
#define EX_UNAVAILABLE	69
#define EX_OSERR		71
#define EX_OSFILE		72
#define EX_CANTCREAT	73
#define EX_IOERR		74
#define EX_TEMPFAIL		75

#endif
