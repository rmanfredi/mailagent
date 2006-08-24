/*

    #     ####           #    #
    #    #    #          #    #
    #    #    #          ######
    #    #    #   ###    #    #
    #    #    #   ###    #    #
    #     ####    ###    #    #

	Declarations of I/O routines.
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
 * $Log: io.h,v $
 * Revision 3.0.1.1  1997/02/20  11:35:33  ram
 * patch55: declared io_redirect()
 *
 * Revision 3.0  1993/11/29  13:48:11  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _io_h_
#define _io_h_

extern void process();				/* Process mail */
extern int emergency_save();		/* Save mail in emeregency file */
extern int was_queued();			/* Was mail safely queued or not? */
extern int io_redirect();			/* Redirect stderr and stdout */

#endif
