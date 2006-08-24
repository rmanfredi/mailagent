/*

 #    #   ####   ######  #####            ####
 #    #  #       #       #    #          #    #
 #    #   ####   #####   #    #          #
 #    #       #  #       #####    ###    #
 #    #  #    #  #       #   #    ###    #    #
  ####    ####   ######  #    #   ###     ####

	Compute user login name.
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
 * $Log: user.c,v $
 * Revision 3.0  1993/11/29  13:48:21  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <sys/types.h>					/* For uid_t */
#include <pwd.h>

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif
#include "confmagic.h"

#define LOGIN_LEN	8					/* Maximum login name length */

extern struct passwd *getpwuid();		/* Get password entry for UID */
extern Uid_t geteuid();					/* Effective user UID */

public char *logname()
{
	/* Return pointer to static data holding the user login name. Note that we
	 * look-up in /etc/passwd. Hence, if the user has duplicate entries in the
	 * file, the first one will be reported. This may or may not bother you.
	 * NB: we use the *effective* user ID, not the real one.
	 */
	
	static char login[LOGIN_LEN + 1];	/* Where login name is stored */
	struct passwd *pw;					/* Pointer to password entry */

	pw = getpwuid(geteuid());			/* Get first entry matching UID */
	if (pw == (struct passwd *) 0)
		return (char *) 0;				/* User not found */

	strncpy(login, pw->pw_name, LOGIN_LEN);
	login[LOGIN_LEN] = '\0';

	return login;
}

