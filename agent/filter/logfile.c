/*

 #        ####    ####   ######     #    #       ######           ####
 #       #    #  #    #  #          #    #       #               #    #
 #       #    #  #       #####      #    #       #####           #
 #       #    #  #  ###  #          #    #       #        ###    #
 #       #    #  #    #  #          #    #       #        ###    #    #
 ######   ####    ####   #          #    ######  ######   ###     ####

	Handles logging facilities.
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
 * $Log: logfile.c,v $
 * Revision 3.0.1.5  2001/01/10 16:50:08  ram
 * patch69: fixed incorrect selection of sys_errlist[]
 *
 * Revision 3.0.1.4  1999/01/13  18:07:00  ram
 * patch64: only use last two digits from year in logfiles
 *
 * Revision 3.0.1.3  1997/02/20  11:36:23  ram
 * patch55: prefer open(O_APPEND) to fopen("a") for stdio append bugs
 *
 * Revision 3.0.1.2  1996/12/24  13:58:03  ram
 * patch45: log onto stderr if logfile not opened correctly
 *
 * Revision 3.0.1.1  1994/07/01  14:53:21  ram
 * patch8: metaconfig now defines Strerror instead of strerror
 *
 * Revision 3.0  1993/11/29  13:48:14  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

#ifdef I_TIME
# include <time.h>
#endif
#ifdef I_SYS_TIME
# include <sys/time.h>
#endif
#ifdef I_SYS_TIME_KERNEL
# define KERNEL
# include <sys/time.h>
# undef KERNEL
#endif

/* Get the O_* constants */
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

#include "confmagic.h"

#define MAX_STRING	1024			/* Maximum length for logging string */

private FILE *logfile = (FILE *) 0;	/* File pointer used for logging */
shared int loglvl = 20;				/* Logging level */
private char *logname;				/* Name of the logfile in use */
private void expand();				/* Run the %m %e expansion on the string */
private int add_error();			/* Prints description of error in errno */
private int add_errcode();			/* Print the symbolic error name */

public char *progname = "ram";	/* Program name */
public Pid_t progpid = 0;		/* Program PID */

extern Time_t time();			/* Time in seconds since the Epoch */
extern char *malloc();			/* Memory allocation */
extern char *strsave();			/* Save string in memory */
extern int errno;				/* System error report variable */

/* VARARGS2 */
public void add_log(level, format, arg1, arg2, arg3, arg4, arg5)
int level;
char *format;
long arg1, arg2, arg3, arg4, arg5;	/* Use long instead of int for 64 bits */
{
	/* Add logging informations at specified level. Note that the arguments are
	 * declared as 'int', but it should work fine, even when we give doubles,
	 * because they will be pased "as is" to fprintf. Maybe I should use
	 * vfprintf when it is available--RAM.
	 * The only magic string substitution which occurs is the '%m', which is
	 * replaced by the error message, as given by errno and '%e' which gives
	 * the symbolic name of the error (if available, otherwise the number).
	 * The log file must have been opened with open_log() before add_log calls.
	 */

	struct tm *ct;				/* Current time (pointer to static data) */
	Time_t clock;				/* Number of seconds since the Epoch */
	char buffer[MAX_STRING];	/* Buffer which holds the expanded %m string */
	FILE *stdlog = logfile;		/* Where logging is to be done */

	if (loglvl < level)			/* Logging level is not high enough */
		return;

	if (logfile == (FILE *) 0)	/* Logfile not opened for whatever reason */
		stdlog = stderr;		/* User stderr then -- RAM, 21/10/96 */

	clock = time((Time_t *) 0);	/* Number of seconds */
	ct = localtime(&clock);		/* Get local time from amount of seconds */
	expand(format, buffer);		/* Expansion of %m and %e into buffer */

	fprintf(stdlog, "%.2d/%.2d/%.2d %.2d:%.2d:%.2d %s[%d]: ",
		ct->tm_year % 100, ct->tm_mon + 1, ct->tm_mday,
		ct->tm_hour, ct->tm_min, ct->tm_sec,
		progname, progpid);

	fprintf(stdlog, buffer, arg1, arg2, arg3, arg4, arg5);
	putc('\n', stdlog);
	fflush(stdlog);
}

public int open_log(name)
char *name;
{
	/* Open log file 'name' for logging. If a previous log file was opened,
	 * it is closed before. The routine returns -1 in case of error.
	 */
	
	if (logfile != (FILE *) 0)
		fclose(logfile);
	
	/*
	 * We used to perform an:
	 *		fopen(name, "a");
	 * at this point, but Sudish Joseph <joseph@cis.ohio-state.edu> has
	 * mentionned a possible stdio library bug whereby "a" would do a seek
	 * at the end before writing, hence being the target for a possible race
	 * condition. Use O_APPEND to fix this, if available.
	 */

#ifdef O_APPEND
	{
		int fd;
		fd = open(name, O_WRONLY | O_CREAT | O_APPEND, 0600);
		if (fd == -1)
			return -1;
		logfile = fdopen(fd, "a");
	}
#else
	logfile = fopen(name, "a");		/* Append to existing file */
#endif

	logname = strsave(name);		/* Save file name */

	if (logfile == (FILE *) 0)
		return -1;
	
	return 0;
}

public void close_log()
{
	/* Close log file */

	if (logfile != (FILE *) 0)
		fclose(logfile);

	logfile = (FILE *) 0;
}

public void set_loglvl(level)
int level;
{
	/* Set logging level to 'level' */

	loglvl = level;
}

private void expand(from, to)
char *from;
char *to;
{
	/* The string held in 'from' is copied into 'to' and every '%m' is expanded
	 * into the error message deduced from the value of errno.
	 */

	int len;							/* Length of substituted text */

	while (*to++ = *from)
		if (*from++ == '%')
			switch (*from) {
			case 'm':					/* %m is the English description */
				len = add_error(to - 1);
				to += len - 1;
				from++;
				break;
			case 'e':					/* %e is the symbolic error code */
				len = add_errcode(to - 1);
				to += len - 1;
				from++;
				break;
			}
}

private int add_error(where)
char *where;
{
	/* Prints a description of the error code held in 'errno' into 'where' if
	 * it is available, otherwise simply print the error code number.
	 */

#if !defined(HAS_STRERROR) && defined(HAS_SYS_ERRLIST)
	extern int sys_nerr;					/* Size of sys_errlist[] */
	extern char *sys_errlist[];				/* Maps error code to string */
#endif

#ifdef HAS_STRERROR
	sprintf(where, "%s", strerror(errno));
#else
#ifdef HAS_SYS_ERRLIST
	sprintf(where, "%s", Strerror(errno));	/* Macro defined by Configure */
#else
	sprintf(where, "error #%d", errno);
#endif
#endif

	return strlen(where);
}

private int add_errcode(where)
char *where;
{
	/* Prints the symbolic description of the error code heldin in 'errno' into
	 * 'where' if possible. Otherwise, prints the error number.
	 */
	
#ifdef HAS_SYS_ERRNOLIST
	extern int sys_nerrno;					/* Size of sys_errnolist[] */
	extern char *sys_errnolist[];			/* Error code to symbolic name */
#endif

#ifdef HAS_SYS_ERRNOLIST
	if (errno < 0 || errno >= sys_nerrno)
		sprintf(where, "UNKNOWN");
	else
		sprintf(where, "%s", sys_errnolist[errno]);
#else
		sprintf(where, "%d", errno);
#endif

	return strlen(where);
}

