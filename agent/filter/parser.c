/*

 #####     ##    #####    ####   ######  #####            ####
 #    #   #  #   #    #  #       #       #    #          #    #
 #    #  #    #  #    #   ####   #####   #    #          #
 #####   ######  #####        #  #       #####    ###    #
 #       #    #  #   #   #    #  #       #   #    ###    #    #
 #       #    #  #    #   ####   ######  #    #   ###     ####

	Parse a configuration file.
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
 * $Log: parser.c,v $
 * Revision 3.0.1.13  1997/09/15  15:03:51  ram
 * patch57: changed ordering of include files
 *
 * Revision 3.0.1.12  1997/02/20  11:38:07  ram
 * patch55: skip group-writable and exec-safe checks if told to
 *
 * Revision 3.0.1.11  1997/01/31  18:07:11  ram
 * patch54: forgot one more get_confval vs get_confstr translation
 *
 * Revision 3.0.1.10  1997/01/08  08:42:31  ram
 * patch53: must use get_confstr() to get at the execsafe variable
 *
 * Revision 3.0.1.9  1997/01/07  18:27:57  ram
 * patch52: don't perform extended exec() checks when execsafe is OFF
 *
 * Revision 3.0.1.8  1996/12/26  10:46:35  ram
 * patch51: include <unistd.h> for X_OK and define fallbacks
 *
 * Revision 3.0.1.7  1996/12/24  14:01:13  ram
 * patch45: enhanced security checks performed on files
 * patch45: the _ character was not correctly parsed in variables
 *
 * Revision 3.0.1.6  1995/08/31  16:25:42  ram
 * patch42: now uses say() to print messages on stderr
 *
 * Revision 3.0.1.5  1995/08/07  16:11:13  ram
 * patch37: removed useless local variable declaration
 *
 * Revision 3.0.1.4  1995/02/03  17:56:15  ram
 * patch30: moved definition of S_IWOTH and S_IWGRP to the top
 *
 * Revision 3.0.1.3  1994/09/22  13:47:21  ram
 * patch12: extended security checks to mimic those done by mailagent
 *
 * Revision 3.0.1.2  1994/07/01  14:53:57  ram
 * patch8: new routine get_confval to get integer config variables
 *
 * Revision 3.0.1.1  1994/01/26  09:27:37  ram
 * patch5: typo fix in a comment
 *
 * Revision 3.0  1993/11/29  13:48:18  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include <sys/types.h>
#include <stdio.h>
#include <ctype.h>
#include <pwd.h>
#include <sys/stat.h>

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif

#ifdef I_SYS_PARAM
#include <sys/param.h>
#endif
#ifndef MAX_PATHLEN
#define MAX_PATHLEN		2048		/* Maximum path length allowed by kernel */
#endif

#ifndef HAS_GETHOSTNAME
#ifdef HAS_UNAME
#include <sys/utsname.h>
#endif
#endif

#ifdef I_UNISTD
#include <unistd.h>		/* X_OK and friends */
#endif

#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_SYS_FILE
#include <sys/file.h>	/* Needed for X_OK */
#endif

#ifndef I_FCNTL
#ifndef I_SYS_FILE
#include <sys/fcntl.h>	/* Try this one in last resort */
#endif
#endif

/*
 * The following should be defined in <sys/stat.h>.
 */
#ifndef S_IWOTH
#define S_IWOTH 00002		/* Write permissions for other */
#endif
#ifndef S_IWGRP
#define S_IWGRP 00020		/* Write permissions for group */
#endif
#ifndef S_ISUID
#define S_ISUID 04000		/* Set user ID on execution */
#endif
#ifndef S_ISGID
#define S_ISGID 02000		/* Set group ID on execution */
#endif

#ifndef X_OK
#define X_OK	1			/* Test for execute (search) permission */
#endif

#include "hash.h"
#include "msg.h"
#include "parser.h"
#include "logfile.h"
#include "environ.h"
#include "confmagic.h"

