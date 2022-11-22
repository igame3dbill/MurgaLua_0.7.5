/* bigdigits.h */

/******************* SHORT COPYRIGHT NOTICE*************************
This source code is part of the BigDigits multiple-precision
arithmetic library Version 1.0 originally written by David Ireland,
copyright (c) 2001 D.I. Management Services Pty Limited, all rights
reserved. It is provided "as is" with no warranties. You may use
this software under the terms of the full copyright notice
"bigdigitsCopyright.txt" that should have been included with
this library. To obtain a copy send an email to
<code@di-mgt.com.au> or visit <www.di-mgt.com.au/crypto.html>.
This notice must be retained in any copy.
****************** END OF COPYRIGHT NOTICE*************************/

#ifndef _BIGDIGITS_H_
#define _BIGDIGITS_H_ 1

/* Define type of DIGIT here */
typedef unsigned long DIGIT_T;
typedef unsigned short HALF_DIGIT_T;

/* Sizes to suit your machine */
#define MAX_DIGIT 0xffffffff
#define MAX_HALF_DIGIT 0xffffL	/* errata [2] */
#define BITS_PER_DIGIT 32
#define HIBITMASK 0x80000000

/* Max number of digits expected in a mp array */
#define MAX_DIG_LEN 51
/*	This is required for temp storage only in:
	mpModulo, mpShortMod, mpModMult, mpGcd,
	mpModInv, mpIsPrime
*/

/* Useful macros */
#define LOHALF(x) ((DIGIT_T)((x) & 0xffff))
#define HIHALF(x) ((DIGIT_T)((x) >> 16 & 0xffff))
#define TOHIGH(x) ((DIGIT_T)((x) << 16))

#define ISODD(x) ((x) & 0x1)
#define ISEVEN(x) (!ISODD(x))

#define mpISODD(x, n) (x[0] & 0x1)
#define mpISEVEN(x, n) (!(x[0] & 0x1))

#define mpNEXTBITMASK(mask, n) if(mask==1){mask=HIBITMASK;n--;}else{mask>>=1;}


char *copyright_notice(void);
	/* Forces linker to include copyright notice in executable */


/*	Multiple precision calculations
	Using known, equal ndigits
	except where noted
*/

DIGIT_T mpAdd(DIGIT_T w[], DIGIT_T u[], DIGIT_T v[],
			   unsigned int ndigits);
	/* Computes w = u + v, returns carry */

DIGIT_T mpSubtract(DIGIT_T w[], DIGIT_T u[], DIGIT_T v[],
			   unsigned int ndigits);
	/* Computes w = u - v, returns borrow */

int mpMultiply(DIGIT_T w[], DIGIT_T u[], DIGIT_T v[],
					unsigned int ndigits);
	/* Computes product w = u * v
	   u, v = ndigits long; w = 2 * ndigits long */

int mpDivide(DIGIT_T q[], DIGIT_T r[], DIGIT_T u[],
	unsigned int udigits, DIGIT_T v[], unsigned int vdigits);
	/* Computes quotient q = u / v and remainder r = u mod v
	   q, r, u = udigits long; v = vdigits long
	   Warning: Trashes q and r first */

int mpModulo(DIGIT_T r[], DIGIT_T u[], unsigned int udigits,
			 DIGIT_T v[], unsigned int vdigits);
	/* Computes r = u mod v
	   u = udigits long; r, v = vdigits long */

int mpModMult(DIGIT_T a[], DIGIT_T x[], DIGIT_T y[], DIGIT_T m[], unsigned int ndigits);
	/* Computes a = (x * y) mod m */

int mpModExp(DIGIT_T y[], DIGIT_T x[],
			DIGIT_T n[], DIGIT_T d[], unsigned int ndigits);
	/* Computes y = x^n mod d */

int mpModInv(DIGIT_T inv[], DIGIT_T u[], DIGIT_T v[], unsigned int ndigits);
	/*	Computes inv = u^-1 mod v */

int mpGcd(DIGIT_T g[], DIGIT_T x[], DIGIT_T y[], unsigned int ndigits);
	/* Computes g = gcd(x, y) */

int mpEqual(DIGIT_T a[], DIGIT_T b[], unsigned int ndigits);
	/* Returns true if a == b, else false */

int mpCompare(DIGIT_T a[], DIGIT_T b[], unsigned int ndigits);
	/* Returns sign of (a - b) */

int mpIsZero(DIGIT_T a[], unsigned int ndigits);
	/* Returns true if a == 0, else false */

/* Bitwise operations */

DIGIT_T mpShiftLeft(DIGIT_T a[], DIGIT_T b[],
	unsigned int x, unsigned int ndigits);
	/* Computes a = b << x, x < BITS_PER_DIGIT */

DIGIT_T mpShiftRight(DIGIT_T a[], DIGIT_T b[],
	unsigned int x, unsigned int ndigits);
	/* Computes a = b >> x, x < BITS_PER_DIGIT */

/* Other mp utilities */

