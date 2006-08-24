/*

 #####    ####   #####    #####    ##    #####   #       ######          #    #
 #    #  #    #  #    #     #     #  #   #    #  #       #               #    #
 #    #  #    #  #    #     #    #    #  #####   #       #####           ######
 #####   #    #  #####      #    ######  #    #  #       #        ###    #    #
 #       #    #  #   #      #    #    #  #    #  #       #        ###    #    #
 #        ####   #    #     #    #    #  #####   ######  ######   ###    #    #

	Some portable declarations.
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
 * $Log: portable.h,v $
 * Revision 3.0  1993/11/29  13:48:20  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _portable_h_
#define _portable_h_

/*
 * Standard types
 */
#if INTSIZE < 4
typedef int int16;
typedef long int32;
typedef unsigned int uint16;
typedef unsigned long uint32;
#else
typedef short int16;
typedef int int32;
typedef unsigned short uint16;
typedef unsigned int uint32;
#endif

/*
 * Scope control pseudo-keywords
 */
#define public				/* default C scope */
#define private static		/* static outside a block means private */
#define shared				/* data shared between modules, but not public */

#endif
