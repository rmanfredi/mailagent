/*

    #     ####            ####
    #    #    #          #    #
    #    #    #          #
    #    #    #   ###    #
    #    #    #   ###    #    #
    #     ####    ###     ####

	I/O routines.
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
 * $Log: io.c,v $
 * Revision 3.0.1.18  2001/03/17 18:05:04  ram
 * patch72: forgot to increment buf in pool_read() -- from Debian
 *
 * Revision 3.0.1.17  2001/01/10 16:48:56  ram
 * patch69: switched to dynamic init of standard file array for GNU libc
 *
 * Revision 3.0.1.16  1999/07/12  13:43:57  ram
 * patch66: renamed metaconfig obsolete symbol
 * patch66: now uses say() when mail is DUMPED
 *
 * Revision 3.0.1.15  1999/01/13  18:06:18  ram
 * patch64: fixed wrong localization of variables in unique_filename()
 * patch64: additions to agent.wait are more robust and use locking
 *
 * Revision 3.0.1.14  1998/07/28  17:32:33  ram
 * patch63: unique_filename() could loop forever, abort if no locking
 *
 * Revision 3.0.1.13  1998/07/28  16:57:41  ram
 * patch62: fixed race condition whilst electing queue filename
 *
 * Revision 3.0.1.12  1997/09/15  15:01:35  ram
 * patch57: factorized code to derive a unique filename
 *
 * Revision 3.0.1.11  1997/02/20  11:35:20  ram
 * patch55: new io_redirect() routine to handle the -o switch
 *
 * Revision 3.0.1.10  1996/12/26  10:46:11  ram
 * patch51: include <unistd.h> for R_OK and define fallbacks
 * patch51: declared strsave() in case it's not done in <string.h>
 * patch51: fixed an incredible typo while declaring progpath[]
 *
 * Revision 3.0.1.9  1996/12/24  13:57:08  ram
 * patch45: message is now read in a pool, instead of one big chunk
 * patch45: attempt to locate mailagent and perl
 * patch45: perform basic security checks on exec()ed programs
 *
 * Revision 3.0.1.8  1995/08/31  16:19:17  ram
 * patch42: new routine write_fd() to write mail onto an opened file
 * patch42: write_file() now relies on new write_fd() to do its main job
 * patch42: read_stdin() was made a once routine
 * patch42: emergency_save() now attempts to read mail if not done already
 * patch42: emergency_save() will dump message on stdout as a fall back
 *
 * Revision 3.0.1.7  1995/08/07  17:23:26  ram
 * patch41: forgot to return value in agent_lockfile()
 *
 * Revision 3.0.1.6  1995/08/07  16:09:03  ram
 * patch37: avoid forking of a new mailagent if one is sitting in background
 * patch37: added support for locking on filesystems with short filenames
 *
 * Revision 3.0.1.5  1995/03/21  12:54:19  ram
 * patch35: now relies on USE_WIFSTAT to use WIFEXITED() and friends
 *
 * Revision 3.0.1.4  1995/02/03  17:55:55  ram
 * patch30: avoid closing stdio files if not connected to a tty
 *
 * Revision 3.0.1.3  1994/10/04  17:25:54  ram
 * patch17: now detect and avoid possible queue filename conflicts
 *
 * Revision 3.0.1.2  1994/07/01  14:52:04  ram
 * patch8: now honours the queuewait config variable when present
 *
 * Revision 3.0.1.1  1994/01/26  09:27:13  ram
 * patch5: now only try to include <sys/fcntl.h> when hope is lost
 * patch5: filter will now put itself in daemon state while waiting
 *
 * Revision 3.0  1993/11/29  13:48:10  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"

#include <sys/types.h>
#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>

#ifdef I_UNISTD
#include <unistd.h>		/* R_OK and friends */
#endif

#ifdef I_STDLIB
#include <stdlib.h>
#else
#ifdef I_MALLOC
#include <malloc.h>
#else
extern char *malloc();				/* Memory allocation */
#endif
#endif	/* I_STDLIB */

#ifdef I_SYS_WAIT
#include <sys/wait.h>
#endif

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

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif

#ifdef I_SYS_IOCTL
#include <sys/ioctl.h>
#endif

/*
 * The following should be defined in <sys/stat.h>.
 */
#ifndef S_IFMT
#define S_IFMT	0170000		/* Type of file */
#endif
#ifndef S_IFREG
#define S_IFREG	0100000		/* Regular file */
#endif
#ifndef S_IFCHR
#define S_IFCHR	0020000		/* Character special (ttys fall into that) */
#endif
#ifndef S_ISCHR
#define S_ISCHR(m)	(((m) & S_IFMT) == S_IFCHR)
#endif
#ifndef S_ISREG
#define S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)
#endif

#ifndef X_OK
#define X_OK	1			/* Test for execute (search) permission */
#endif
#ifndef R_OK
#define R_OK	4			/* Test for read permission */
#endif

#include "io.h"
#include "hash.h"
#include "parser.h"
#include "lock.h"
#include "logfile.h"
#include "environ.h"
#include "sysexits.h"
#include "msg.h"
#include "confmagic.h"

#define BUFSIZE		1024			/* Amount of bytes read in a single call */
#define CHUNK		(10 * BUFSIZE)	/* Granularity of pool */
#define CHUNKSIZE	(10 * CHUNK)	/* Maximum size of realloc()ed pool */
#define MAX_STRING	2048			/* Maximum string's length */
#define MAX_TRYS	1024			/* Maximum attempts for unique queue file */
#define QUEUE_WAIT	60				/* Default waiting time in queue */
#define AGENT_WAIT	"agent.wait"	/* File listing out-of-the-queue mails */
#define DEBUG_LOG	12				/* Lowest debugging log level */
#ifdef FLEXFILENAMES
#define AGENT_LOCK	"perl.lock"		/* Lock file used by mailagent */
#else
#define AGENT_LOCK	"perl!"			/* Same as above, if filename length < 14 */
#endif

