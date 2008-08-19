/*

 #    #    ##     ####   #    #           ####
 #    #   #  #   #       #    #          #    #
 ######  #    #   ####   ######          #
 #    #  ######       #  #    #   ###    #
 #    #  #    #  #    #  #    #   ###    #    #
 #    #  #    #   ####   #    #   ###     ####

	Hash table handling (no item ever deleted).
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
 * $Log: hash.c,v $
 * Revision 3.0  1993/11/29  13:48:08  ram
 * Baseline for mailagent 3.0 netwide release.
 *
 */

#include "config.h"
#include "portable.h"

#ifdef I_STDLIB
#include <stdlib.h>
#else
#ifdef I_MALLOC
#include <malloc.h>
#else
extern char *malloc();				/* Memory allocation */
#endif
#endif	/* I_STDLIB */

#ifdef I_STRING
#include <string.h>
#else
#include <strings.h>
#endif

#include "hash.h"
#include "msg.h"
#include "confmagic.h"

#ifndef lint
private char *rcsid =
	"$Id$";
#endif

private uint32 hashcode();			/* The hahsing function */
private int prime();				/* Is a number a prime one? */
private uint32 nprime();			/* Find next prime number */

extern char *strsave();				/* Save string in memory */

public int ht_create(ht, n)
struct htable *ht;
int n;
{
	/* Creates an H table to hold 'n' items with descriptor held in 'ht'. The
	 * size of the table is optimized to avoid conflicts and is of course a
	 * prime number. We take the first prime after (5 * n / 4).
	 * The function returns 0 if everything was ok, -1 otherwise.
	 */

	int hsize;			/* Size of created table */
	char **array;		/* For array creation (keys/values) */
	
	(void) rcsid;					/* Shut up compiler warning */
	hsize = nprime((5 * n) / 4);	/* Table's size */

	array = (char **) calloc(hsize, sizeof(char *));	/* Array of keys */
	if (array == (char **) 0)
		return -1;					/* Malloc failed */
	ht->h_keys = array;				/* Where array of keys is stored */

	array = (char **) malloc(hsize * sizeof(char *));	/* Array of values */
	if (array == (char **) 0) {
		free(ht->h_keys);			/* Free keys array */
		return -1;					/* Malloc failed */
	}
	ht->h_values = array;			/* Where array of keys is stored */

	ht->h_size = hsize;				/* Size of hash table */
	ht->h_items = 0;				/* Table is empty */

	return 0;			/* Creation was ok */
}

public char *ht_value(ht, skey)
struct htable *ht;
char *skey;
{
	/* Look for item associated with given key and returns its value.
	 * Return a null pointer if item is not found.
	 */
	
	register1 int32 key;		/* Hash code associated with string key */
	register2 int32 pos;		/* Position in H table */
	register3 int32 hsize;		/* Size of H table */
	register4 char **hkeys;		/* Array of keys */
	register5 int32 try = 0;	/* Count number of attempts */
	register6 int32 inc;		/* Loop increment */

	/* Initializations */
	hsize = ht->h_size;
	hkeys = ht->h_keys;
	key = hashcode(skey);

	/* Jump from one hashed position to another until we find the value or
	 * go to an empty entry or reached the end of the table.
	 */
	inc = 1 + (key % (hsize - 1));
	for (pos = key % hsize; try < hsize; try++, pos = (pos + inc) % hsize) {
		if (hkeys[pos] == (char *) 0)
			break;
		else if (0 == strcmp(hkeys[pos], skey))
			return ht->h_values[pos];
	}

	return (char *) 0;			/* Item was not found */
}