#define MAX_STRING	2048			/* Maximum length for strings */
#define SYMBOLS		50				/* Expected number of symbols */

/* check_perm flags */
#define MUST_OWN	0x0001			/* File/directory must be owned */
#define MAY_PANIC 	0x0002			/* Whether we may panic */
#define SECURE_ON 	0x0004			/* Force secure tests */

/* Function declarations */
public void read_conf();			/* Read configuration file */
public void set_env_vars();			/* Set envrionment variables */
public int exec_secure();			/* Checks whether exec() is safe on file */
private void secure();				/* Perform basic security checks on file */
private int check_perm();			/* Check permissions on file */
private void get_home();			/* Extract home from /etc/passwd */
private void substitute();			/* Variable and ~ substitutions */
private void add_home();			/* Replace ~ with home directory */
private void add_variable();		/* Replace $var by its value */
private void insert_value();		/* Record variable value in H table */
private char *machine_name();		/* Return the machine name */
private char *strip_down();			/* Strip down domain name from host name */
private void strip_comment();		/* Strip trailing comment in config line */
private void start_log();			/* Start up logging */

private char *home = (char *) 0;	/* Location of the home directory */
public struct htable symtab;		/* Symbol table */

extern char *strsave();				/* Save string value in memory */
extern struct passwd *getpwuid();	/* Fetch /etc/passwd entry from uid */
extern char *getenv();				/* Get environment variable */

public void read_conf(myself, file)
char *myself;
char *file;
{
	/* Read file in the home directory and build a symbol H table on the fly.
	 * The ~ substitution and usual $var substitution occur (but not ${var}).
	 * As we go, we perform basic sanity and security checks on the overall
	 * configuration.
	 */
	
	char path[MAX_STRING];			/* Full path of the config file */
	char *rules;					/* Path of the rule file, if any */
	char mailagent[MAX_STRING];		/* Path of the configuration file */
	FILE *fd;						/* File descriptor used for config file */
	int line = 0;					/* Line number */
	struct stat buf;				/* Statistics buffer */

	if (home == (char *) 0)			/* Home not already artificially set */
		get_home();					/* Get home directory via /etc/passwd */

	/* Build full path for configuration file, based on $HOME */
	strcpy(path, home);
	strcat(path, "/");
	strcat(path, file);
	strcpy(mailagent, path);		/* Save configuration path for later */

	fd = fopen(path, "r");
	if (fd == (FILE *) 0)
		fatal("cannot open config file %s", path);

	/* Initialize the H table */
	if (-1 == ht_create(&symtab, SYMBOLS))
		fatal("cannot create symbol table");

	while((char *) 0 != fgets(path, MAX_STRING - 1, fd)) {
		line ++;					/* One more line */
		substitute(path);			/* Standard parameter substitutions */
		insert_value(path, line);	/* Record value in hash table */
	}
	fclose(fd);


	/* Some security checks are in order here, or someone could set up a fake
	 * a config file for us and then let the mailagent execute arbitrary 
	 * commands under our uid. These tests are performed after the parsing of
	 * the file, to allow logging of errors.
	 */

	start_log();					/* Start up loging */
	secure(mailagent);				/* Perform basic security checks */

	/* Final security check on the rule file, if provided. The constraints are
	 * the same as those for the ~/.mailagent configuration file. This is
	 * because a rule can specify a RUN command, which will start a process
	 * with the user's privileges.
	 */

	rules = get_confstr_opt("rules");	/* Fetch rules location */
	if (rules)							/* No rule file is perfectly fine */
		check_perm(rules, MUST_OWN | MAY_PANIC);	/* Might not exist */

	/* Make sure I cannot get compromised... */
	if (*myself == '/') {				/* Only possible with absoulte path */
		add_log(19, "checking myself at %s", myself);
		if (!exec_secure(myself)) {
			char *error = "ERROR --FILTER PROGRAM CAN BE TAMPERED WITH--";
			say(error);					/* Make sure they see it */
			add_log(1, error);
		}
	}

	/* And that the .forward which invoked me is secure... */
	strcpy(path, home);
	strcat(path, "/");
	strcat(path, ".forward");
	if (-1 != stat(path, &buf)) {	/* File exists, not called manually */
		add_log(19, "checking %s", path);
		if (!exec_secure(path)) {
			char *error = "ERROR --YOUR .forward FILE CAN BE TAMPERED WITH--";
			say(error);					/* Make sure they see it */
			add_log(1, error);
		}
	}
}