/* The following array of stdio streams is used by close_tty() */
private FILE *stream_by_fd[] = {
	0,		/* file descriptor 0 */
	0,		/* ... 1 */
	0,		/* ... 2 */
};
#define STDIO_FDS	(int) (sizeof(stream_by_fd) / sizeof(FILE *))

private char *agent_lockfile();	/* Name of the mailagent lock */
private int get_lock();			/* Attempt to get a lockfile */
private void release_agent();	/* Remove mailagent's lock if needed */
private int process_mail();		/* Process mail by feeding the mailagent */
private void queue_mail();		/* Queue mail for delayed processing */
private char *write_file();		/* Write mail on disk */
private int write_fd();			/* Write mail onto file descriptor */
private char *save_file();		/* Emergency saving into a file */
private void goto_daemon();		/* Disassociate process from tty */

/*
 * Mail is stored in a linked list of chunks, each chunk being able to
 * contain at most CHUNKSIZE bytes. This prevents exponential memory
 * consumption when facing messages two or three order of magnitude bigger
 * than the basic CHUNK granularity.
 */
struct mail {
	struct pool *first;			/* Data description in successive pools */
	struct pool *last;			/* Last created pool */
	int len;					/* Mail length in bytes */
};
struct pool {
	struct pool *next;			/* Pool data */
	char *arena;				/* Data for this pool chunk */
	int size;					/* Size of data that can be held in arena */
	int offset;					/* Filling offset */
};
private int queued = 0;			/* True when mail queued safely */
private struct mail mail;		/* Where mail is expected to lie */

extern char *logname();			/* User's login name */
extern char *strsave();			/* Save string somewhere in core */
extern void my_exit();
extern int loglvl;				/* Logging level */

private struct pool *pool_alloc(size)
int size;
{
	/* Allocate a new pool of given size, or fail if not enough memory */

	struct pool *lp;

	lp = (struct pool *) malloc(sizeof(struct pool));
	if (!lp)
		goto failed;

	lp->arena = malloc(size);
	if (!lp->arena)
		goto failed;

	lp->size = size;
	lp->offset = 0;				/* Nothing read yet */
	lp->next = 0;				/* Assume we're at the end of chain */

	return lp;

failed:
	fatal("out of memory");
	/* NOTREACHED */
	return NULL;				/* Shut up compiler warnings */
}

private struct pool *pool_init(size)
int size;
{
	/* Initialize mail by creating the first pool */

	mail.first = mail.last = pool_alloc(size);
	mail.len = 0;

	return mail.last;
}

private void pool_extend(pool, size)
struct pool **pool;
int size;
{
	/* Make more room in pool and update parameters accordingly. If we
	 * can extend the size of the pool because we're under the CHUNKSIZE
	 * limit, then do so. Otherwise, allocate a new pool and link it to
	 * the current one, then update our caller's view to point to the new
	 * pool so new allocation is quasi-transparent.
	 */

	struct pool *lp = *pool;	/* Current pool */
	struct pool *np;			/* New pool, if necessary */

	if (lp->size < CHUNKSIZE) {
		lp->size += size;
		lp->arena = realloc(lp->arena, lp->size);
		if (!lp->arena)
			fatal("out of memory");
		return;
	}

	/* Need to create a new pool */

	mail.last = np = pool_alloc(size);
	lp->next = np;
	*pool = np;					/* Update our caller's view */
}

private void pool_read(pool, buf, len)
struct pool **pool;
char *buf;				/* Where data lie */
int len;				/* Amount of data in buf to transfer */
{
	struct pool *lp = *pool;		/* Local pool pointer */
	int fit;						/* Amount of data that can fit */

	while ((fit = len)) {			/* Assume everything will fit */
		if ((lp->offset + len) > lp->size)
			fit = lp->size - lp->offset;

		bcopy(buf, lp->arena + lp->offset, fit);
		buf += fit;
		lp->offset += fit;
		mail.len += fit;

		len -= fit;
		if (len == 0)
			return;					/* Everything fitted in pool */

		pool_extend(&lp, CHUNK);	/* Resize it or fail */
		*pool = lp;					/* Update our caller's view */
	}
}

private int pool_write(fd, pool)
int fd;
struct pool *pool;
{
	/* Write the pool onto fd. We do not call a single write on the pool areana
	 * as in "write(fd, buf, len)" in case the pool length exceeds the maximum
	 * amount of bytes the system can atomically write.
	 *
	 * Returns the amount of bytes written, or -1 on error.
	 */

	register1 char *mailptr;		/* Pointer into arena buffer */
	register2 int length;			/* Number of bytes already written */
	register3 int amount;			/* Amount of bytes written by last call */
	register4 int n;				/* Result from the write system call */
	register5 int len;				/* Bytes remaining to be written */

	for (
		mailptr = pool->arena, length = 0, len = pool->offset;
		length < len;
		mailptr += amount, length += amount
	) {
		amount = len - length;
		if (amount > BUFSIZ)		/* Do not write more than BUFSIZ */
			amount = BUFSIZ;
		n = write(fd, mailptr, amount);
		if (n == -1 || n != amount) {
			if (n == -1)
				add_log(1, "SYSERR write: %m (%e)");
			return -1;
		}
	}

	return length;
}