public char *ht_put(ht, skey, val)
struct htable *ht;
char *skey;
char *val;
{
	/* Puts string held at 'val' tagged with key 'key' in H table 'ht'. If
	 * insertion was successful, the address of the value is returned and the
	 * value is copied in the array. Otherwise, return a null pointer.
	 */

	register1 int32 key;		/* Hash code associated with string key */
	register2 int32 pos;		/* Position in H table */
	register3 int32 hsize;		/* Size of H table */
	register4 char **hkeys;		/* Array of keys */
	register5 int32 try = 0;	/* Records number of attempts */
	register6 int32 inc;		/* Loop increment */

	/* If the table is full at 75%, resize it to avoid performance degradations.
	 * The extension updates the htable structure in place.
	 */
	hsize = ht->h_size;
	if ((ht->h_items * 4) / 3 > hsize) {
		ht_xtend(ht);
		hsize = ht->h_size;
	}
	hkeys = ht->h_keys;
	key = hashcode(skey);

	/* Jump from one hashed position to another until we find a free entry or
	 * we reached the end of the table.
	 */
	inc = 1 + (key % (hsize - 1));
	for (pos = key % hsize; try < hsize; try++, pos = (pos + inc) % hsize) {
		if (hkeys[pos] == (char *) 0) {			/* Found a free location */
			hkeys[pos] = strsave(skey);			/* Record item */
			ht->h_values[pos] = strsave(val);	/* Save string */
			ht->h_items++;				/* One more item */
			return ht->h_values[pos];
		} else if (0 == strcmp(hkeys[pos], skey))
			fatal("H table key conflict: %s", skey);
	}

	return (char *) 0;		/* We were unable to insert item */
}

public char *ht_force(ht, skey, val)
struct htable *ht;
char *skey;
char *val;
{
	/* Replace value tagged with key 'key' in H table 'ht' with 'val'. If
	 * insertion was successful, the address of the value is returned and the
	 * value is copied in the array. Otherwise, return a null pointer (if table
	 * is full and item was not found). The previous value is freed if any.
	 * Otherwise, simply add the item in the table.
	 */

	register1 int32 key;		/* Hash code associated with string key */
	register2 int32 pos;		/* Position in H table */
	register3 int32 hsize;		/* Size of H table */
	register4 char **hkeys;		/* Array of keys */
	register5 int32 try = 0;	/* Records number of attempts */
	register6 int32 inc;		/* Loop increment */

	/* If the table is full at 75%, resize it to avoid performance degradations.
	 * The extension updates the htable structure in place.
	 */
	hsize = ht->h_size;
	if ((ht->h_items * 4) / 3 > hsize) {
		ht_xtend(ht);
		hsize = ht->h_size;
	}
	hkeys = ht->h_keys;
	key = hashcode(skey);

	/* Jump from one hashed position to another until we find a free entry or
	 * we reached the end of the table.
	 */
	inc = 1 + (key % (hsize - 1));
	for (pos = key % hsize; try < hsize; try++, pos = (pos + inc) % hsize) {
		if (hkeys[pos] == (char *) 0) {			/* Found a free location */
			hkeys[pos] = strsave(skey);			/* Record item */
			ht->h_values[pos] = strsave(val);	/* Save string */
			ht->h_items++;						/* One more item */
			return ht->h_values[pos];
		} else if (0 == strcmp(hkeys[pos], skey)) {
			if (ht->h_values[pos])				/* If old value */
				free(ht->h_values[pos]);		/* Free it */
			ht->h_values[pos] = strsave(val);	/* Save string */
			return ht->h_values[pos];
		}
	}

	return (char *) 0;		/* We were unable to insert item */
}

public int ht_xtend(ht)
struct htable *ht;
{
	/* The H table 'ht' is full and needs resizing. We add 50% of old size and
	 * copy the old table in the new one, before freeing the old one. Note that
	 * h_create multiplies the number we give by 5/4, so 5/4*3/2 yields ~2, i.e.
	 * the final size will be the double of the previous one (modulo next prime
	 * number).
	 * Return 0 if extension was ok, -1 otherwise.
	 */

