/*

 #    #     #     ####    ####            ####
 ##  ##     #    #       #    #          #    #
 # ## #     #     ####   #               #
 #    #     #         #  #        ###    #
 #    #     #    #    #  #    #   ###    #    #
 #    #     #     ####    ####    ###     ####

	Miscellaneous routines.
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
 * $Log: misc.c,v $
 * Revision 3.0.1.3  1997/09/15  15:03:04  ram
 * patch57: cosmetic change
 *
 * Revision 3.0.1.2  1996/12/24  13:59:15  ram
 * patch45: new my_exit() to allow exit code tracing for debugging
 *
 * Revision 3.0.1.1  1994/09/22  13:45:30  ram
 * patch12: added fallback implementation for strcasecmp()
 *
 * Revision 3.0  1993/11/29  13:48:16  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <ctype.h>
#include "sysexits.h"
#include "confmagic.h"

extern char *malloc();				/* Memory allocation */

public char *strsave(string)
char *string;
{
	/* Save string somewhere in memory and return a pointer to the new string
	 * or NULL if there is not enough memory.
	 */

	char *new = malloc(strlen(string) + 1);		/* +1 for \0 */
	
	if (new == (char *) 0)
		fatal("no more memory to save strings");

	strcpy(new, string);
	return new;
}

public void my_exit(code)
int code;
{
	/* Exit, but log the exit code... */

	char *name;					/* Symbolic error code name */
	char buf[20];				/* For unknown error codes */

#define symname(x)		case x: name = STRINGIFY(x); break;

	switch (code) {
	symname(EX_OK);
	symname(EX_USAGE);
	symname(EX_UNAVAILABLE);
	symname(EX_OSERR);
	symname(EX_OSFILE);
	symname(EX_CANTCREAT);
	symname(EX_IOERR);
	symname(EX_TEMPFAIL);
	default:
		sprintf(buf, "%d", code);
		name = buf;
		break;
	}

#undef symname

	add_log(11, "exit %s", name);
	exit(code);
}

#ifndef HAS_STRCASECMP
/*
 * This is a rather inefficient version of the strcasecmp() routine which
 * compares two strings in a case-independant manner. The libc routine uses
 * an array, which when indexed by character code, directly yields the lower
 * case version of that character. Here however, since the routine is only
 * used in a few places, we don't bother being as efficient.
 */
public int strcasecmp(s1, s2)
char *s1;
char *s2;
{
	char c1, c2;

	while (c1 = *s1++, c2 = *s2++, c1 && c2) {
		if (isupper(c1))
			c1 = tolower(c1);
		if (isupper(c2))
			c2 = tolower(c2);
		if (c1 != c2)
			break;			/* Strings are different */
	}

	return c1 - c2;			/* Will be 0 if both string ended */
}
#endif

