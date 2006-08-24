/*
 * utmp_ph.c -- Generates perl packing format for struct utmp.
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
 * $Log: utmp_ph.c,v $
 * Revision 3.0.1.1  1994/10/29  18:13:23  ram
 * patch20: created
 *
 */

/*
 * Only two fields are of interest to us and need to be unpacked by perl:
 *
 *   . ut_name[]	The user's login name
 *   . ut_line[]    The device name where user is connected
 *
 * Padding is inserted so that the total length of the pack format is the
 * length of a utmp structure.
 *
 * This program generates those perl lines:
 *
 *   $packfmt = 'A32x14A32x142';    # ut_name[32] ..pad.. ut_line[32] ..pad..
 *   $length = 156;                 # sizeof(struct utmp)
 *   @fields = ('user', 'pad', 'line', 'pad');
 */

#include "config.h"

#define MAX_LEN		1024		/* Maximum length for strings */
#define PADSTR		"..pad.. "	/* Pad string, for comment */

#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif

#include <utmp.h>
#include "confmagic.h"

#define minimum(a,b)	((a) < (b) ? (a) : (b))
#define maximum(a,b)	((a) < (b) ? (b) : (a))

char *padstr = PADSTR;

#define ADD_USER \
		strcat(comment, "ut_name[] "); \
		sprintf(buf, "A%d", user_len); \
		strcat(fields, "'user', ");	\
		last_off += user_len;

#define ADD_LINE \
		strcat(comment, "ut_line[] "); \
		sprintf(buf, "A%d", line_len); \
		strcat(fields, "'line', "); \
		last_off += line_len;

main()
{
	struct utmp *utmp = (struct utmp *) 0;
	char comment[MAX_LEN];
	char pack[MAX_LEN];
	char fields[MAX_LEN];
	char buf[MAX_LEN];
	int user_off = (int) utmp->ut_name;		/* Offset of ut_name[] */
	int line_off = (int) utmp->ut_line;		/* Offset of ut_line[] */
	int user_len = sizeof(utmp->ut_name);	/* Length of ut_name[] array */
	int line_len = sizeof(utmp->ut_line);	/* Length of ut_line[] array */
	int last_off = 0;						/* Last offset in pack format */
	int offset;

	*comment = '\0';		/* So that we may strcat() later */
	*pack = '\0';
	sprintf(fields, "(");

	/*
	 * In case none of ut_name[] and ut_line[] begins the structure...
	 */
	if ((last_off = minimum(user_off, line_off)) != 0) {
		strcat(comment, padstr);
		sprintf(pack, "x%d", last_off);
		strcat(fields, "'pad', ");
	}

	/*
	 * Find out which of ut_name[] and ut_line[] comes first...
	 */
	if (user_off < line_off) {				/* ut_name[] first */
		ADD_USER;
	} else {
		ADD_LINE;
	}
	strcat(pack, buf);

	/*
	 * Possible padding between ut_name[] and ut_line[].
	 */
	offset = maximum(user_off, line_off) - last_off;
	if (offset > 0) {
		strcat(comment, padstr);
		strcat(fields, "'pad', ");
		sprintf(buf, "x%d", offset);
		strcat(pack, buf);
		last_off += offset;
	}

	/*
	 * Last field before final padding.
	 */
	if (last_off == line_off) {
		ADD_LINE;
	} else {
		ADD_USER;
	}
	strcat(pack, buf);

	/*
	 * Final offsetting.
	 */
	offset = sizeof(struct utmp) - last_off;
	strcat(comment, padstr);
	strcat(fields, "'pad')");
	sprintf(buf, "x%d", offset);
	strcat(pack, buf);

	/*
	 * Spit out perl definitions.
	 */
	printf("$packfmt = '%s';\t\t# %s\n", pack, comment);
	printf("$length = %d;\t\t\t\t\t# sizeof(struct utmp)\n",
		sizeof(struct utmp));
	printf("@fields = %s;\n", fields);

	exit(0);
}