	register1 int32 size;			/* Size of old H table */
	register2 char **key;			/* To loop over keys */
	register3 char **val;			/* To loop over values */
	struct htable new_ht;

	size = ht->h_size;
	if (-1 == ht_create(&new_ht, size + (size / 2)))
		return -1;		/* Extension of H table failed */

	key = ht->h_keys;				/* Start of array of keys */
	val = ht->h_values;				/* Start of array of values */

	/* Now loop over the whole table, inserting each item in the new one */

	for (; size > 0; size--, key++, val++) {
		if (*key == (char *) 0)		/* Nothing there */
			continue;				/* Skip entry */
		if ((char *) 0 == ht_put(&new_ht, *key, *val)) {	/* Failed */
			free(new_ht.h_values);	/* Free new H table */
			free(new_ht.h_keys);
			fatal("BUG in ht_xtend");
		}
	}

	/* Free old H table and set H table descriptor */
	free(ht->h_values);				/* Free in allocation order */
	free(ht->h_keys);				/* To make free happy (coalescing) */
	bcopy(&new_ht, ht, sizeof(struct htable));

	return 0;		/* Extension was ok */
}

public int ht_start(ht)
struct htable *ht;
{
	/* Start iteration over H table. Return 0 if ok, -1 if the table is empty */

	register1 int32 hpos;		/* Index in H table */
	register2 char **hkeys;		/* Array of keys */
	register3 int32 hsize;		/* Size of H table */

	/* Initializations */
	hpos = 0;
	hkeys = ht->h_keys;
	hsize = ht->h_size;

	/* Stop at first non-null key */
	for (; hpos < hsize; hpos++, hkeys++)
		if (*hkeys != (char *) 0)
			break;
	ht->h_pos = hpos;			/* First non-null postion */

	return (hpos < hsize) ? 0 : -1;
}

public int ht_next(ht)
struct htable *ht;
{
	/* Advance to next item in H table, if possible. Return 0 if there is a
	 * next item, -1 otherwise.
	 */

	register1 int32 hpos;		/* Index in H table */
	register2 char **hkeys;		/* Array of keys */
	register3 int32 hsize;		/* Size of H table */

	/* Initializations */
	hpos = ht->h_pos + 1;
	hkeys = ht->h_keys + hpos;
	hsize = ht->h_size;

	/* Stop at first non-null key */
	for (; hpos < hsize; hpos++, hkeys++)
		if (*hkeys != (char *) 0)
			break;
	ht->h_pos = hpos;			/* Next non-null postion */

	return (hpos < hsize) ? 0 : -1;
}

public char *ht_ckey(ht)
struct htable *ht;
{
	/* Return pointer on current item's key */

	return ht->h_keys[ht->h_pos];
}

public char *ht_cvalue(ht)
struct htable *ht;
{
	/* Return pointer on current item's value */

	return ht->h_values[ht->h_pos];
}

public int ht_count(ht)
struct htable *ht;
{
	/* Return the number of items in the H table */

	return ht->h_items;
}

private uint32 hashcode(s)
register3 char *s;
{
	/* Compute the hash code associated with given string s. The magic number
	 * below is the greatest prime lower than 2^23.
	 */

	register1 uint32 hashval = 0;
	register2 uint32 magic = 8388593;

	while (*s)
		hashval = ((hashval % magic) << 8) + (unsigned int) *s++;

	return hashval;
}

private uint32 nprime(n)
register1 uint32 n;
{
	/* Return the closest prime number greater than `n' */

	while (!prime(n))
		n++;

	return n;
}

private int prime(n)
register2 uint32 n;
{
	/* Return 1 if `n' is a prime number */

	register1 uint32 divisor;

	if (n == 1)
		return 0;
	else if (n == 2)
		return 1;
	else if (n % 2) {
		for (
			divisor = 3; 
			divisor * divisor <= n;
			divisor += 2
		)
			if (0 == (n % divisor))
				return 0;
		return 1;
	}
	return 0;
}

