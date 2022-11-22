/* 2004 December 23

	Secure database extension to SQLite 3. Uses hooks for encryption keys
	in the SQLite API.

	Extension author: Low Weng Liong (LWL)

	Currently at experimental testing stage so USE AT YOUR OWN RISK!

	Credits go to:
		Brian Gladman for his AES (Rijndael) and key derivation code.
		David Ireland for his BigDigits multiple-precision arithmetic library.
*/

#include "aes.h"
#include "aes_modes.h"
#include "pwd2key.h"
#include "bigdigits.h"
#include "sqliteInt.h"
#include "pager.h"
#include "btree.h"

#define KEY_LEN	32			/* 256 bits */
#define SALT_LEN	16
#define NUM_ITER	5000
#define BD_DIGITS	(AES_BLOCK_SIZE / 4)

/* security info for databases */
typedef struct
{
	aes_encrypt_ctx cx;		/* Encryption context */
	unsigned char key[KEY_LEN];
	unsigned char newKey[KEY_LEN];
	int isKeyed;		/* true if key is set */
	int isReKey;		/* true if re-keying */
	Btree *bt;			/* pointer to B-tree used by DB */
} stDbSecInfo;


/* Global variables */
static stDbSecInfo dbInfo[MAX_ATTACHED + 2];

/*
	Stores a [large] counter for CTR mode.
	We use the BigDigits multiple-precision arithmetic representation,
	but the AES CTR mode expects it in a byte array.
*/
typedef union
{
	/* DIGIT_T from bigdigits.h should be a 32-bit integer */
	DIGIT_T d[BD_DIGITS];
	unsigned char s[AES_BLOCK_SIZE];
} big_num;

/* Derive a key from a null-terminated pass phrase */
static int get_a_key (const unsigned char pass[], unsigned int passlen,
	unsigned char key[])
{
	/*
		Random fixed salt of SALT_LEN bytes used. A dynamic one would be great
		if we can save it with the encrypted SQLite database.
		Has room for further improvement.
	*/
	const unsigned char salt[SALT_LEN] = { 0x5c, 0x08, 0xeb, 0x61, 0xfd, 0xf7,
		0x1e, 0x4e, 0x4e, 0xc3, 0xcf, 0x6b, 0xa1, 0xf5, 0x51, 0x2b };

	derive_key(pass, passlen, salt, SALT_LEN, NUM_ITER, key, KEY_LEN);
	return SQLITE_OK;
}

/*
	Set initial CTR counter value based on the page number to be crypted.
	The way CTR mode works is that the entire counter (of size AES_BLOCK_SIZE)
	is encrypted with the key and then used as the key stream for cryption.
	When all bytes in the counter are used, the counter is incremented,
	encrypted, and the resulting AES_BLOCK_SIZE-byte keystream is used
	starting from the beginning. The process repeats until all input bytes
	have been crypted.

	To make it so that each crypted page will not begin with the same counter
	value, we divide each page into blocks the size of AES_BLOCK_SIZE. The blocks
	are numbered from 0 onwards. We then find the starting block (i.e., counter
	value) given a page number. If the page size does not divide evenly by the
	block size, then we also find the offset in the first block (that is also the
	last block used by the previous page) where the cryption should start.

	In this way, if you think of the entire file as a contiguous flow of bytes
	instead of being separated by pages, then the counter values used from start
	to end of the file should be contiguous in increasing order.

	ctr - [out] counter value that is set and returned
	num - page number
	pagesize - size of a page
	ofs - [out] offset into first block where cryption should start
*/
static void set_counter (big_num *ctr, Pgno num, unsigned int pagesize,
	unsigned int ofs[1])
{
	unsigned int blksize;
	big_num temp, total, offset;

	assert (num > 0);
	copyright_notice();		/* copyright for BigDigits library */

	blksize = AES_BLOCK_SIZE;

	/*
		total_bytes = (page_num - 1) * pagesize
		counter = total_bytes / blksize
		offset = total_bytes % blksize
	*/

	mpSetDigit (temp.d, num - 1, BD_DIGITS);
	mpShortMult (total.d, temp.d, (DIGIT_T) pagesize, BD_DIGITS);
	mpSetDigit (temp.d, blksize, 1);
	mpDivide (ctr->d, offset.d, total.d, BD_DIGITS, temp.d, 1);

	/* the remainder is less than blksize, so it's in one DIGIT_T */
	ofs[0] = (unsigned int) offset.d[0];
}