void mpSetZero(DIGIT_T a[], unsigned int ndigits);
	/* Sets a = 0 */

void mpSetDigit(DIGIT_T a[], DIGIT_T d, unsigned int ndigits);
	/* Sets a = d where d is a single digit */

void mpSetEqual(DIGIT_T a[], DIGIT_T b[], unsigned int ndigits);
	/* Sets a = b */

unsigned int mpSizeof(DIGIT_T a[], unsigned int ndigits);
	/* Returns size of significant non-zero digits in a */

int mpIsPrime(DIGIT_T w[], unsigned int ndigits, unsigned int t);
	/* Returns true if w is a probable prime
	   t tests using FIPS-186-2/Rabin-Miller */


/* mpShort = mp x single digit calculations */

DIGIT_T mpShortAdd(DIGIT_T w[], DIGIT_T u[], DIGIT_T d,
			   unsigned int ndigits);
	/* Computes w = u + d, returns carry */

DIGIT_T mpShortSub(DIGIT_T w[], DIGIT_T u[], DIGIT_T v,
			   unsigned int ndigits);
	/* Computes w = u - v, returns borrow */

DIGIT_T mpShortMult(DIGIT_T p[], DIGIT_T x[], DIGIT_T y,
					unsigned int ndigits);
	/* Computes product p = x * y */

DIGIT_T mpShortDiv(DIGIT_T q[], DIGIT_T u[], DIGIT_T v,
				   unsigned int ndigits);
	/* Computes q = u / v, returns remainder */

DIGIT_T mpShortMod(DIGIT_T a[], DIGIT_T d, unsigned int ndigits);
	/* Computes r = a mod d */

int mpShortCmp(DIGIT_T a[], DIGIT_T b, unsigned int ndigits);
	/* Returns sign of (a - b) where b is a single digit */


/* Short division using only half-digit divisor */

DIGIT_T mpHalfDiv(DIGIT_T q[], DIGIT_T a[], HALF_DIGIT_T d,
				   unsigned int ndigits);
	/* Computes q = a mod d, returns remainder */

DIGIT_T mpHalfMod(DIGIT_T a[], HALF_DIGIT_T d, unsigned int ndigits);
	/* Computes r = a mod d */


/* Single precision calculations (double where necessary) */

int spMultiply(DIGIT_T p[2], DIGIT_T x, DIGIT_T y);
	/* Computes p = x * y */

DIGIT_T spDivide(DIGIT_T *q, DIGIT_T *r, DIGIT_T u[2], DIGIT_T v);
	/* Computes quotient q = u / v, remainder r = u mod v */

int spModExp(DIGIT_T *exp, DIGIT_T x, DIGIT_T n, DIGIT_T d);
	/* Computes exp = x^n mod d */

int spModMult(DIGIT_T *a, DIGIT_T x, DIGIT_T y, DIGIT_T m);
	/* Computes a = (x * y) mod m */

int spModInv(DIGIT_T *inv, DIGIT_T u, DIGIT_T v);
	/* Computes inv = u^-1 mod v */

DIGIT_T spGcd(DIGIT_T x, DIGIT_T y);
	/* Returns gcd(x, y) */

int spIsPrime(DIGIT_T w, unsigned int t);
	/* Returns true if w is prime, else false; t tests */

DIGIT_T spPseudoRand(DIGIT_T lower, DIGIT_T upper);
	/* Returns single pseudo-random digit between lower and upper */


/* Print utilities */

void mpPrint(DIGIT_T *p, unsigned int len);
	/* Print all digits incl leading zero digits */
void mpPrintNL(DIGIT_T *p, unsigned int len);
	/* Print all digits with newlines */
void mpPrintTrim(DIGIT_T *p, unsigned int len);
	/* Print but trim leading zero digits */
void mpPrintTrimNL(DIGIT_T *p, unsigned int len);
	/* Print, trim leading zeroes, add newlines */


/* "BigDigits" with memory management - not complete yet */

typedef struct
{
	DIGIT_T *digits;	/* Ptr to array of digits, least sig. first */
	unsigned int ndigits;	/* No of non-zero significant digits */
	unsigned int maxdigits;	/* Max size allocated */
} BIGD_T;

BIGD_T *bpInit(BIGD_T *b, unsigned int precision);
	/* Return ptr to initialised BIGD structure
	   with precision digits */

void bpFinal(BIGD_T *b);
	/* Zeroise and free memory */

BIGD_T *bpResize(BIGD_T *b, unsigned int newsize);
	/* Increase allocated memory to newsize digits */

int bpAdd(BIGD_T *w, BIGD_T *u, BIGD_T *v);
	/* Compute w = u + v */

int bpSubtract(BIGD_T *w, BIGD_T *u, BIGD_T *v);
	/* Compute w = u - v, return borrow */

int bpEqual(BIGD_T *a, BIGD_T *b);
	/* Returns true if a == b, else false */

void bpPrint(BIGD_T *p);
	/* Print all significant digits in BIGD_T */

#endif	/* _BIGDIGITS_H_ */
