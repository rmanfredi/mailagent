/*

 #    #    ##     ####   #    #          #    #
 #    #   #  #   #       #    #          #    #
 ######  #    #   ####   ######          ######
 #    #  ######       #  #    #   ###    #    #
 #    #  #    #  #    #  #    #   ###    #    #
 #    #  #    #   ####   #    #   ###    #    #

	Declarations for hash table.
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
 * $Log: hash.h,v $
 * Revision 3.0  1993/11/29  13:48:09  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#ifndef _hash_h
#define _hash_h

/* Structure which describes the hash table: array of keys and array of
 * values, along with the table's size and the number of recorded elements.
 */
struct htable {
	int32 h_size;		/* Size of table (prime number) */
	int32 h_items;		/* Number of items recorded in table */
	char **h_keys;		/* Array of keys (strings) */
	int h_pos;			/* Last position in table (iterations) */
	char **h_values;	/* Array of values (strings) */
};

/* Function declaration */
extern int ht_create();				/* Create H table */
extern char *ht_value();			/* Get value given some key */
extern char *ht_put();				/* Insert value in H table */
extern char *ht_force();			/* Like ht_put, but replace old value */
extern int ht_xtend();				/* Extend size of full H table */
extern int ht_start();				/* Start iteration over H table */
extern int ht_next();				/* Go to next item in H table */
extern char *ht_ckey();				/* Fetch current key */
extern char *ht_cvalue();			/* Fetch current value */
extern int ht_count();				/* Number of items in H table */

#endif
