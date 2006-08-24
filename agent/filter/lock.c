/*

 #        ####    ####   #    #           ####
 #       #    #  #    #  #   #           #    #
 #       #    #  #       ####            #
 #       #    #  #       #  #     ###    #
 #       #    #  #    #  #   #    ###    #    #
 ######   ####    ####   #    #   ###     ####

	Lock file handling.
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
 * $Log: lock.c,v $
 * Revision 3.0.1.5  1997/09/15  15:02:18  ram
 * patch57: added more generic file_lock() and file_unlock() routines
 *
 * Revision 3.0.1.4  1995/08/07  16:10:04  ram
 * patch37: exported check_lock() for external mailagent lock checks in io.c
 * patch37: added support for locking on filesystems with short filenames
 *
 * Revision 3.0.1.3  1995/01/03  17:55:11  ram
 * patch24: now correctly includes <sys/fcntl.h> as a last option only
 *
 * Revision 3.0.1.2  1994/09/22  13:44:52  ram
 * patch12: typo fix to enable correct lockfile timeout printing
 *
 * Revision 3.0.1.1  1994/07/01  14:52:28  ram
 * patch8: now honours the lockhold config variable if present
 *
 * Revision 3.0  1993/11/29  13:48:12  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_SYS_FILE
#include <sys/file.h>
#endif

#ifndef I_FCNTL
#ifndef I_SYS_FILE
#include <sys/fcntl.h>	/* Try this one in last resort */
#endif
#endif

#include "parser.h"
#include "lock.h"
#include "confmagic.h"

#define MAX_STRING	2048		/* Max string length */
#define MAX_TIME	3600		/* One hour */

private char lockfile[MAX_STRING];		/* Location of main filter lock file */
private int locked = 0;					/* Did we lock successfully? */

extern int errno;						/* System error status */
extern Time_t time();					/* Current time */

public int filter_lock(dir)
char *dir;						/* Where lockfile should be written */
{
	/* Note: this locking is not completly safe w.r.t. race conditions, but the
	 * mailagent will do its own locking checks in a rather safe way.
	 * Return 0 if locking succeeds, -1 otherwise.
	 */

	struct stat buf;

	if (-1 == stat(dir, &buf)) {
		add_log(1, "SYSERR stat: %m (%e)");
		add_log(2, "ERROR can't stat directory %s", dir);
		return 0;
	}

	sprintf(lockfile, "%s/filter", dir);

	if (0 == file_lock(lockfile, "filter", 0))
		locked = 1;				/* We did lock successfully */

	return locked ? 0 : -1;
}

public void release_lock()
{
	if (!locked)
		return;

	file_unlock(lockfile);
	locked = 0;
}

public int is_locked()
{
	return locked;			/* Do we have a lock file active or not? */
}

/*
 * lockname
 *
 * Generate lockfile name.
 *
 * Be consistent with mailagent's behaviour: when flexible filenames are
 * available, the locking extenstion is .lock. However, when filenames are
 * limited in length, it is reduced to the single '!' character. Here,
 * the name filter.lock is smaller than 14 characters anyway, so it would
 * not matter much.
 */
#ifdef FLEXFILENAMES
#define lockname(b, p)	sprintf(b, "%s.lock", p)
#else
#define lockname(b, p)	sprintf(b, "%s!", p)
#endif


public int check_lock(file, name)
char *file;
char *name;		/* System name for which the lock is checked */
{
	/* Make sure the lock file is not older than MAX_TIME seconds, otherwise
	 * unlink it (something must have gone wrong). If the lockhold parameter
	 * is set in ~/.mailagent, use that instead for timeout.
	 *
	 * Returns LOCK_OK if lockfile was ok or missing, LOCK_ERR on error and
	 * LOCK_OLD if it was too old and got removed.
	 */

	struct stat buf;
	int hold;					/* Lockfile timeout */
	int ret = LOCK_OK;			/* Returned value */

	if (-1 == stat(file, &buf)) {		/* Stat failed */
		if (errno == ENOENT)			/* File does not exist */
			return LOCK_OK;
		add_log(1, "SYSERR stat: %m (%e)");
		add_log(2, "could not check lockfile %s", file);
		return LOCK_ERR;
	}

	/*
	 * Get lockhold if defined, or use hardwired MAX_TIME.
	 */

	hold = get_confval("lockhold", CF_DEFAULT, MAX_TIME);

	/*
	 * Break lock if older than 'hold' seconds, otherwise honour it.
	 */

	if (time((Time_t *) 0) - buf.st_mtime > hold) {
		if (-1 == unlink(file)) {
			add_log(1, "SYSERR unlink: %m (%e)");
			add_log(4, "WARNING could not remove old lock %s", file);
			ret = LOCK_ERR;
		} else {
			add_log(6, "UNLOCKED %s (lock older than %d seconds)", name, hold);
			ret = LOCK_OLD;		/* File was removed */
		}
	} else
		add_log(16, "lockfile for %s is recent (%d seconds or less)",
			name, hold);

	return ret;		/* Lock file ok, removed, or error status */
}

public int file_lock(path, name, max_loops)
char *path;			/* Path of file to lock */
char *name;			/* "name" of lock file, in case we have to break it */
int max_loops;		/* Amount of waiting loops (1 second each) */
{
	/* Lock file by creating a .lock file, returning 0 if OK, -1 otherwise */

	char lockpath[MAX_STRING];
	int fd = -1;

	lockname(lockpath, path);
	(void) check_lock(lockpath, name);

	while (max_loops-- >= 0) {
		if (-1 != (fd = open(lockpath, O_CREAT | O_EXCL, 0)))
			break;
		if (errno != EEXIST) {
			add_log(1, "ERROR can't create %s: %m (%e)", lockpath);
			return -1;
		}
		sleep(1);
	}

	if (fd == -1)
		return -1;				/* Did not lock file */

	(void) close(fd);			/* Close dummy file descriptor */
	return 0;					/* OK, did lock */
}

void file_unlock(path)
char *path;
{
	/* Unlock named file presumably locked by file_lock() */

	char lockpath[MAX_STRING];

	lockname(lockpath, path);

	if (-1 == unlink(lockpath)) {
		add_log(1, "SYSERR unlink: %m (%e)");
		add_log(4, "WARNING could not remove lock file %s", lockpath);
	}
}

