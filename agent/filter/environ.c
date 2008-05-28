/*

 ######  #    #  #    #     #    #####    ####   #    #           ####
 #       ##   #  #    #     #    #    #  #    #  ##   #          #    #
 #####   # #  #  #    #     #    #    #  #    #  # #  #          #
 #       #  # #  #    #     #    #####   #    #  #  # #   ###    #
 #       #   ##   #  #      #    #   #   #    #  #   ##   ###    #    #
 ######  #    #    ##       #    #    #   ####   #    #   ###     ####

	Environment setting.
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
 * $Log: environ.c,v $
 * Revision 3.0.1.2  1996/12/24  13:52:05  ram
 * patch45: new get_env() routine, plus typo fixes
 * patch45: make sure new environment lines are smaller than MAX_STRING
 *
 * Revision 3.0.1.1  1995/08/07  16:08:02  ram
 * patch37: removed useless local variable declaration
 *
 * Revision 3.0  1993/11/29  13:48:07  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"
#include "logfile.h"
#include "hash.h"
#include "msg.h"
#include <stdio.h>

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif
#ifdef I_MALLOC
#include <malloc.h>
#else
extern char *malloc();				/* Memory allocation */
#endif
#include "confmagic.h"

#define ENV_VARS	200				/* An average number of environment vars */
#define MAX_STRING	4096			/* Maximum size for an environment value */

/* The environment is stored as an associative array: the key is the variable's
 * name, and we store the value as the associated value, of course. This is
 * not suitable for direct passing to a child, but it eases the environment
 * modifications.
 */
private struct htable henv;			/* The associative array for env */

extern char *strsave();				/* String saving */

public void print_env(fd, envp)
FILE *fd;
char **envp;
{
	/* Print the environment held in 'envp' on file 'fd'. This is mainly
	 * intended for debug purposes.
	 */

	while (*envp)
		fprintf(fd, "%s\n", *envp++);
}

public int init_env(envp)
char **envp;
{
	/* Initializes the associative array with the current environment. Returns
	 * 0 if ok, -1 if failed due to a lack of memory.
	 */

	char env_line[MAX_STRING + 1];	/* The environment line */
	char *ptr;						/* Pointer inside env_line */
	char *env;						/* The current environment line */

	if (-1 == ht_create(&henv, ENV_VARS))
		return -1;					/* Cannot create H table */

	while ((env = *envp++)) {
		strncpy(env_line, env, MAX_STRING);
		ptr = index(env_line, '=');
		if (ptr == (char *) 0) {
			add_log(6, "WARNING bad environment line");
			continue;
		}
		*ptr = '\0';				/* Before '=' lies the key */
		if ((char *) 0 == ht_put(&henv, env_line, ptr + 1)) {
			add_log(4, "ERROR cannot record environment any more");
			return -1;
		}
	}

	return 0;	/* Ok */
}

public int append_env(key, value)
char *key;
char *value;
{
	/* Appends 'value' at the end of the environment variable 'key', if it
	 * already exists, otherwise create it with that value.
	 * Returns 0 for success, -1 for failure.
	 */
	
	char env_line[MAX_STRING + 1];	/* The environment line */
	char *cval;						/* Current value */

	cval = ht_value(&henv, key);
	if (cval == (char *) 0) {
		if ((char *) 0 == ht_put(&henv, key, value)) {
			add_log(1, "ERROR cannot insert environment variable '%s'", key);
			return -1;				/* Insertion failed */
		}
		return 0;					/* Insertion ok */
	}

	strncpy(env_line, cval, MAX_STRING);
	if (strlen(env_line) + strlen(value) > MAX_STRING) {
		add_log(1, "ERROR cannot append to environment variable '%s'", key);
		return -1;
	}
	strcat(env_line, value);
	if ((char *) 0 == ht_force(&henv, key, env_line)) {
		add_log(1, "ERROR cannot update environment variable '%s'", key);
		return -1;
	}

	return 0;	/* Ok */
}

public int prepend_env(key, value)
char *key;
char *value;
{
	/* Prepends 'value' at the head of the environment variable 'key', if it
	 * already exists, otherwise create it with that value.
	 * Returns 0 for success, -1 for failure.
	 */
	
	char env_line[MAX_STRING + 1];	/* The environment line */
	char *cval;						/* Current value */

	cval = ht_value(&henv, key);
	if (cval == (char *) 0) {
		if ((char *) 0 == ht_put(&henv, key, value)) {
			add_log(1, "ERROR cannot insert environment variable '%s'", key);
			return -1;				/* Insertion failed */
		}
		return 0;					/* Insertion ok */
	}

	strncpy(env_line, value, MAX_STRING);
	if (strlen(env_line) + strlen(cval) > MAX_STRING) {
		add_log(1, "ERROR cannot prepend to environment variable '%s'", key);
		return -1;
	}
	strcat(env_line, cval);
	if ((char *) 0 == ht_force(&henv, key, env_line)) {
		add_log(1, "ERROR cannot update environment variable '%s'", key);
		return -1;
	}

	return 0;	/* Ok */
}

public int set_env(key, value)
char *key;
char *value;
{
	/* Set environment value 'key' and return 0 for success, -1 for failure. */

	char *cval;						/* Current value */

	cval = ht_value(&henv, key);
	if (cval == (char *) 0) {
		if ((char *) 0 == ht_put(&henv, key, value)) {
			add_log(1, "ERROR cannot insert environment variable '%s'", key);
			return -1;				/* Insertion failed */
		}
		return 0;					/* Insertion ok */
	}

	if ((char *) 0 == ht_force(&henv, key, value)) {
		add_log(1, "ERROR cannot update environment variable '%s'", key);
		return -1;
	}

	return 0;	/* Ok */
}

public char *get_env(key)
char *key;
{
	return ht_value(&henv, key);	/* Pointer to string value, or null */
}

public char **make_env()
{
	/* Create the environment pointer suitable for the execle() system call.
	 * Return a null pointer if there is not enough memory to create the
	 * environment.
	 */

	char env_line[MAX_STRING + 1];	/* The environment line */
	char **envp;					/* The environment pointer returned */
	char **ptr;						/* Pointer in the environment */
	int nb_line;					/* Number of lines */

	nb_line = ht_count(&henv) + 1;	/* Envp ends with a null pointer */
	if (nb_line == 0) {
		add_log(6, "NOTICE environment is empty");
		return (char **) 0;
	}
	envp = (char **) malloc(nb_line * sizeof(char *));
	if (envp == (char **) 0)
		fatal("out of memory");
	
	if (-1 == ht_start(&henv))
		fatal("environment H table botched");
	
	ptr = envp;
	for (ptr = envp; --nb_line > 0; (void) ht_next(&henv), ptr++) {
		char *key = ht_ckey(&henv);
		char *value = ht_cvalue(&henv);
		if ((strlen(key) + strlen(value) + 1) > MAX_STRING) {
			add_log(1, "ERROR can't propagate environment variable %s", key);
			fatal("environment line too big");
		}
		sprintf(env_line, "%s=%s", key, value);		/* key=value */
		*ptr = strsave(env_line);
		if (*ptr == (char *) 0)
			fatal("no more memory for environment");
	}

	*ptr = (char *) 0;				/* Environment is NULL terminated */

	return envp;					/* Pointer to new environment */
}