/*
	Increment counter of of AES_BLOCK_SIZE bytes
	Assumes buffer is at least AES_BLOCK_SIZE bytes long.
	If not, the result is undefined.
*/
static void inc_counter(unsigned char *cbuf)
{
	DIGIT_T k, *ptr;
	unsigned int j;

	ptr = (DIGIT_T *) cbuf;
	k = 0;

	/* This code block taken and modified from mpShortAdd() for efficiency. */
	/* Add 1 to first digit */
	ptr[0] = ptr[0] + 1;
	if (ptr[0] < 1)		/* overflow + wrap around */
		k = 1;
	else
		k = 0;

	/* Add carry to subsequent digits */
	for (j = 1; j < BD_DIGITS; j++)
	{
		ptr[j] = ptr[j] + k;
		if (ptr[j] < k)
			k = 1;
		else
			k = 0;
	}
	/* We do not care about overflows. Just let the counter wrap around. */
}

/*
	This is our implementation of the xCodec function as referenced in pager.c.
	It encrypts/decrypts a page based on the fourth parameter.

	I still have no idea what exactly the fourth parameter does, but it is
	probably some mode. I can only discern two modes: encrypt and decrypt,
	but with 5 different values used in pager.c it might indicate additional
	stuff the codec needs to do.

	If someone finds out what each value of the 4th parameter does, please
	let me know. (Hint: Search for 'CODEC' in pager.c)

	pCodecArg - additional arguments to the codec function
	data - data to be crypted
	num - number of the page that the data is from
	xmode - indication of some mode/flag (see above comments)
*/
void sqlite3sec_crypt(void *pCodecArg, void *data, Pgno num, int xmode)
{
	big_num counter;		/* to store counter for AES CTR */
	unsigned int offset, size;
	stDbSecInfo *p;

	if (!pCodecArg)		/* not an encrypted DB? */
		return;

	p = (stDbSecInfo *) pCodecArg;
	if (!p->isKeyed)
		return;

	/* Initialize CTR counter value */
	size = (unsigned int) sqlite3BtreeGetPageSize (p->bt);
	set_counter (&counter, num, (unsigned int) size, &offset);
	aes_ctr_set_bpos (&p->cx, offset);

	/*
		Actually, since we are using AES in CTR mode, it does not matter
		whether the xmode parameter indicates encryption or decryption since
		both use the same crypt function (and internally, only encryption).

		Here are my observations of each xmode value from the calls to the
		CODEC macro in pager.c:

		3 - from DB to page
		  - from journal to page
		  - probably decryption
		2 - from DB to page
		  - probably decryption
		6 - from page to DB
		  - probably encryption
		7 - from page to journal
		  - probably encryption
		0 - used after xmode = 6 and writing to DB
		  - used after xmode = 7 and writing to journal
		  - probably decryption after the previous encryption before writing

		Again, please let me know if someone finds out what these modes mean
		in this function, or if it is not relevant given the mode of operation
		we are using with AES here.
	*/

	aes_ctr_crypt (data, data, size, counter.s, inc_counter, &p->cx);
}

/*
	Attach to a new database with a given key.

	I am unsure whether the key is a pass phrase, the binary cryption key,
	or both. In attach.c the key can come from 3 locations: 1)main DB,
	2)as text(?), 3)as a BLOB. This brings the possibility that it might in
	fact be a hex representation of the cryption key as opposed to an ASCII
	pass phrase as I originally thought.

	Regardless, if the key argument is not the length expected by the AES
	algorithm, we derive the proper key from it. This might change once the
	exact semantics of these functions are figured out.
*/
int sqlite3CodecAttach(sqlite3 *db, int index, void *key, int keylen)
{
	Pager *mainPager = NULL;

	if (keylen == 0)		/* no key? */
	{
		dbInfo[index].isKeyed = 0;
		return SQLITE_OK;
	}

	/*
		I think this function is similar to sqlite3_key, but it already
		knows exactly which DB's pager to attach the codec to.
	*/
	memset (dbInfo[index].newKey, 0, KEY_LEN);
	memset (&dbInfo[index].cx, 0, sizeof (aes_encrypt_ctx));

	/* If key not of proper length, assume it is a pass phrase and derive the key */
	if (keylen != KEY_LEN)
		get_a_key (key, keylen, dbInfo[index].key);

	/* Set the key */
	if (aes_encrypt_key256 (dbInfo[index].key, &dbInfo[index].cx) != aes_good)
		return SQLITE_ERROR;

	/* Set the other information (similar to sqlite3_key()) */
	dbInfo[index].isKeyed = 1;
	dbInfo[index].isReKey = 0;
	dbInfo[index].bt = db->aDb[index].pBt;
	mainPager = sqlite3BtreePager (dbInfo[index].bt);
	sqlite3pager_set_codec (mainPager, sqlite3sec_crypt, &dbInfo[index]);

	return SQLITE_OK;
}