private void read_stdin()
{
	/* Read the whole stdandard input into memory and return a pointer to its
	 * location in memory. Any I/O error is fatal. Set the length of the
	 * data read into 'len'.
	 *
	 * This routine may be called from two distinct places, but should only
	 * run once, for obvious reasons...
	 */

	int amount = 0;				/* Total amount of data read */
	int n;						/* Bytes read by last system call */
	struct pool *pool;			/* Current pool where input is stored */
	char buf[BUFSIZE];
	static int done = 0;		/* Ensure routine is run once only */

	if (done++) return;

	add_log(19, "reading mail");

	pool = pool_init(CHUNK);

	while ((n = read(0, buf, BUFSIZE))) {
		if (n == -1) {
			add_log(1, "SYSERR read: %m (%e)");
			fatal("I/O error while reading mail");
		}
		pool_read(&pool, buf, n);		/* Copy read bytes */
		amount += n;					/* Update amount of bytes read */
	}

	if (amount != mail.len)
		fatal("corrupted mail: read %d bytes, now has %d", amount, mail.len);

	add_log(16, "got mail (%d bytes)", amount);
}

public void process()
{
	char *queue;						/* Location of mailagent's queue */

	(void) umask(077);					/* Files we create are private ones */

	queue = ht_value(&symtab, "queue");	/* Fetch queue location */
	if (queue == (char *) 0)
		fatal("queue directory not defined");

	read_stdin();						/* Read mail */
	(void) get_lock();					/* Get a lock file */
	queue_mail(queue);					/* Process also it locked */
	release_lock();						/* Release lock file if necessary */
}

public int was_queued()
{
	return queued;			/* Was mail queued? */
}

private int is_main()
{
	/* Test whether we are the main filter (i.e. whether or not we are
	 * entitled to launch a new mailagent process). This is the case when
	 * we were able to grab a filter lock, in which case is_locked() returns
	 * true.
	 *
	 * However, it is also possible a mailagent process put in the background
	 * be processing some mail, albeit the main filter that originally launched
	 * it disappeared. Therefore, we also check for an existing mailagent lock,
	 * when we are locked.
	 */

	char *agentlock;			/* Path of the mailagent lock file */
	struct stat buf;			/* Stat buffer */
	static int done = 0;
	static int result = 0;		/* Assume we're not the main filter */

	if (done)
		return result;
	done = 1;

	if (!is_locked())
		return 0;		/* We're not a main filter, one is already active */

	/*
	 * No filter lock held, we are a candidate for being a main filter!
	 */

	agentlock = agent_lockfile();
	if (-1 == stat(agentlock, &buf)) {
		if (errno != ENOENT) {
			add_log(1, "SYSERR stat: %m (%e)");
			add_log(2, "ERROR cannot stat %s", agentlock);
		}
		return result = 1;	/* No mailagent is currently active */
	}

	if (LOCK_OLD == check_lock(agentlock, "mailagent")) {
		release_agent();
		return result = 1;	/* Old lockfile removed, assume we're the main */
	}

	add_log(5, "NOTICE mailagent seems to be active in background");
	return 0;
}

private int get_lock()
{
	/* Try to get a filter lock in the spool directory. Propagate the return
	 * status of filter_lock(): 0 for ok, -1 for failure.
	 */

	char *spool;						/* Location of spool directory */

	spool = ht_value(&symtab, "spool");	/* Fetch spool location */
	if (spool == (char *) 0)
		fatal("spool directory not defined");

	return filter_lock(spool);			/* Get a lock in spool directory */
}

private char *agent_lockfile()
{
	/* Once function used to compute the path of maialagent's lock file */

	char *spool;					/* Location of spool directory */
	static int done = 0;
	static char agentlock[MAX_STRING];	/* Result */

	if (done)
		return agentlock;

	done = 1;

	spool = ht_value(&symtab, "spool");	/* Fetch spool location */
	if (spool == (char *) 0)			/* Should not happen */
		spool = "";

	sprintf(agentlock, "%s/%s", spool, AGENT_LOCK);
	add_log(12, "mailagent lock in %s", agentlock);

	return agentlock;
}

private void release_agent()
{
	/* In case of abnormal failure, the mailagent may leave its lock file
	 * in the spool directory. Remove it if necessary.
	 */

	struct stat buf;				/* Stat buffer */
	char *agentlock = agent_lockfile();

	if (-1 == stat(agentlock, &buf))
		return;						/* Assume no lock file left behind */

	if (-1 == unlink(agentlock)) {
		add_log(1, "SYSERR unlink: %m (%e)");
		add_log(2, "ERROR could not remove mailagent's lock");
	} else
		add_log(5, "NOTICE removed mailagent's lock");
}