private void start_log()
{
	/* Start up logging, if possible. Note that not defining a logging
	 * directory or a logging level is a fatal error.
	 */

	char logfile[MAX_STRING];		/* Location of logfile */
	char *value;					/* Symbol value */
	int level = 0;					/* Logging level wanted */

	value = get_confstr("logdir", CF_MANDATORY);
	strcpy(logfile, value);
	strcat(logfile, "/");						/* Logging directory */

	value = get_confstr("log", CF_MANDATORY);	/* Log file basename*/
	strcat(logfile, value);

	level = get_confval("level", CF_MANDATORY);

	set_loglvl(level);						/* Logging level wanted */
	if (-1 == open_log(logfile))
		say("cannot open logfile %s", logfile);
}

private void stat_check(file)
char *file;
{
	/* Make sure we can stat() the file */

	struct stat buf;				/* Statistics buffer */

	if (-1 == stat(file, &buf)) {
		add_log(1, "SYSERR stat: %m (%e)");
		fatal("cannot stat file %s", file);
	}
}

private void secure(file)
char *file;
{
	/* Make sure the file is owned by the effective uid, and that it is not
	 * world writable. Otherwise, simply abort with a fatal error.
	 * Returning from this routine implies that the security checks succeeded.
	 */

	stat_check(file);
	check_perm(file, MUST_OWN | MAY_PANIC);	/* Check permissions */
}

public int exec_secure(file)
char *file;
{
	/* Same checks as secure(), but without file/directory ownership.
	 * We propagate SECURE_ON only when execsafe is ON or when the
	 * user is the superuser.
	 *
	 * When execskip is ON, we don't perform the exec() checks at all.
	 * This variable if OFF by default, i.e. they must explicitely
	 * turn it ON to disable checking.
	 */

	char *execsafe = get_confstr("execsafe", CF_DEFAULT, "OFF");
	char *execskip = get_confstr("execskip", CF_DEFAULT, "OFF");
	int flag = (0 == strcasecmp(execsafe, "ON") || ROOTID == geteuid()) ?
		SECURE_ON : 0;

	stat_check(file);
	if (0 == strcasecmp(execskip, "ON"))
		return 1;
	return check_perm(file, flag);		/* Check permissions */
}

/* VARARGS3 */
private void check_fatal(flags, reason, arg1, arg2, arg3, arg4, arg5)
int flags;
char *reason;
long arg1, arg2, arg3, arg4, arg5;
{
	/* Die with a fatal error if MAY_PANIC is specified in flags, otherwise
	 * simply log the error.
	 */

	char buffer[MAX_STRING];

	if (flags & MAY_PANIC)
		fatal(reason, arg1, arg2, arg3, arg4, arg5);

	sprintf(buffer, "ERROR %s", reason);
	add_log(1, buffer, arg1, arg2, arg3, arg4, arg5);
}

