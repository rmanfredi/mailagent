/*
 * termios_ph.c -- Generates perl configuration for termios.
 */

/*
 * $Id$
 *
 *  Copyright (c) 2008, Raphael Manfredi
 *  
 *  You may redistribute only under the terms of the Artistic License,
 *  as specified in the README file that comes with the distribution.
 *  You may reuse parts of this distribution only within the terms of
 *  that same Artistic License; a copy of which may be found at the root
 *  of the source tree for mailagent 3.0.
 */

/*
 * Only two fields are of interest in struct winsize and need to be unpacked
 * by perl:
 *
 *   . ws_row    The number of rows in the tty
 *   . ws_col    The number of columns in the tty
 *
 * This program generates those perl lines:
 *
 *   $TIOCGWINSZ = 0x1234;			# The TIOCGWINSZ ioctl()
 *   $packfmt = 'SS';    			# ws_row ws_col
 *   $length = 8;					# sizeof(struct winsize)
 *   @fields = ('row', 'col', );
 */

#define MAX_LEN	1024		/* Max length for strings */
#define PADSTR  "..pad.. "	/* Pad string, for comment */

#include "config.h"

#include <stdio.h>

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif

#ifdef I_STDLIB
#include <stdlib.h>
#endif

#ifdef I_TERMIOS
#include <termios.h>
#endif

#ifdef I_SYS_IOCTL
#include <sys/ioctl.h>
#endif

#ifdef I_UNISTD
#include <unistd.h>
#endif

#include "confmagic.h"

#define minimum(a,b)	((a) < (b) ? (a) : (b))
#define maximum(a,b)	((a) < (b) ? (b) : (a))

char *padstr = PADSTR;

#define ADD_ROW \
		strcat(comment, "ws_row "); \
		sprintf(buf, "%c", 'S'); \
		strcat(fields, "'row', ");	\
		last_off += row_len;

#define ADD_COL \
		strcat(comment, "ws_col "); \
		sprintf(buf, "%c", 'S'); \
		strcat(fields, "'col', "); \
		last_off += col_len;

int main()
{
#ifdef I_TERMIOS
	struct winsize *win = (struct winsize *) 0;
	char comment[MAX_LEN];
	char pack[MAX_LEN];
	char fields[MAX_LEN];
	char buf[MAX_LEN];
	int row_off = (int) &win->ws_row;		/* Offset of ws_row */
	int col_off = (int) &win->ws_col;		/* Offset of ws_col */
	int row_len = sizeof(win->ws_row);		/* Size of ws_row */
	int col_len = sizeof(win->ws_col);		/* Size of ws_col */
	int last_off = 0;						/* Last offset in pack format */
	int offset;

	*comment = '\0';		/* So that we may strcat() later */
	*pack = '\0';
	sprintf(fields, "(");

	/*
	 * In case none of ws_row and ws_col begins the structure...
	 */
	if ((last_off = minimum(row_off, col_off)) != 0) {
		strcat(comment, padstr);
		sprintf(pack, "x%d", last_off);
		strcat(fields, "'pad', ");
	}

	/*
	 * Find out which of ws_row and ws_col comes first...
	 */
	if (row_off < col_off) {				/* ws_row is first */
		ADD_ROW;
	} else {
		ADD_COL;
	}
	strcat(pack, buf);

	/*
	 * Possible padding between ws_row and ws_col.
	 */
	offset = maximum(row_off, col_off) - last_off;
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
	if (last_off == col_off) {
		ADD_COL;
	} else {
		ADD_ROW;
	}
	strcat(pack, buf);

	strcat(fields, ")");

	/*
	 * Spit out perl definitions.
	 */
	printf("$TIOCGWINSZ = 0x%x;\t# The TIOCGWINSZ ioctl()\n", TIOCGWINSZ);
	printf("$packfmt = '%s';\t\t# %s\n", pack, comment);
	printf("$length = %d;\t\t\t# sizeof(struct winsize)\n",
		sizeof(struct winsize));
	printf("@fields = %s;\n", fields);
#else
	printf("$TIOCGWINSZ = undef;\t# No termios\n");
#endif	/* I_TERMIOS */

	exit(0);
}