private int unique_filename(buf, format, dir, base)
char buf[];
char *format;
char *dir;
char *base;
{
	/* Compute unique filename in directory dir and store it in buf. The
	 * generated file name will be something like dir/base<pid>, but it
	 * really depends on the value of the sprintf format, usually "%s%d".
	 * A trailing %c may be appended to the format to help getting a unique
	 * name.
	 * Returns opened file descriptor on the elected file ("locked"), or -1.
	 */

	char fmt[MAX_STRING];	/* Final sprintf() format string */
	int try = 0;			/* Count attempts to find a unique filename */
	int alternate = 0;		/* True when alternate naming was chosen */
	char trailer = '\0';	/* Trailer character after pid */

	sprintf(fmt, "%s%s%s", "%s/", format, "%c");

	for (;;) {
		int fd;					/* Opened file */

		sprintf(buf, fmt, dir, base, progpid + try, trailer);

		/*
		 * Must "lock" the file in the queue in case mailagent happens to be
		 * sleeping in the background and wakes up between the time we create
		 * the file and before we get a chance to rename() the temporary file.
		 * When that happens, an empty message would be processed and if the
		 * file system is NFS-mounted, it could be rename()-ed and then unlinked
		 * by mailagent after a so-called "successful" processing... thereby
		 * loosing the message completely.
		 */

		if (-1 == file_lock(buf, buf, 0)) {
			add_log(6, "NOTICE could not lock %s", buf);
			return -1;
		}

		fd = open(buf, O_WRONLY | O_CREAT | O_EXCL, 0600);
		if (fd != -1)
			return fd;			/* Returns "locked" pathname */

		if (errno != EEXIST) {
			add_log(1, "SYSERR open: %m (%e)");
			add_log(2, "ERROR can't create %s", buf);
			file_unlock(buf);
			return -1;
		}

		/*
		 * Must do that now to preserve the value of errno in the test above
		 * for the sake of %m and %e. Alternative would be to save/restore
		 * errno before calling add_log().
		 */

		file_unlock(buf);

		if (++try > MAX_TRYS) {
			if (alternate > ('z' - 'a'))
				fatal("unable to find unique queue filename");
			try = 0;
			trailer = 'a' + alternate++;	/* ASCII-dependant */
		}
	}

	return -1;				/* Unable to find unique filename in dir */
}

private void queue_mail(queue)
char *queue;				/* Location of the queue directory */
{
	char *where;			/* Where mail is stored */
	char real[MAX_STRING];	/* Real queue mail */
	char *base;				/* Pointer to base name */
	struct stat buf;		/* To make sure queued file remains */
	char *type;				/* "qm" or "fm" mails */
	int fd;					/* fd from unique_filename() */

	where = write_file(queue, "Tm");
	if (where == (char *) 0) {
		add_log(1, "ERROR unable to queue mail");
		fatal("try again later");
	}

	/* If we have a lock, create a qm* file suitable for mailagent processing.
	 * Otherwise, create a fm* file and the mailagent will process it
	 * immediately. Because of my paranoid nature, we loop at least MAX_TRYS
	 * to get a unique queue filename (duplicates may happen if mail is
	 * delivered on distinct machines simultaneously with an NFS-mounted queue).
	 * If that's not enough. we try again once for each letter in the alphabet,
	 * adding it as a trailer character for better uniqueness.
	 */

	type = is_main() ? "qm" : "fm";

	if (-1 == (fd = unique_filename(real, "%s%d", queue, type)))
		fatal("unable to find unique queue filename");
	(void) close(fd);

	if (-1 == rename(where, real)) {
		add_log(1, "SYSERR rename: %m (%e)");
		add_log(2, "ERROR could not rename %s into %s", where, real);
		file_unlock(real);		/* Locked by unique_filename() */
		fatal("try again later");
	}

	/* Compute base name of queued mail */
	base = rindex(real, '/');
	if (base++ == (char *) 0)
		base = real;

	add_log(4, "QUEUED [%s] %d bytes", base, mail.len);
	queued = 1;
	file_unlock(real);			/* Better have this after logging QUEUED */

	/* If we got a lock, then no mailagent is running and we may process the
	 * mail. Otherwise, do nothing. The mail will be processed by the currently
	 * active mailagent.
	 */

	if (!is_main())				/* Another mailagent is running */
		return;					/* Leave mail in queue */

	if (0 == process_mail(real)) {
		/* Mailagent may have simply queued the mail for itself by renaming
		 * it, so of course we would not be able to remove it. Hence the
		 * test for ENOENT to avoid error messages when the file does not
		 * exit any more.
		 */
		if (-1 == unlink(real) && errno != ENOENT) {
			add_log(1, "SYSERR unlink: %m (%e)");
			add_log(2, "ERROR could not remove queued mail");
		}
		return;
	}
	/* Paranoia: make sure the queued mail is still there */
	if (-1 == stat(real, &buf)) {
		queued = 0;			/* Or emergency_save() would not do anything */
		add_log(1, "SYSERR stat: %m (%e)");
		add_log(1, "ERROR queue file [%s] vanished", base);
		if (-1 == emergency_save())
			add_log(1, "ERROR mail probably lost");
	} else {
		add_log(4, "WARNING mailagent failed, [%s] left in queue", base);
		release_agent();	/* Remove mailagent's lock file if needed */
	}
}

private char *locate(prog, path)
char *prog;			/* Program to locate within path */
char *path;			/* The path under which we should look for program */
{
	/* Locate specified program within the `path' and return pointer to static
	 * data with the full path of the program when found, or a null pointer
	 * otherwise.
	 */

	static char progpath[MAX_STRING + 1];
	char *cp;					/* Current path pointer */
	char *ep;					/* End of current path component */
	int len;					/* Length of current path component */
	struct stat buf;			/* Stat buffer */
	int proglen = strlen(prog);

	/*
	 * Loop over the path and extract components between `:'. The `cp'
	 * variable points to the beginning of the place to look for the next
	 * component.
	 */

	for (ep = cp = path; ep && *cp; cp = ep ? (ep + 1) : ep) {
		ep = index(cp, ':');				/* Lookup next `:' separator */
		len = ep ? (ep - cp) :
			(int) strlen(cp);				/* Slurp remaining if not found */
		if ((len + proglen + 1) > MAX_STRING) {
			add_log(4, "WARNING skipping directory while looking for %s", prog);
			continue;
		}
		if (len) {
			strncpy(progpath, cp, len);		/* Will not add trailing '\0' */
			progpath[len] = '\0';
		} else
			strcpy(progpath, ".");			/* Good old "null" path field */
		strcat(progpath, "/");
		strcat(progpath, prog);
		if (-1 == stat(progpath, &buf))		/* No entry in file system */
			continue;
		if (!S_ISREG(buf.st_mode))			/* Not a regular file */
			continue;
		if (-1 == access(progpath, R_OK|X_OK)) {
			add_log(4, "WARNING no read and/or execute rights on %s", progpath);
			continue;
		}
		return progpath;		/* Ok, we found it */
	}

	return (char *) 0;			/* Program not found */
}

