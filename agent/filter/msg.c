/*

 #    #   ####    ####            ####
 ##  ##  #       #    #          #    #
 # ## #   ####   #               #
 #    #       #  #  ###   ###    #
 #    #  #    #  #    #   ###    #    #
 #    #   ####    ####    ###     ####

	Fatal messages.
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
 * $Log: msg.c,v $
 * Revision 3.0.1.5  1999/01/13  18:08:06  ram
 * patch64: added tag-checking heuristic to say()
 *
 * Revision 3.0.1.4  1996/12/24  13:59:31  ram
 * patch45: call my_exit() instead of exit()
 *
 * Revision 3.0.1.3  1995/08/31  16:22:00  ram
 * patch42: new routine say() to print messages onto stderr
 * patch42: all messages on stderr now also include the filter pid
 * patch42: fatal() now prefixes its supplied reason with FATAL
 *
 * Revision 3.0.1.2  1995/08/07  16:10:55  ram
 * patch37: commented and re-organized fatal code for emergency saving
 *
 * Revision 3.0.1.1  1994/09/22  13:46:01  ram
 * patch12: made fatal() arguments long rather than int for 64-bit machines
 *
 * Revision 3.0  1993/11/29  13:48:17  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <stdio.h>
#include <sys/types.h>
#include <ctype.h>
#include "sysexits.h"
#include "logfile.h"
#include "lock.h"
#include "io.h"
#include "confmagic.h"

#define MAX_STRING	1024		/* Maximum length for error string */

extern Pid_t progpid;			/* Program PID */

/* VARARGS2 */
public void say(msg, arg1, arg2, arg3, arg4, arg5)
char *msg;
long arg1, arg2, arg3, arg4, arg5;	/* Use longs, hope (char *) fits in it! */
{
	/* Write important message to stderr */

	fprintf(stderr, "%s[%d]: ", progname, progpid);
	fprintf(stderr, msg, arg1, arg2, arg3, arg4, arg5);
	fputc('\n', stderr);

	/*
	 * A little heuristic here...
	 *
	 * If the message begins with an upper-cased don't prepend
	 * the ERROR tag, assuming a tag was already specified.
	 */

	if (isupper(msg[0]))
		add_log(2, msg, arg1, arg2, arg3, arg4, arg5);
	else {
		char buffer[MAX_STRING];
		sprintf(buffer, "ERROR %s", msg);
		add_log(2, buffer, arg1, arg2, arg3, arg4, arg5);
	}
}

/* VARARGS2 */
public void fatal(reason, arg1, arg2, arg3, arg4, arg5)
char *reason;
long arg1, arg2, arg3, arg4, arg5;	/* Use longs, hope (char *) fits in it! */
{
	/* Fatal error -- die with a meaningful error status for sendmail. If the
	 * logfile has been opened, the reason will also be logged there.
	 */
	char buffer[MAX_STRING];
	int status;						/* Status from emergency_save() */
	
	/*
	 * Attempt a save as early as possible, since we might not recover
	 * from a fprintf() if we came here on a SIGSEGV or a SIGBUS.
	 */

	status = emergency_save();		/* Attempt emergency saving */

	fprintf(stderr, "%s[%d]: FATAL ", progname, progpid);
	fprintf(stderr, reason, arg1, arg2, arg3, arg4, arg5);
	fputc('\n', stderr);

	sprintf(buffer, "FATAL %s", reason);
	add_log(1, buffer, arg1, arg2, arg3, arg4, arg5);

	release_lock();		/* We're about to exit, free grabbed resources */

	/*
	 * If the emergency saving failed, then the message is not queued
	 * anywhere. We're about to leave the message in the MTA queue in
	 * that case, but we must warn them since we have no guarantee the
	 * MTA will do as we think it will.
	 */

	if (status == -1)
		add_log(5, "WARNING no saving was ever done");

	if (!was_queued()) {
		/*
		 * Exit with a meaningful exit code for the MTA (sendmail usually) so
		 * that it leaves the message in its own queue for later delivery when
		 * conditions * are better (hopefully), or it will bounce to the sender
		 * after some delay.
		 */

		add_log(6, "NOTICE leaving mail in MTA's queue");
		my_exit(EX_TEMPFAIL);
	}

	/*
	 * Message was saved somewhere where mailagent will find it (either in
	 * its queue, or listed in the agent.wait file). There's no need for
	 * the MTA to worry, hence the following...
	 */

	my_exit(EX_OK);
}