private int check_perm(file, flags)
char *file;
int flags;	/* MAY_PANIC | MUST_OWN */
{
	/* Check basic permissions on the specified file. It cannot be world
	 * writable and must be owned by the user. If the file specified does not
	 * exist, no error is reported however. If the 'secure' option is set
	 * to ON, or if we are running with superuser credentials, further checks
	 * are performed on the directory containing the file.
	 *
	 * We return true if the file is OK, false otherwise, unless MAY_PANIC
	 * is activated in which case we don't return but exit with fatal().
	 */

	struct stat buf;			/* Statistics buffer */
	char parent[MAX_PATHLEN+1];	/* For parent directory */
	char *cfsecure;				/* Config value for the 'secure' parameter */
	char *c;					/* Last slash position in file name */
	int wants_secure = 0;		/* Set to true for extra security checks */
	int wants_group = 1;		/* Set to true unless 'groupsafe' is OFF */

	if (-1 == stat(file, &buf))
		return 0;				/* Missing file is not secure! */

	if (buf.st_mode & S_IWOTH) {
		check_fatal(flags, "file %s is world writable!", file);
		return 0;			/* Failed checks */
	}

	if ((flags & MUST_OWN) && buf.st_uid != geteuid()) {
		check_fatal(flags, "file %s not owned by user!", file);
		return 0;			/* Failed checks */
	}

	/*
	 * If file is setuid of setgid, make sure only the owner can write to
	 * it. It's too critical and the system might not clear the set[ug]id bit
	 * on a write to the file.
	 */

	if (-1 != access(file, X_OK)) {			/* User may execute the file */
		if ((buf.st_mode & S_ISUID) && (buf.st_mode & (S_IWOTH|S_IWGRP))) {
			check_fatal(flags, "setuid file %s is writable!", file);
			return 0;
		}
		if ((buf.st_mode & S_ISGID) && (buf.st_mode & (S_IWOTH|S_IWGRP))) {
			check_fatal(flags, "setgid file %s is writable!", file);
			return 0;
		}
	}

	cfsecure = get_confstr_opt("secure");	/* Do they want extra security? */
	if (
		(flags & SECURE_ON) ||				/* They want secure checks anyway */
		(cfsecure != (char *) 0 &&			/* Ok, secure is defined */
		0 == strcasecmp(cfsecure, "ON")) ||	/* And extra checks wanted */
		geteuid() == ROOTID					/* Running as superuser */
	)
		wants_secure = 1;					/* Activate checks */
			
	if (!wants_secure) {
		add_log(12, "basic checks ok for file %s", file);
		return 1;			/* OK */
	}

	/*
	 * Extra security checks for group writability and parent directory.
	 */

	add_log(17, "performing additional checks on %s", file);

	if (0 == strcasecmp(get_confstr("groupsafe", CF_DEFAULT, "ON"), "OFF"))
		wants_group = 0;			/* They trust all the groups! */

	if (wants_group && (buf.st_mode & S_IWGRP)) {
		check_fatal(flags, "file %s is group writable!", file);
		return 0;			/* Failed checks */
	}

	/*
	 * Ok, go on and check the parent directory...
	 */

	if (*file != '/') {				/* Path is not abosule, assume from home */
		strcpy(parent, home);		/* Prefill with home */
		strcat(parent, "/");
	} else
		*parent = '\0';				/* Null string */
	strcat(parent, file);			/* Append file to get an absolute path */
	if ((c = rindex(parent, '/')))
		*c = '\0';					/* Strip down last path component */

	add_log(17, "checking directory %s", parent);

	if (-1 == stat(parent, &buf)) {
		add_log(1, "SYSERR stat: %m (%e)");
		check_fatal(flags, "cannot stat directory %s", parent);
		return 0;			/* Failed checks */
	}

	if (buf.st_mode & S_IWOTH) {
		check_fatal(flags, "directory %s is world writable!", parent);
		return 0;			/* Failed checks */
	}

	if (wants_group && (buf.st_mode & S_IWGRP)) {
		check_fatal(flags, "directory %s is group writable!", parent);
		return 0;			/* Failed checks */
	}

	if ((flags & MUST_OWN) && buf.st_uid != geteuid()) {
		check_fatal(flags, "directory %s not owned by user!", parent);
		return 0;			/* Failed checks */
	}

	add_log(12, "file %s seems to be secure", file);
	return 1;				/* OK */
}

public char *homedir()
{
	return home;			/* Location of the home directory */
}

public void env_home()
{
	home = getenv("HOME");		/* For tests only -- see main.c */
	if (home != (char *) 0)
		home = strsave(home);	/* POSIX getenv() returns ptr to static data */
}