private int process_mail(location)
char *location;
{
	/* Process mail held in 'location' by invoking the mailagent on it. If the
	 * command fails, return -1. Otherwise, return 0;
	 * Note that we will exit if the first fork is not possible, but that is
	 * harmless, because we know the mail was safely queued, otherwise we would
	 * not be here trying to make the mailagent process it.
	 */

	char **envp;			/* Environment pointer */
#ifdef UNION_WAIT
	union wait status;		/* Waiting status */
#else
	int status;				/* Status from command */
#endif
	int xstat;				/* The exit status value */
	int pid;				/* Pid of our children */
	int res;				/* Result from wait */
	int delay;				/* Delay in seconds before invoking mailagent */
	char *perl;				/* perl path */
	char *mailagent;		/* mailagent path */
	char *path = get_env("PATH");

	if (loglvl <= 20) {		/* Loggging level higher than 20 is for tests */
		pid = fork();
		if (pid == -1) {	/* Resources busy, most probably */
			release_lock();
			add_log(1, "SYSERR fork: %m (%e)");
			add_log(6, "NOTICE exiting to save resources");
			my_exit(EX_OK);	/* Exiting will also release sendmail process */
		} else if (pid != 0)
			my_exit(EX_OK);	/* Release waiting sendmail */
		else
			goto_daemon();	/* Remaining child is to disassociate from tty */
	}

	/*
	 * Compute waiting delay, defaults to QUEUE_WAIT seconds if not defined.
	 */

	delay = get_confval("queuewait", CF_DEFAULT, QUEUE_WAIT);

	/* Now hopefully we detached ourselves from sendmail, which thinks the mail
	 * has been delivered. Not yet, but close. Simply wait a little in case
	 * more mail is comming. This process is going to remain alive while the
	 * mailagent is running so as to trap any weird exit status. But the size
	 * of the perl process (with script compiled) is about 1650K on my MIPS,
	 * so the more we delay the invocation, the better.
	 */

	if (loglvl < DEBUG_LOG)	/* Higher logging level reserverd for debugging */
		sleep(delay);		/* Delay invocation of mailagent */
	progpid = getpid();		/* This may be the child (if fork succeded) */
	envp = make_env();		/* Build new environment */

	/*
	 * We locate both mailagent and perl in the specified path. Not finding
	 * mailagent is a fatal error, but not finding perl simply means we
	 * fall back to the hardwired perl path (determined by Configure).
	 *
	 * Given the sensitive nature of mailagent processing, it is vital to
	 * make sure both perl and mailagent cannot be tampered with by ordinary
	 * users, or that would defeat all sanity checks performed on the config
	 * and rule files.
	 */

	mailagent = locate("mailagent", path);
	if (!mailagent) {
		add_log(1, "ERROR cannot locate mailagent anywhere in PATH");
		if (path)
			add_log(6, "NOTICE looked for mailagent under %s", path);
		return -1;
	} else
		mailagent = strsave(mailagent);		/* Save static data for perusal */

	perl = locate("perl", path);			/* Override hardwired default */
	if (!perl) perl = PERLPATH;				/* ...if possible */

	add_log(12, "perl at %s", perl);
	add_log(12, "mailagent at %s", mailagent);

	if (!(exec_secure(perl) && exec_secure(mailagent))) {
		add_log(1, "ERROR running mailagent would be unsecure");
		return -1;
	}

	/*
	 * Issue a virtual fork and let the child execute mailagent...
	 */

	pid = vfork();			/* Virtual fork this time... */
	if (pid == -1) {
		add_log(1, "SYSERR vfork: %m (%e)");
		add_log(1, "ERROR cannot run mailagent");
		return -1;
	}

	if (pid == 0) {			/* This is the child */
		execle(perl, "perl", mailagent, location, (char *) 0, envp);
		add_log(1, "SYSERR execle: %m (%e)");
		add_log(1, "ERROR cannot run perl to start %s", mailagent);
		my_exit(EX_UNAVAILABLE);
	}

	/* Parent process */

	while (pid != (res = wait(&status)))
		if (res == -1) {
			add_log(1, "SYSERR wait: %m (%e)");
			return -1;
		}

#ifdef USE_WIFSTAT
	if (WIFEXITED(status)) {			/* Exited normally */
		xstat = WEXITSTATUS(status);
		if (xstat != 0) {
			add_log(3, "ERROR mailagent returned status %d", xstat);
			return -1;
		}
	} else if (WIFSIGNALED(status)) {	/* Signal received */
		xstat = WTERMSIG(status);
		add_log(3, "ERROR mailagent terminated by signal %d", xstat);
		return -1;
	} else if (WIFSTOPPED(status)) {	/* Process stopped */
		xstat = WSTOPSIG(status);
		add_log(3, "WARNING mailagent stopped by signal %d", xstat);
		add_log(6, "NOTICE terminating mailagent, pid %d", pid);
		if (-1 == kill(pid, 15))
			add_log(1, "SYSERR kill: %m (%e)");
		return -1;
	} else
		add_log(1, "BUG please report bug 'posix-wait' to author");
#else
#ifdef UNION_WAIT
	xstat = status.w_status;
#else
	xstat = status;
#endif
	if ((xstat & 0xff) == 0177) {		/* Process stopped */
		xstat >>= 8;
		add_log(3, "WARNING mailagent stopped by signal %d", xstat);
		add_log(6, "NOTICE terminating mailagent, pid %d", pid);
		if (-1 == kill(pid, 15))
			add_log(1, "SYSERR kill: %m (%e)");
		return -1;
	} else if ((xstat & 0xff) != 0) {	/* Signal received */
		xstat &= 0xff;
		if (xstat & 0200) {				/* Dumped a core ? */
			xstat &= 0177;
			add_log(3, "ERROR mailagent dumped core on signal %d", xstat);
		} else
			add_log(3, "ERROR mailagent terminated by signal %d", xstat);
		return -1;
	} else {
		xstat >>= 8;
		if (xstat != 0) {
			add_log(3, "ERROR mailagent returned status %d", xstat);
			return -1;
		}
	}
#endif

	add_log(19, "mailagent ok");

	return 0;
}

