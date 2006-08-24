/*

 #    #   ####    ####           #    #
 ##  ##  #       #    #          #    #
 # ## #   ####   #               ######
 #    #       #  #  ###   ###    #    #
 #    #  #    #  #    #   ###    #    #
 #    #   ####    ####    ###    #    #

	Declaration of message related functions.
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
 * $Log: msg.h,v $
 * Revision 3.0.1.1  1995/08/31  16:24:05  ram
 * patch42: added declaration for new say() routine
 *
 * Revision 3.0  1993/11/29  13:48:17  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _msg_h_
#define _msg_h_

extern void say();					/* For important error messages */
extern void fatal();				/* For fatal errors */

#endif