private void get_home()
{
	/* Get home directory out of /etc/passwd file */

	struct passwd *pp;				/* Pointer to passwd entry */

	pp = getpwuid(geteuid());
	if (pp == (struct passwd *) 0)
		fatal("cannot locate home directory");
	home = strsave(pp->pw_dir);
	if (home == (char *) 0)
		fatal("no more memory");
}

public void set_env_vars(envp)
char **envp;				/* The environment pointer */
{
	/* Set the all environment variable correctly. If the configuration file
	 * defines a variable of the form 'p_host' where "host" is the lowercase
	 * name of the machine (domain name stripped), then that value is prepended
	 * to the current value of the PATH variable. We also set HOME and TZ if
	 * there is a 'timezone' variable in the config file.
	 */

	char *machine = machine_name();		/* The machine name */
	char *path_val;						/* Path value to append */
	char *tz;							/* Time zone value */
	char name[MAX_STRING];				/* Built 'p_host' */

	init_env(envp);						/* Built the current environment */

	/* If there is a path: entry in the ~/.mailagent, it is used to replace
	 * then current PATH value. This entry is of course not mandatory. If not
	 * present, we'll simply prepend the added path 'p_host' to the existing
	 * value provided by sendmail, cron, or whoever invoked us.
	 */
	path_val = get_confstr_opt("path");
	if (path_val != (char *) 0) {
		if (-1 == set_env("PATH", path_val))
			fatal("cannot initialize PATH");
	}

	sprintf(name, "p_%s", machine);		/* Name of field in ~/.mailagent */
	path_val = get_confstr_opt(name);	/* Exists ? */
	if (path_val != (char *) 0) {		/* Yes, prepend its value */
		add_log(19, "updating PATH with '%s' from config file", name);
		if (-1 == prepend_env("PATH", ":"))
			fatal("cannot set PATH variable");
		if (-1 == prepend_env("PATH", path_val))
			fatal("cannot set PATH variable");
	}

	/* Also set a correct value for the home directory */
	if (-1 == set_env("HOME", home))
		fatal("cannot set HOME variable");

	/* If there is a 'timezone' variable, set TZ accordingly */
	tz = get_confstr("timezone", CF_DEFAULT, (char *) 0);	/* Exists ? */
	if (tz != (char *) 0) {
		if (-1 == set_env("TZ", tz))
			add_log(1, "ERROR cannot set TZ variable");
	}
}

public char *get_confstr(name, type, dflt)
char *name;		/* Option name */
int type;		/* Type: mandatory or may be defaulted */
char *dflt;		/* Default value to be used if option not defined */
{
	/* Return string value for option and use default if not defined, or
	 * raise a fatal error when option is mandatory.
	 */

	char buffer[MAX_STRING];
	char *namestr;		/* String in H table */
	char *val = dflt;	/* Returned value */

	namestr = ht_value(&symtab, name);
	if (namestr == (char *) 0) {
		switch(type) {
		case CF_MANDATORY:	/* Variable should have been defined */
			sprintf(buffer, "variable '%s' not defined in config file", name);
			fatal(buffer);
			/* NOTREACHED */
		case CF_DEFAULT:	/* May use default if variable not defined */
			break;
		default:
			fatal("BUG: get_confval");
		}
	} else
		val = namestr;

	return val;
}

public int get_confval(name, type, dflt)
char *name;		/* Option name */
int type;		/* Type: mandatory or may be defaulted */
int dflt;		/* Default value to be used if option not defined */
{
	/* Return int value for option and use default if not defined, or yield a
	 * fatal error when option is mandatory.
	 */

	char *namestr;		/* String in H table */
	int val;			/* Returned value */

	namestr = get_confstr(name, type, (char *) 0);
	if (namestr == (char *) 0)		/* get_confstr() panics if CF_MANDATORY */
		return dflt;

	sscanf(namestr, "%d", &val);
	return val;
}