public int emergency_save()
{
	/* Save mail in emeregency files and add the path to the agent.wait file,
	 * so that the mailagent knows where to look when processing its queue.
	 * Return -1 if the mail was not sucessfully saved, 0 otherwise.
	 */

	char *where;			/* Where file was stored (static data) */
	char *home = homedir();	/* Location of the home directory */
	char path[MAX_STRING];	/* Location of the AGENT_WAIT file */
	char *spool;			/* Location of the spool directory */
	char *emergdir;			/* Emergency directory */
	int fd;					/* File descriptor to write in AGENT_WAIT */
	int size;				/* Length of 'where' string */
	int old_size;			/* Old size of AGENT_WAIT file */
	struct stat buf;		/* To stat AGENT_WAIT */
	int error = 0;			/* Assume no error during AGENT_WAIT writes */
	int locked = 0;			/* True when AGENT_WAIT was locked */

	/*
	 * It is possible that we come here due to a configuration error, for
	 * instance, and that we had not a chance to read our standard input
	 * yet. So do that now.
	 *
	 * Thanks to Rosina Bignall <bigna@leopard.cs.byu.edu> for finding
	 * this hole at her depend ;-)
	 */

	read_stdin();		/* Read mail if not already done yet */

	if (mail.len == 0) {
		say("mail not read, cannot dump");
		return -1;	/* Failed */
	}

	if (queued) {
		add_log(6, "NOTICE mail was safely queued");
		return 0;
	}

	emergdir = ht_value(&symtab, "emergdir");
	if ((emergdir != (char *) 0) && (char *) 0 != (where = save_file(emergdir)))
		goto ok;
	if ((home != (char *) 0) && (char *) 0 != (where = save_file(home)))
		goto ok;
	if ((where = save_file("/usr/spool/uucppublic")))
		goto ok;
	if ((where = save_file("/var/spool/uucppublic")))
		goto ok;
	if ((where = save_file("/usr/tmp")))
		goto ok;
	if ((where = save_file("/var/tmp")))
		goto ok;
	if ((where = save_file("/tmp")))
		goto ok;

	/*
	 * Attempt dumping on stdout, as a fall back.
	 */

	say("dumping mail on stdout...");
	fflush(stderr);		/* In case they did >file 2>&1 */

	if (-1 != write_fd(1, "stdout")) {
		char *logmsg = "DUMPED to stdout";
		say(logmsg);
		add_log(6, logmsg);
		return 0;
	}

	say("unable to dump mail anywhere");
	return -1;	/* Failed */

ok:
	say("DUMPED in %s", where);

	/*
	 * Attempt to write path of saved mail in the AGENT_WAIT file
	 *
	 * The file is locked to prevent concurrent update by mailagent, which
	 * could be regenerating the file. Still, we don't want to wait too much
	 * so only loop for 10 seconds.
	 */

	spool = ht_value(&symtab, "spool");
	if (spool == (char *) 0)
		return 0;

	locked = 0 == file_lock(AGENT_WAIT, "agent.wait", 10);
	if (!locked)
		add_log(6, "WARNING updating %s without lock", AGENT_WAIT);

	sprintf(path, "%s/%s", spool, AGENT_WAIT);
	if (-1 == (fd = open(path, O_WRONLY | O_APPEND | O_CREAT, 0600))) {
		add_log(1, "SYSERR open: %m (%e)");
		add_log(6, "WARNING mailagent ignores mail was left in %s", where);
		if (locked)
			file_unlock(AGENT_WAIT);
		return 0;
	}

	/*
	 * Stat AGENT_WAIT to save the old size, and enable a comparison later
	 * on to really be sure that the path of the message was properly
	 * memorized in there. Yes, this is paranoid, but I was bitten once
	 * by the old code that did not check that.
	 */

	if (-1 == stat(path, &buf)) {
		add_log(1, "SYSERR stat: %m (%e)");
		add_log(6, "WARNING cannot stat %s", path);
		old_size = -1;				/* Mark: old size not available */
	} else
		old_size = buf.st_size;

	size = strlen(where);
	where[size + 1] = '\0';			/* Make room for trailing new-line */
	where[size] = '\n';
	if (-1 == write(fd, where, size + 1)) {
		add_log(1, "SYSERR write: %m (%e)");
		add_log(4, "ERROR could not append to %s", path);
		error++;
	}
	where[size] = '\0';

	if (-1 == close(fd)) {
		add_log(1, "SYSERR close: %m (%e)");
		add_log(4, "ERROR could not flush to %s", path);
		error++;
	}

	if (locked)
		file_unlock(AGENT_WAIT);

	if (-1 == stat(path, &buf)) {
		add_log(1, "SYSERR stat: %m (%e)");
		add_log(6, "WARNING cannot stat %s", path);
		old_size = -1;				/* Disable sanity check below */
	}

	/*
	 * If an error is already recorded, it is useless to do a size
	 * sanity check since the size will not be correct anyway.
	 */

	if (!error && old_size != -1) {
		int expected = old_size + size + 1;
		if (expected != buf.st_size) {
			add_log(2, "ERROR %s truncated to %d bytes (should have had %d)",
				buf.st_size, expected);
			error++;
		}
	} else if (!error)
		add_log(8, "cannot double-check %s was properly flushed", path);

	/*
	 * Setting `queued' to 1 means that, upon exit, filter will return a
	 * success status to the MTA.
	 */

	if (!error) {
		add_log(7, "NOTICE memorized %s", where);
		queued = 1;
	} else
		add_log(6, "WARNING mailagent ignores mail was left in %s", where);

	return 0;
}

