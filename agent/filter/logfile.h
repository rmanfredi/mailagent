/*

 #        ####    ####   ######     #    #       ######          #    #
 #       #    #  #    #  #          #    #       #               #    #
 #       #    #  #       #####      #    #       #####           ######
 #       #    #  #  ###  #          #    #       #        ###    #    #
 #       #    #  #    #  #          #    #       #        ###    #    #
 ######   ####    ####   #          #    ######  ######   ###    #    #

	Declarations for logging.
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
 * $Log: logfile.h,v $
 * Revision 3.0  1993/11/29  13:48:15  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _logfile_h_
#define _logfile_h_

#include "config.h"

/* Routine defined by logging package */
extern void add_log();			/* Add logging message */
extern int open_log();			/* Open logging file */
extern void close_log();		/* Close logging file */
extern void set_loglvl();		/* Set logging level */

/* The following need to be set externally but are defined here */
extern char *progname;			/* Program name */
extern Pid_t progpid;			/* Program PID */

#endif