private void substitute(value)
char *value;
{
	/* Run parameter and ~ substitution in-place */

	char buffer[MAX_STRING];		/* Copy on which we work */
	char *ptr = buffer;				/* To iterate over the buffer */

	strcpy(buffer, value);			/* Make a copy of original line */
	while ((*value++ = *ptr)) {		/* Line is updated in-place */
		switch(*ptr++) {
		case '~':					/* Replace by home directory */
			add_home(&value);
			break;
		case '$':					/* Variable substitution */
			add_variable(&value, &ptr);
			break;
		}
	}
}

private void add_home(to)
char **to;						/* Pointer to address in substituted text */
{
	/* Add home directory at the current location. If the 'home' symbol has
	 * been found, use that instead.
	 */

	char *value = *to - 1;		/* Go back to overwrite the '~' */
	char *ptr = home;			/* Where home directory string is stored */
	char *symbol;				/* Symbol entry for 'home' */

	if (strlen(home) == 0)		/* As a special case, this is empty when */
		ptr = "/";				/* referring to the root directory */

	symbol = ht_value(&symtab, "home");		/* Maybe we saw  'home' already */
	if (symbol != (char *) 0)				/* Yes, we did */
		ptr = symbol;						/* Use it for ~ substitution */

	while ((*value++ = *ptr++))	/* Copy string */
		;

	*to = value - 1;			/* Update position in substituted string */
}

private void add_variable(to, from)
char **to;						/* Pointer to address in substituted text */
char **from;					/* Pointer to address in original text */
{
	/* Add value of variable at the current location */

	char *value = *to - 1;		/* Go back to overwrite the '$' */
	char *ptr = *from;			/* Start of variable's name */
	char buffer[MAX_STRING];	/* To hold the name of the variable */
	char *name = buffer;		/* To advance in buffer */
	char *dol_value;			/* $value of variable */

	/* Get variable's name */
	while ((*name++ = *ptr)) {
		if (isalnum(*ptr) || *ptr == '_')
			ptr++;
		else
			break;
	}

	*(name - 1) = '\0';			/* Ensure null terminated string */
	*from = ptr;				/* Update pointer in original text */

	/* Fetch value of variable recorded so far */
	dol_value = ht_value(&symtab, buffer);
	if (dol_value == (char *) 0)
		return;

	/* Do the variable substitution */
	while ((*value++ = *dol_value++))
		;
	
	*to = value - 1;			/* Update pointer to substituted text */
}

private void insert_value(path, line)
char *path;						/* The whole line */
int line;						/* The line number, for error reports */
{
	/* Analyze the line after parameter substitution and record the value of
	 * the variable in the hash table. The line has the following format:
	 *    name  :  value	# trailing comment
	 * If only spaces are encoutered or if the first non blank value is a '#',
	 * then the line is ignored. Otherwise, any error in parsing is reported.
	 */

	char name[MAX_STRING];				/* The name of the variable */
	char *nptr = name;					/* To fill in the name buffer */

	while (isspace(*path))				/* Skip leading spaces */
		path++;

	if (*path == '#')					/* A comment */
		return;							/* Ignore the whole line */
	if (*path == '\0')					/* A line full of spaces */
		return;							/* Ignore it */

	while ((*nptr++ = *path)) {			/* Copy everything until non alphanum */
		if (*path == '_') {
			/* Valid variable character, although not 'isalnum' */
			path++;
			continue;
		} else if (!isalnum(*path++))	/* Reached a non-alphanumeric char */
			break;						/* We got variable name */
	}
	*(nptr - 1) = '\0';					/* Overwrite the ':' with '\0' */
	path--;								/* Go back on non-alphanum char */
	while (*path)						/* Now go and find the ':' */
		if (*path++ == ':')				/* Found it */
			break;

	/* We reached the end of the string without seeing a ':' */
	if (*path == '\0') {
		say("syntax error in config file, line %d", line);
		return;
	}

	while (isspace(*path))					/* Skip leading spaces in value */
		path++;
	path[strlen(path) - 1] = '\0';			/* Chop final newline */
	strip_comment(path);					/* Remove trailing comment */
	(void) ht_put(&symtab, name, path);		/* Add value into symbol table */
}