private char *save_file(dir)
char *dir;				/* Where saving should be done (directory) */
{
	/* Attempt to write mail in directory 'dir' and return a pointer to static
	 * data holding the path name of the saved file if writing was ok.
	 * Otherwise, return a null pointer and unlink any already created file.
	 */

	struct stat buf;				/* Stat buffer */

	/* Make sure 'dir' entry exists, although we do not make sure it is really
	 * a directory. If 'dir' is in fact a file, then open() will loudly
	 * complain. We only want to avoid spurious log messages.
	 */

	if (-1 == stat(dir, &buf))		/* No entry in file system, probably */
		return (char *) 0;			/* Saving failed */

	return write_file(dir, logname());
}

private char *write_file(dir, template)
char *dir;				/* Where saving should be done (directory) */
char *template;			/* First part of the file name */
{
	/* Attempt to write mail in directory 'dir' and return a pointer to static
	 * data holding the path name of the saved file if writing was ok.
	 * Otherwise, return a null pointer and unlink any already created file.
	 * The file 'dir/template.$$' is created (where '$$' refers to the pid of
	 * the current process). As login name <= 8 and pid is <= 5, we are below
	 * the fatidic 14 chars limit for filenames.
	 */

	static char path[MAX_STRING];	/* Path name of created file */
	int fd;							/* File descriptor */
	int status;						/* Status from write_fd() */
	struct stat buf;				/* Stat buffer */

	if (-1 == (fd = unique_filename(path, "%s.%d", dir, template)))
		return (char *) 0;

	status = write_fd(fd, path);		/* Write mail to file descriptor fd */
	file_unlock(path);					/* Was locked by unique_filename */
	close(fd);
	if (status == -1)					/* Something wrong happened */
		goto error;

	add_log(19, "mail in %s", path);	/* We did not detect any error so far */

	/* I don't really trust writes through NFS soft-mounted partitions, and I
	 * am also suspicious about hard-mounted ones. I could have opened the file
	 * with the O_SYNC flag, but the effect on NFS is not well defined either.
	 * So, let's just make sure the mail has been correctly written on the disk
	 * by comparing the file size and the orginal message size. If they differ,
	 * complain and return an error.
	 */

	if (-1 == stat(path, &buf))		/* No entry in file system, probably */
		return (char *) 0;			/* Saving failed */

	if (buf.st_size != mail.len) {	/* Not written entirely */
		add_log(2, "ERROR mail truncated to %d bytes (had %d)",
			buf.st_size, mail.len);
		goto error;					/* Remove file and report error */
	}

	return path;			/* Where mail was writen (static data) */

error:		/* Come here when a write error has been detected */

	if (-1 == unlink(path)) {
		add_log(1, "SYSERR unlink: %m (%e)");
		add_log(4, "WARNING leaving %s around", path);
	}

	return (char *) 0;
}

private int write_fd(fd, path)
int fd;					/* On which file descriptor saving occurs */
char *path;				/* Path name associated with that fd (may be NULL) */
{
	/* Write mail to the specified fd and return 0 if OK, -1 on error.
	 * Since mail is scattered amongst various pools of at most CHUNKSIZE
	 * bytes, we loop against all pools and write them in turn.
	 */

	struct pool *lp;

	for (lp = mail.first; lp; lp = lp->next) {
		if (-1 == pool_write(fd, lp)) {
			if (path != (char *) 0)
				add_log(2, "ERROR cannot write to file %s", path);
			return -1;	/* Failed */
		}
	}

	return 0;			/* OK */
}

private void close_tty(fd)
int fd;
{
	/* Close file if attached to a tty, otherwise do nothing. This is used
	 * by goto_daemon() to close file descriptors related to a tty to try
	 * to void any tty associations if other modern methods have failed.
	 * Unfortunately, we cannot just blindly close those descriptors in
	 * case output was redirected to some file...
	 */

	struct stat buf;				/* Stat buffer */

	if (-1 == fstat(fd, &buf)) {
		add_log(1, "SYSERR fstat: %m (%e)");
		add_log(6, "WARNING could not stat file descriptor #%d", fd);
		return;		/* Don't close it then */
	}

	/*
	 * The GNU libc had this bight idea to make stdin, stdout and stderr
	 * unsuitable for static initialization.  Wonderful.  Do it an runtime
	 * then.  -- RAM, 05/01/2001
	 */

	if (!stream_by_fd[0]) {
		stream_by_fd[0] = stdin;
		stream_by_fd[1] = stdout;
		stream_by_fd[2] = stderr;
	}
		
	/* Close file descriptor if attached to a tty. Otherwise, flush it if
	 * it is of the standard I/O kind, in case we did some buffered fprintf()
	 * on those.
	 */

	if (S_ISCHR(buf.st_mode)) {		/* File is a character device (tty) */
		if (fd < STDIO_FDS)
			(void) fclose(stream_by_fd[fd]);
		else
			(void) close(fd);
	} else if (fd < STDIO_FDS)
		(void) fflush(stream_by_fd[fd]);
}

