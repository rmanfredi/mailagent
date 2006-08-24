/*

 #        ####    ####   #    #          #    #
 #       #    #  #    #  #   #           #    #
 #       #    #  #       ####            ######
 #       #    #  #       #  #     ###    #    #
 #       #    #  #    #  #   #    ###    #    #
 ######   ####    ####   #    #   ###    #    #

	Declarations for locking routines.
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
 * $Log: lock.h,v $
 * Revision 3.0.1.2  1997/09/15  15:02:36  ram
 * patch57: new generic file_lock() and file_unlock() routines
 *
 * Revision 3.0.1.1  1995/08/07  16:10:17  ram
 * patch37: exported check_lock() for external mailagent lock checks in io.c
 *
 * Revision 3.0  1993/11/29  13:48:12  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _lock_h_
#define _lock_h_

extern int filter_lock();		/* Lock filter */
extern void release_lock();		/* Release lock if necessary */
extern int check_lock();		/* Check lock for excessive lifetime */
extern int is_locked();			/* Do we have a lock file? */
extern int file_lock();			/* Lock arbitrary file */
extern void file_unlock();		/* Unlock arbitrary file */

/*
 * Returned values for check_lock().
 */

#define LOCK_ERR	-1		/* Error, ernno set accordingly */
#define LOCK_OK		0		/* Ok, lock missing or young enough */
#define LOCK_OLD	1		/* Lock removed */

#endif