private void strip_comment(line)
char *line;
{
	/* Remove anything after first '#' on line (trailing comment) and also
	 * strip any trailing spaces (including those right before the '#'
	 * character).
	 */

	char *first = (char *) 0;		/* First space in sequence */
	char c;							/* Character at current position */

	while ((c = *line++)) {
		if (isspace(c) && first != (char *) 0)
			continue;
		if (c == '#') {					/* This has to be a comment */
			if (first != (char *) 0)	/* Position of first preceding space */
				*first = '\0';			/* String ends at first white space */
			*(line - 1) = '\0';			/* Also truncate at '#' position */
			return;						/* Done */
		}
		if (isspace(c))
			first = line - 1;			/* Record first space position */
		else
			first = (char *) 0;			/* Signal: no active first space */
	}

	/* We have not found any '#' sign, so there is no comment in this line.
	 * However, there might be trailing white spaces... Trim them.
	 */
	
	if (first != (char *) 0)
		*first = '\0';					/* Get rid of trailing white spaces */
}

private char *machine_name()
{
	/* Compute the local machine name, using only lower-cased names and
	 * stipping down any domain name. The result points on a freshly allocated
	 * string. A null pointer is returned in case of error.
	 */
	
#ifdef HAS_GETHOSTNAME
	char name[MAX_STRING + 1];		/* The host name */
#else
#ifdef HAS_UNAME
	struct utsname un;				/* The internal uname structure */
#else
#ifdef PHOSTNAME
	char *command = PHOSTNAME;		/* Shell command to get hostname */
	FILE *fd;						/* File descriptor on popen() */
	char name[MAX_STRING + 1];		/* The host name read from command */
	char buffer[MAX_STRING + 1];	/* Input buffer */
#endif
#endif
#endif

#ifdef HAS_GETHOSTNAME
	if (-1 != gethostname(name, MAX_STRING))
		return strip_down(name);

	add_log(1, "SYSERR gethostname: %m (%e)");
	return (char *) 0;
#else
#ifdef HAS_UNAME
	if (-1 != uname(&un))
		return strip_down(un.nodename);

	add_log(1, "SYSERR uname: %m (%e)");
	return (char *) 0;
#else
#ifdef PHOSTNAME
	fd = popen(PHOSTNAME, "r");
	if (fd != (FILE *) 0) {
		fgets(buffer, MAX_STRING, fd);
		fclose(fd);
		sscanf(buffer, "%s", name);
		return strip_down(name);
	}

	add_log(1, "SYSERR cannot run %s: %m (%e)", PHOSTNAME);
#endif
	return strip_down(MYHOSTNAME);
#endif
#endif
}

private char *strip_down(host)
char *host;
{
	/* Return a freshly allocated string containing the host name. The string
	 * is lower-cased and the domain part is removed from the name.
	 * If any '-' is found in the hostname, it is translated into a '_', since
	 * it would not otherwise be a valid variable name for perl.
	 */
	
	char name[MAX_STRING + 1];		/* Constructed name */
	char *ptr = name;
	char c;

	if (host == (char *) 0)
		return (char *) 0;

	while ((c = *host)) {			/* Lower-case name */
		if (isupper(c))
			*ptr = tolower(c);
		else {
			if (c == '-')			/* Although '-' is a valid hostname char */
				c = '_';			/* It's not a valid perl variable char */
			*ptr = c;
		}
		if (c != '.') {				/* Found a domain delimiter? */
			host++;					/* No, continue */
			ptr++;
		} else
			break;					/* Yes, we end processing there */
	}
	*ptr = '\0';					/* Ensure null-terminated string */

	add_log(19, "hostname is %s", name);

	return strsave(name);			/* Save string in memory */
}