/*
	Return existing key for main database.
	Currently, we return the actual AES key for the main DB. See comments for
	sqlite3CodecAttach() above.

	db - Database
	noclue - No clue what this parameter does. A zero is passed in from
		attach.c and is the only reference we have.
	key - [out] main database key
	keylen - [out] key length
*/
void sqlite3CodecGetKey(sqlite3 *db, int noclue, void **key, int *keylen)
{
	if (!dbInfo[0].isKeyed)		/* no key for main DB? */
	{
		*key = NULL;
		*keylen = 0;
	}
	else
	{
		*key = dbInfo[0].key;
		*keylen = KEY_LEN;
	}
}

/*
	Set the password for the main database. The 'key' here refers to
	the plaintext pass phrase, not the AES encryption key.


	db - database to be rekeyed
	pKey - the key in ASCII
	nKey - key length in bytes
*/
int sqlite3_key(sqlite3 *db, const void *pKey, int nKey)
{
	int rc = SQLITE_OK;
	Pager *mainPager = NULL;

	if (nKey == 0)		/* no key given, assume DB is not encrypted */
		return SQLITE_OK;

	if (db->nDb < 2)
		return SQLITE_ERROR;

	if (dbInfo[0].isKeyed)		/* key already set? */
	{
		/* TODO: Check if this is a good move. For now, treat as a re-keying. */
		sqlite3_rekey (db, pKey, nKey);
	}

	/*
		Since this function must be called right after sqlite3_open or
		sqlite3_open16 and before all other sqlite3 calls, there are only
		two databases: main and temp.

		For now we set the codec and page size for main since temp's B-tree
		is not allocated at this point. Hence only db[0].
	*/
	memset (dbInfo[0].key, 0, KEY_LEN);
	memset (dbInfo[0].newKey, 0, KEY_LEN);
	memset (&dbInfo[0].cx, 0, sizeof (aes_encrypt_ctx));
	dbInfo[0].isKeyed = 0;
	dbInfo[0].isReKey = 0;

	get_a_key (pKey, nKey, dbInfo[0].key);
	if (aes_encrypt_key256 (dbInfo[0].key, &dbInfo[0].cx) != aes_good)
		rc = SQLITE_ERROR;
	else
	{
		dbInfo[0].isKeyed = 1;

		/*
			Set the codec and codec argument. We also need to know the page size,
			so we set that in the dbInfo structure as well.

			TODO: set codec for temp DB?
		*/

		dbInfo[0].bt = db->aDb[0].pBt;
		mainPager = sqlite3BtreePager (dbInfo[0].bt);
		sqlite3pager_set_codec (mainPager, sqlite3sec_crypt, &dbInfo[0]);
	}

	return rc;
}

/*
	Change the password for the encrypted database. If the database is not
	encrypted, this will encrypt it with the given password.
	'key' here refers to the plaintext pass phrase, not the AES encryption key.

	db - database to be rekeyed
	pKey - the key in ASCII
	nKey - key length in bytes
*/
int sqlite3_rekey(sqlite3 *db, const void *pKey, int nKey)
{
	int rc = SQLITE_OK;

	/*
		This code is responsible for keeping track of the old key until
		all pages in the DB have been re-keyed.
	*/
	/* TODO */
	/*return rc;*/
	return SQLITE_ERROR;		/* not implemented yet */
}

