/*
 * dup2.C -- A dup2 emulation.
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
 * Original Author: Larry Wall <lwall@netlabs.com>
 *
 * $Log: dup2.c,v $
 * Revision 3.0.1.1  1997/02/20  11:34:52  ram
 * patch55: created
 *
 * Revision 3.0.1.1  1994/01/24  13:58:37  ram
 * patch16: created
 *
 */

#include "config.h"

#ifndef HAS_DUP2

#ifdef I_FCNTL
#include <fcntl.h>
#endif

#include "confmagic.h"		/* Remove if not metaconfig -M */

/*
 * dup2
 *
 * This routine duplicates file descriptor 'old' into 'new'. After the
 * operation, both 'new' and 'old' refer to the same file 'old' was referring
 * to in the first place.
 *
 * Returns 0 if OK, -1 on failure with errno being set to indicate the error.
 * 
 */
V_FUNC(int dup2, (old, new),
	int old 	/* Opened file descriptor */ NXT_ARG
	int new		/* File descriptor we'd like to get */)
{
#ifdef HAS_FCNTL
#ifdef F_DUPFD
#define USE_FNCTL
#endif
#endif

#ifdef USE_FCNTL
	if (old == new)
		return 0;

	close(new);
	return fcntl(old, F_DUPFD, new);
#else
	int fd_used[256];		/* Fixed stack used to record dup'ed files */
	int fd_top = 0;			/* Top in the fixed stack */
	int fd;					/* Currently dup'ed file descriptor */

	if (old == new)
		return 0;

	close(new);						/* Ensure one free slot */
	while ((fd = dup(old)) != new)	/* Until dup'ed file matches */
		fd_used[fd_top++] = fd;		/* Remember we have to close it later */
	
	while (fd_top > 0)				/* Close all useless dup'ed slots */
		close(fd_used[--fd_top]);
	
	return 0;
#endif
}

#else
int dup2_variable_not_used = 1;		/* Avoid "empty file" */
#endif	/* HAS_DUP2 */