private void goto_daemon()
{
	/* Make sure filter process goes into daemon state by releasing its
	 * control terminal and becoming the leader of a new process group
	 * or session.
	 *
	 * Harald Koch <chk@enfm.utcc.utoronto.ca> reported that this was
	 * needed when filter is invoked by zmailer's transport process.
	 * Otherwise the father waiting for his children does not get to see
	 * the EOF on the pipe, hanging forever.
	 */

	int fd;

#ifdef USE_TIOCNOTTY
	/*
	 * Errors from this open are discarded, since it is quite possible
	 * filter be launched without a controling tty, for instance when
	 * called via a daemon process like sendmail... :-)
	 */
	if ((fd = open("/dev/tty", 2)) >= 0) {
		if (-1 == ioctl(fd, TIOCNOTTY, (char *) 0)) {
			add_log(1, "SYSERR ioctl: %m (%e)");
			add_log(6, "WARNING could not release tty control");
		}
		(void) close(fd);
	}
#endif

	(void) close_tty(0);
	(void) close_tty(1);
	(void) close_tty(2);

	if (-1 == setsid()) {
		add_log(1, "SYSERR setsid: %m (%e)");
		add_log(6, "WARNING did not become session leader");
	}
}

public int io_redirect(filename, is_setid, ruid)
char *filename;			/* Filename for redirection */
int is_setid;			/* True when set[ug]id */
int ruid;				/* Real uid */
{
	/* Redirect stdout and stderr to specified filename. When is_setid
	 * is true, we don't create the file but only append to it, and
	 * only if the file is owned by the real uid.
	 * Returns true if operation succeeded, false otherwise.
	 */

	int fd;					/* New fd created for new stdout/stderr */
	int stdfd;				/* Saved stderr file descriptor */
	struct stat buf;		/* Stat buffer */

	if (is_setid) {			/* Pre-check file when running set[ug]id */
		if (-1 == stat(filename, &buf)) {
			if (errno != ENOENT) {
				add_log(1, "SYSERR stat: %m (%e)");
				add_log(2, "ERROR cannot stat %s", filename);
				return 0;	/* Failed */
			}
			add_log(1, "ERROR cannot create %s when running set[ug]id",
				filename);
			return 0;
		}
		if ((int) buf.st_uid != ruid) {
			add_log(1, "ERROR cannot append to %s (not owned by UID %d)",
				filename, ruid);
			return 0;
		}
	}

	/*
	 * Now open the specified file.
	 *
	 * The pre-checking above, meant to spot errors, also opens a
	 * race-condition wrt. the file ownership, when running set[ug]id.
	 * Closing it would mean using the real uid to perform the open, which
	 * is hard to do portably (need to switch to the real uid and back to
	 * the effective later on).
	 *
	 * Workaround: we open the file, and re-check the opened fd via a fstat().
	 * We close it without writing anything if the ownership is not right.
	 * Note that we forbid the creation explicitely when running set[ug]id.
	 */

	fd = open(filename, O_WRONLY | O_APPEND | (is_setid ? 0 : O_CREAT), 0600);
	if (fd == -1) {
		add_log(1, "SYSERR open: %m (%e)");
		return 0;
	}

	if (is_setid) {			/* Re-check file when running set[ug]id */
		if (-1 == fstat(fd, &buf)) {	/* Note we stat() the fd! */
			close(fd);
			add_log(1, "SYSERR stat: %m (%e)");
			add_log(2, "ERROR can't locate %s after opening", filename);
			return 0;
		}
		if ((int) buf.st_uid != ruid) {
			close(fd);
			add_log(1, "ERROR cannot append to %s (not owned by UID %d)",
				filename, ruid);
			return 0;
		}
	}

	/*
	 * Time to redirect the new fd to 1 and 2.
	 * Keep the original stderr file descriptor around, in case there is
	 * a dup2() failure.
	 */

	stdfd = dup(2);
	fflush(stderr);		/* In case we have to force a write() on 2 below */

	if (-1 == dup2(fd, 1) || -1 == dup2(fd, 2)) {
		add_log(1, "SYSERR dup2: %m (%e)");
		if (-1 == dup2(stdfd, 2)) {		/* #2 may have been closed by dup2 */
			char *msg = "Emergency restore of stderr failed...";
			write(stdfd, msg, strlen(msg));		/* They might see this */
		}
		close(stdfd);
		close(fd);
		return 0;
	}

	close(stdfd);
	close(fd);
	return 1;		/* OK -- stderr and stdout redirected */
}

#ifndef HAS_RENAME
public int rename(from, to)
char *from;				/* Original name */
char *to;				/* Target name */
{
	(void) unlink(to);
	if (-1 == link(from, to))
		return -1;
	if (-1 == unlink(from))
		return -1;

	return 0;
}
#endif

#ifndef HAS_SETSID
public int setsid()
{
	/* Set the process group ID and create a new session for the process.
	 * This is a pale imitation of the setsid() system call. Actually, we
	 * go into a lot more trouble here than is really needed...
	 */

	int error = 0;

#ifdef HAS_SETPGID
	/*
	 * setpgid() supersedes setpgrp() in OSF/1.
	 */
	error = setpgid(0 ,getpid());
#else
#ifdef HAS_SETPGRP
	/*
	 * Good old way to get a process group leader.
	 */
#ifdef USE_BSD_SETPGRP
	error = setpgrp(0 ,getpid());	/* bsd way */
#else
	error = setpgrp();				/* usg way */
#endif
#endif
#endif

	/*
	 * When none of the above is defined, do nothing.
	 */

	return error;
}
#endif

