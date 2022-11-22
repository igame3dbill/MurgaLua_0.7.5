/*
*	Selene crypto stuff
*	This additions
*	Copyright (c) 2005 Malete Partner, Berlin, partner@malete.org
*	Available under "Lua 5.0 license", see http://www.lua.org/license.html#5
*	$Id: slncrypt.c,v 1.4 2006/07/26 17:20:04 paul Exp $
*
The crypto code is borrowed -- with heavy modifications -- from:

SHA1 spec at http://ietf.org/rfc/rfc3174.txt
	(originally at http://www.itl.nist.gov/fipspubs/fip180-1.htm)
SHA1_Transform (not much diff to RFC 3174) from
 * SHA-1 in C
 * By Steve Reid <steve@edmweb.com>
 * 100% Public Domain
once distributed
 * Copyright (c) 1999 Scriptics Corporation.
as
 * exampleA.c --
at ftp://tcl.activestate.com/pub/tcl/examples/tea/sampleextension-0.2.tar.gz
"SHA-1 broken" at http://www.schneier.com/blog/archives/2005/02/sha1_broken.html
 
The blowfish is basically as described by it's inventor Bruce Schneier
in http://www.schneier.com/paper-blowfish-fse.html
(c.f. Applied Cryptography http://www.schneier.com/book-applied-toc.html)
and available at http://www.schneier.com/blowfish.html

Some code was copied from Paul Kocher's LGPLed implementation
available at http://www.schneier.com/code/bfsh-koc.zip

Paul okayed a BSD-stlye license (see below).
*/

/*
		$Id: slncrypt.c,v 1.4 2006/07/26 17:20:04 paul Exp $
		selene crypto utilities for Lua
*/

#include <string.h> /* memcpy/set :( */

#include "lua.h"
#include "lauxlib.h"

#ifndef SLN_CRYPTNAME /* unless set it luaconf */
#	define SLN_CRYPTNAME "crypto"
#endif

#if defined( __sparc__ ) || defined( __ppc__ )
#	define CPU_BIG_ENDIAN
#endif
#ifndef uint64_t
#define uint64_t unsigned long long
#endif

#define SWAP32(x) \
	(((0xff&x)<<24)|((0xff00&x)<<8)|(0xff00&(x>>8))|(0xff&(x>>24)))

/*
*	there are 2 SHA1 implementations:
*	a naive one straight from the RFC (~ 2.8 K intel codesize),
*	and an unrolled version by Steve Reid (~ 7K ", 20% faster)
*	#define SHA1_REID	for the latter
*/


/* so here goes license.terms accompanying exampleA.c by Scriptics:
This software is copyrighted by the Scriptics Corporation, and other
parties.  The following terms apply to all files associated with the
software unless explicitly disclaimed in individual files.

The authors hereby grant permission to use, copy, modify, distribute,
and license this software and its documentation for any purpose, provided
that existing copyright notices are retained in all copies and that this
notice is included verbatim in any distributions. No written agreement,
license, or royalty fee is required for any of the authorized uses.
Modifications to this software may be copyrighted by their authors
and need not follow the licensing terms described here, provided that
the new terms are clearly indicated on the first page of each file where
they apply.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
MODIFICATIONS.

GOVERNMENT USE: If you are acquiring this software on behalf of the
U.S. government, the Government shall have only "Restricted Rights"
in the software and related documentation as defined in the Federal 
Acquisition Regulations (FARs) in Clause 52.227.19 (c) (2).  If you
are acquiring the software on behalf of the Department of Defense, the
software shall be classified as "Commercial Computer Software" and the
Government shall have only "Restricted Rights" as defined in Clause
252.227-7013 (c) (1) of DFARs.  Notwithstanding the foregoing, the
authors grant the U.S. Government and others acting in its behalf
permission to use and distribute the software in accordance with the
terms specified in this license. 
*/

/*
 * SHA-1 in C
 * By Steve Reid <steve@edmweb.com>
 * 100% Public Domain
 * 
 * Test Vectors (from FIPS PUB 180-1)
 * "abc"
 *   A9993E36 4706816A BA3E2571 7850C26C 9CD0D89D
 * "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
 *   84983E44 1C3BD26E BAAE4AA1 F95129E5 E54670F1
 * A million repetitions of "a"
 *   34AA973C D4C4DAA4 F61EEB2B DBAD2731 6534016F
try crypto.sha1(string.rep("a",1000000))
 */


/*
	sha1(string [, state])
*/
static int crypto_sha1 (lua_State *L)
{
	/* SHA1 initialization constants */
	unsigned A = 0x67452301, B = 0xEFCDAB89,
		C = 0x98BADCFE, D = 0x10325476, E = 0xC3D2E1F0;
#ifdef SHA1_REID
	unsigned l[16];
#else
	unsigned l[80];
#endif
	uint64_t ll;
	char ret[64]; /* 40 len \0 */
	const char *bytes;
	int len, state = 0, add = 0;

	if (1 < lua_gettop(L)) { /* state */
		state = 1;
		bytes = luaL_checklstring(L, 2, &len);
		if ( len /* init from previous state */
			&& 6 != sscanf(bytes, "%8x%8x%8x%8x%8x %d", &A,&B,&C,&D,&E,&add)
		) /* sorrry for using sscanf ! */
			luaL_error(L, "bad sha1 state");
	}

	bytes = luaL_checklstring(L, 1, &len);
	ll = ((uint64_t)(add+len)) << 3; /* bitcount */

	if ( !len || 63&len ) /* close */
		state = 0;
	else if (state)
		state = add+len;
	for (; len > -9; bytes += 64, len -= 64) {
		if ( 64 <= len ) /* fits */
			memcpy(l, bytes, 64);
		else {
			memset(l, 0, 64); /* lazy pad */
			if ( 0 <= len ) { /* previous block was fully used */
				if ( 0 < len )
					memcpy(l, bytes, len);
				else if (state) /* return current unclosed A-E state */
					break;
				((unsigned char*)l)[len] = 0x80; /* always pad binary 10000000 */
			}
			if ( 56 > len ) { /* room for the count (after pad)  */
#ifdef CPU_BIG_ENDIAN
				((uint64_t*)l)[7] = ll;
#else
				char *d = (char*)(l+14), *s = (char*)&ll, *e = s+8;
				do *d++ = *--e; while (e > s);
#endif
				state = 0; /* closed */
			}
		}
		/* SHA1_Transform */ {
		register unsigned int a=A, b=B, c=C, d=D, e=E;
#ifdef SHA1_REID	/* 7K on an intel */
#define Rol(value, bits) (((value) << (bits)) | ((value) >> (32 - (bits))))
/*
 * Blk0() and Blk() perform the initial expand.
 * I got the idea of expanding during the round function from SSLeay
 */
#ifdef CPU_BIG_ENDIAN
#	define Blk0(i) l[i]
#else
#	define Blk0(i) (l[i] = (Rol(l[i],24)&0xFF00FF00) \
	|(Rol(l[i],8)&0x00FF00FF))
#endif
#define Blk(i) (l[i&15] = Rol(l[(i+13)&15]^l[(i+8)&15] \
	^l[(i+2)&15]^l[i&15],1))
/*
 * (R0+R1), R2, R3, R4 are the different operations used in SHA1
 */
#define R0(v,w,x,y,z,i) z+=((w&(x^y))^y)+Blk0(i)+0x5A827999+Rol(v,5);w=Rol(w,30);
#define R1(v,w,x,y,z,i) z+=((w&(x^y))^y)+Blk(i)+0x5A827999+Rol(v,5);w=Rol(w,30);
#define R2(v,w,x,y,z,i) z+=(w^x^y)+Blk(i)+0x6ED9EBA1+Rol(v,5);w=Rol(w,30);
#define R3(v,w,x,y,z,i) z+=(((w|x)&y)|(w&x))+Blk(i)+0x8F1BBCDC+Rol(v,5);w=Rol(w,30);
#define R4(v,w,x,y,z,i) z+=(w^x^y)+Blk(i)+0xCA62C1D6+Rol(v,5);w=Rol(w,30);

		/*
		 * 4 rounds of 20 operations each. Loop unrolled.
		 */

		R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
		R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
		R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
		R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
		R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
		R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
		R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
		R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
		R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
		R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
		R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
		R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
		R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
		R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
		R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
		R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
		R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
		R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
		R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
		R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);

#else /* not SHA1_REID: plain from RFC ~2.8K on intel, +25% slower */
#define SHA1CircularShift(bits,word) \
                (((word) << (bits)) | ((word) >> (32-(bits))))
		unsigned tmp, *u, *end;
#ifndef CPU_BIG_ENDIAN /* do the Blk0-init-magic once */
		for (u = l+16; --u >= l;) *u = SWAP32(*u);
#endif
		for (u = l+15, end = l+80; ++u < end;)
			*u = SHA1CircularShift(1, u[-3]^u[-8]^u[-14]^u[-16]);
		for (u = l-1, end = l+20; ++u < end;) {
			tmp = SHA1CircularShift(5, a) + ((b&c) | (~b&d)) + e + *u + 0x5A827999;
			e=d; d=c; c=SHA1CircularShift(30,b); b=a; a=tmp;
		}
		for (u = l+19, end = l+40; ++u < end;) {
			tmp = SHA1CircularShift(5, a) + (b^c^d) + e + *u + 0x6ED9EBA1;
			e=d; d=c; c=SHA1CircularShift(30,b); b=a; a=tmp;
		}
		for (u = l+39, end = l+60; ++u < end;) {
			tmp = SHA1CircularShift(5, a) + ((b&(c|d))|(c&d)) + e + *u + 0x8F1BBCDC;
			e=d; d=c; c=SHA1CircularShift(30,b); b=a; a=tmp;
		}
		for (u = l+59, end = l+80; ++u < end;) {
			tmp = SHA1CircularShift(5, a) + (b^c^d) + e + *u + 0xCA62C1D6;
			e=d; d=c; c=SHA1CircularShift(30,b); b=a; a=tmp;
		}
#endif /* SHA1_REID */
		/*
		 * Add the working vars back into context.state[]
		 */

		A += a;
		B += b;
		C += c;
		D += d;
		E += e;
	}}
	/* memset(l, 0, 64); wipe traces -- useless in Lua */

	/* this always prints a "big-endian" representation */
	if ( state )
		sprintf(ret, "%08X%08X%08X%08X%08X %d", A,B,C,D,E, state);
	else
		sprintf(ret, "%08X%08X%08X%08X%08X", A,B,C,D,E);
	lua_pushstring(L, ret);
	return 1;
}	/* sha1 */



/*
blowfish.c:  C implementation of the Blowfish algorithm.

Copyright (C) 1997 by Paul Kocher

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  
  

COMMENTS ON USING THIS CODE:

Normal usage is as follows:
   [1] Allocate a BFish.  (It may be too big for the stack.)
   [2] Call Blowfish_Init with a pointer to your BFish, a pointer to
       the key, and the number of bytes in the key.
   [3] To encrypt a 64-bit block, call Blowfish_Encrypt with a pointer to
       BFish, a pointer to the 32-bit left half of the plaintext
     and a pointer to the 32-bit right half.  The plaintext will be
     overwritten with the ciphertext.
   [4] Decryption is the same as encryption except that the plaintext and
       ciphertext are reversed.

Warning #1:  The code does not check key lengths. (Caveat encryptor.) 
Warning #2:  Beware that Blowfish keys repeat such that "ab" = "abab".
Warning #3:  It is normally a good idea to zeroize the BFish before
  freeing it.
Warning #4:  Endianness conversions are the responsibility of the caller.
  (To encrypt bytes on a little-endian platforms, you'll probably want
  to swap bytes around instead of just casting.)
Warning #5:  Make sure to use a reasonable mode of operation for your
  application.  (If you don't know what CBC mode is, see Warning #7.)
Warning #6:  This code is susceptible to timing attacks.
Warning #7:  Security engineering is risky and non-intuitive.  Have someone 
  check your work.  If you don't know what you are doing, get help.


This is code is fast enough for most applications, but is not optimized for
speed.

If you require this code under a license other than LGPL, please ask.  (I 
can be located using your favorite search engine.)  Unfortunately, I do not 
have time to provide unpaid support for everyone who uses this code.  

                                             -- Paul Kocher

Subject: Re: license for 1997 blowfish implementation
Date: Thu, 24 Mar 2005 17:51:27 -0800
From: Paul Kocher <paul@cryptography.com>
To: Klaus Ripke <paul@malete.org>

It's OK with me for it to be used under a BSD license (which is more
permissive than most others).  If that's not sufficient, let me know and
I'll look at the LUA license...

-- Paul

At 06:42 PM 2/23/2005 +0100, you wrote:
>Dear Paul
>
>I built a little extension for the Lua programming language based on
>http://www.schneier.com/code/bfsh-koc.zip
>
>In order to fit in the lua picture, it would be very nice to
>make it available under the MIT-style "Lua 5 license"
>http://www.lua.org/license.html#5
>
>Would you allow these terms (for this purpose)?
>
>
>TIA
>Klaus

_________________________________________________________
Paul Kocher  (paul@cryptography.com)
President & Chief Scientist, Cryptography Research, Inc.

575 Market Street, 21st floor, San Francisco, CA  94105
tel: 415.397.0111   main: 415.397.0123   fax: 415.397.0127

"Good security doesn't happen by chance."

*/


typedef struct {
	unsigned S[4][256];
	unsigned P[18];
} BFish;


static const BFish BFishInit = {
{{
	0xD1310BA6, 0x98DFB5AC, 0x2FFD72DB, 0xD01ADFB7,
	0xB8E1AFED, 0x6A267E96, 0xBA7C9045, 0xF12C7F99,
	0x24A19947, 0xB3916CF7, 0x0801F2E2, 0x858EFC16,
	0x636920D8, 0x71574E69, 0xA458FEA3, 0xF4933D7E,
	0x0D95748F, 0x728EB658, 0x718BCD58, 0x82154AEE,
	0x7B54A41D, 0xC25A59B5, 0x9C30D539, 0x2AF26013,
	0xC5D1B023, 0x286085F0, 0xCA417918, 0xB8DB38EF,
	0x8E79DCB0, 0x603A180E, 0x6C9E0E8B, 0xB01E8A3E,
	0xD71577C1, 0xBD314B27, 0x78AF2FDA, 0x55605C60,
	0xE65525F3, 0xAA55AB94, 0x57489862, 0x63E81440,
	0x55CA396A, 0x2AAB10B6, 0xB4CC5C34, 0x1141E8CE,
	0xA15486AF, 0x7C72E993, 0xB3EE1411, 0x636FBC2A,
	0x2BA9C55D, 0x741831F6, 0xCE5C3E16, 0x9B87931E,
	0xAFD6BA33, 0x6C24CF5C, 0x7A325381, 0x28958677,
	0x3B8F4898, 0x6B4BB9AF, 0xC4BFE81B, 0x66282193,
	0x61D809CC, 0xFB21A991, 0x487CAC60, 0x5DEC8032,
	0xEF845D5D, 0xE98575B1, 0xDC262302, 0xEB651B88,
	0x23893E81, 0xD396ACC5, 0x0F6D6FF3, 0x83F44239,
	0x2E0B4482, 0xA4842004, 0x69C8F04A, 0x9E1F9B5E,
	0x21C66842, 0xF6E96C9A, 0x670C9C61, 0xABD388F0,
	0x6A51A0D2, 0xD8542F68, 0x960FA728, 0xAB5133A3,
	0x6EEF0B6C, 0x137A3BE4, 0xBA3BF050, 0x7EFB2A98,
	0xA1F1651D, 0x39AF0176, 0x66CA593E, 0x82430E88,
	0x8CEE8619, 0x456F9FB4, 0x7D84A5C3, 0x3B8B5EBE,
	0xE06F75D8, 0x85C12073, 0x401A449F, 0x56C16AA6,
	0x4ED3AA62, 0x363F7706, 0x1BFEDF72, 0x429B023D,
	0x37D0D724, 0xD00A1248, 0xDB0FEAD3, 0x49F1C09B,
	0x075372C9, 0x80991B7B, 0x25D479D8, 0xF6E8DEF7,
	0xE3FE501A, 0xB6794C3B, 0x976CE0BD, 0x04C006BA,
	0xC1A94FB6, 0x409F60C4, 0x5E5C9EC2, 0x196A2463,
	0x68FB6FAF, 0x3E6C53B5, 0x1339B2EB, 0x3B52EC6F,
	0x6DFC511F, 0x9B30952C, 0xCC814544, 0xAF5EBD09,
	0xBEE3D004, 0xDE334AFD, 0x660F2807, 0x192E4BB3,
	0xC0CBA857, 0x45C8740F, 0xD20B5F39, 0xB9D3FBDB,
	0x5579C0BD, 0x1A60320A, 0xD6A100C6, 0x402C7279,
	0x679F25FE, 0xFB1FA3CC, 0x8EA5E9F8, 0xDB3222F8,
	0x3C7516DF, 0xFD616B15, 0x2F501EC8, 0xAD0552AB,
	0x323DB5FA, 0xFD238760, 0x53317B48, 0x3E00DF82,
	0x9E5C57BB, 0xCA6F8CA0, 0x1A87562E, 0xDF1769DB,
	0xD542A8F6, 0x287EFFC3, 0xAC6732C6, 0x8C4F5573,
	0x695B27B0, 0xBBCA58C8, 0xE1FFA35D, 0xB8F011A0,
	0x10FA3D98, 0xFD2183B8, 0x4AFCB56C, 0x2DD1D35B,
	0x9A53E479, 0xB6F84565, 0xD28E49BC, 0x4BFB9790,
	0xE1DDF2DA, 0xA4CB7E33, 0x62FB1341, 0xCEE4C6E8,
	0xEF20CADA, 0x36774C01, 0xD07E9EFE, 0x2BF11FB4,
	0x95DBDA4D, 0xAE909198, 0xEAAD8E71, 0x6B93D5A0,
	0xD08ED1D0, 0xAFC725E0, 0x8E3C5B2F, 0x8E7594B7,
	0x8FF6E2FB, 0xF2122B64, 0x8888B812, 0x900DF01C,
	0x4FAD5EA0, 0x688FC31C, 0xD1CFF191, 0xB3A8C1AD,
	0x2F2F2218, 0xBE0E1777, 0xEA752DFE, 0x8B021FA1,
	0xE5A0CC0F, 0xB56F74E8, 0x18ACF3D6, 0xCE89E299,
	0xB4A84FE0, 0xFD13E0B7, 0x7CC43B81, 0xD2ADA8D9,
	0x165FA266, 0x80957705, 0x93CC7314, 0x211A1477,
	0xE6AD2065, 0x77B5FA86, 0xC75442F5, 0xFB9D35CF,
	0xEBCDAF0C, 0x7B3E89A0, 0xD6411BD3, 0xAE1E7E49,
	0x00250E2D, 0x2071B35E, 0x226800BB, 0x57B8E0AF,
	0x2464369B, 0xF009B91E, 0x5563911D, 0x59DFA6AA,
	0x78C14389, 0xD95A537F, 0x207D5BA2, 0x02E5B9C5,
	0x83260376, 0x6295CFA9, 0x11C81968, 0x4E734A41,
	0xB3472DCA, 0x7B14A94A, 0x1B510052, 0x9A532915,
	0xD60F573F, 0xBC9BC6E4, 0x2B60A476, 0x81E67400,
	0x08BA6FB5, 0x571BE91F, 0xF296EC6B, 0x2A0DD915,
	0xB6636521, 0xE7B9F9B6, 0xFF34052E, 0xC5855664,
	0x53B02D5D, 0xA99F8FA1, 0x08BA4799, 0x6E85076A,
}, {
	0x4B7A70E9, 0xB5B32944, 0xDB75092E, 0xC4192623,
	0xAD6EA6B0, 0x49A7DF7D, 0x9CEE60B8, 0x8FEDB266,
	0xECAA8C71, 0x699A17FF, 0x5664526C, 0xC2B19EE1,
	0x193602A5, 0x75094C29, 0xA0591340, 0xE4183A3E,
	0x3F54989A, 0x5B429D65, 0x6B8FE4D6, 0x99F73FD6,
	0xA1D29C07, 0xEFE830F5, 0x4D2D38E6, 0xF0255DC1,
	0x4CDD2086, 0x8470EB26, 0x6382E9C6, 0x021ECC5E,
	0x09686B3F, 0x3EBAEFC9, 0x3C971814, 0x6B6A70A1,
	0x687F3584, 0x52A0E286, 0xB79C5305, 0xAA500737,
	0x3E07841C, 0x7FDEAE5C, 0x8E7D44EC, 0x5716F2B8,
	0xB03ADA37, 0xF0500C0D, 0xF01C1F04, 0x0200B3FF,
	0xAE0CF51A, 0x3CB574B2, 0x25837A58, 0xDC0921BD,
	0xD19113F9, 0x7CA92FF6, 0x94324773, 0x22F54701,
	0x3AE5E581, 0x37C2DADC, 0xC8B57634, 0x9AF3DDA7,
	0xA9446146, 0x0FD0030E, 0xECC8C73E, 0xA4751E41,
	0xE238CD99, 0x3BEA0E2F, 0x3280BBA1, 0x183EB331,
	0x4E548B38, 0x4F6DB908, 0x6F420D03, 0xF60A04BF,
	0x2CB81290, 0x24977C79, 0x5679B072, 0xBCAF89AF,
	0xDE9A771F, 0xD9930810, 0xB38BAE12, 0xDCCF3F2E,
	0x5512721F, 0x2E6B7124, 0x501ADDE6, 0x9F84CD87,
	0x7A584718, 0x7408DA17, 0xBC9F9ABC, 0xE94B7D8C,
	0xEC7AEC3A, 0xDB851DFA, 0x63094366, 0xC464C3D2,
	0xEF1C1847, 0x3215D908, 0xDD433B37, 0x24C2BA16,
	0x12A14D43, 0x2A65C451, 0x50940002, 0x133AE4DD,
	0x71DFF89E, 0x10314E55, 0x81AC77D6, 0x5F11199B,
	0x043556F1, 0xD7A3C76B, 0x3C11183B, 0x5924A509,
	0xF28FE6ED, 0x97F1FBFA, 0x9EBABF2C, 0x1E153C6E,
	0x86E34570, 0xEAE96FB1, 0x860E5E0A, 0x5A3E2AB3,
	0x771FE71C, 0x4E3D06FA, 0x2965DCB9, 0x99E71D0F,
	0x803E89D6, 0x5266C825, 0x2E4CC978, 0x9C10B36A,
	0xC6150EBA, 0x94E2EA78, 0xA5FC3C53, 0x1E0A2DF4,
	0xF2F74EA7, 0x361D2B3D, 0x1939260F, 0x19C27960,
	0x5223A708, 0xF71312B6, 0xEBADFE6E, 0xEAC31F66,
	0xE3BC4595, 0xA67BC883, 0xB17F37D1, 0x018CFF28,
	0xC332DDEF, 0xBE6C5AA5, 0x65582185, 0x68AB9802,
	0xEECEA50F, 0xDB2F953B, 0x2AEF7DAD, 0x5B6E2F84,
	0x1521B628, 0x29076170, 0xECDD4775, 0x619F1510,
	0x13CCA830, 0xEB61BD96, 0x0334FE1E, 0xAA0363CF,
	0xB5735C90, 0x4C70A239, 0xD59E9E0B, 0xCBAADE14,
	0xEECC86BC, 0x60622CA7, 0x9CAB5CAB, 0xB2F3846E,
	0x648B1EAF, 0x19BDF0CA, 0xA02369B9, 0x655ABB50,
	0x40685A32, 0x3C2AB4B3, 0x319EE9D5, 0xC021B8F7,
	0x9B540B19, 0x875FA099, 0x95F7997E, 0x623D7DA8,
	0xF837889A, 0x97E32D77, 0x11ED935F, 0x16681281,
	0x0E358829, 0xC7E61FD6, 0x96DEDFA1, 0x7858BA99,
	0x57F584A5, 0x1B227263, 0x9B83C3FF, 0x1AC24696,
	0xCDB30AEB, 0x532E3054, 0x8FD948E4, 0x6DBC3128,
	0x58EBF2EF, 0x34C6FFEA, 0xFE28ED61, 0xEE7C3C73,
	0x5D4A14D9, 0xE864B7E3, 0x42105D14, 0x203E13E0,
	0x45EEE2B6, 0xA3AAABEA, 0xDB6C4F15, 0xFACB4FD0,
	0xC742F442, 0xEF6ABBB5, 0x654F3B1D, 0x41CD2105,
	0xD81E799E, 0x86854DC7, 0xE44B476A, 0x3D816250,
	0xCF62A1F2, 0x5B8D2646, 0xFC8883A0, 0xC1C7B6A3,
	0x7F1524C3, 0x69CB7492, 0x47848A0B, 0x5692B285,
	0x095BBF00, 0xAD19489D, 0x1462B174, 0x23820E00,
	0x58428D2A, 0x0C55F5EA, 0x1DADF43E, 0x233F7061,
	0x3372F092, 0x8D937E41, 0xD65FECF1, 0x6C223BDB,
	0x7CDE3759, 0xCBEE7460, 0x4085F2A7, 0xCE77326E,
	0xA6078084, 0x19F8509E, 0xE8EFD855, 0x61D99735,
	0xA969A7AA, 0xC50C06C2, 0x5A04ABFC, 0x800BCADC,
	0x9E447A2E, 0xC3453484, 0xFDD56705, 0x0E1E9EC9,
	0xDB73DBD3, 0x105588CD, 0x675FDA79, 0xE3674340,
	0xC5C43465, 0x713E38D8, 0x3D28F89E, 0xF16DFF20,
	0x153E21E7, 0x8FB03D4A, 0xE6E39F2B, 0xDB83ADF7,
}, {
	0xE93D5A68, 0x948140F7, 0xF64C261C, 0x94692934,
	0x411520F7, 0x7602D4F7, 0xBCF46B2E, 0xD4A20068,
	0xD4082471, 0x3320F46A, 0x43B7D4B7, 0x500061AF,
	0x1E39F62E, 0x97244546, 0x14214F74, 0xBF8B8840,
	0x4D95FC1D, 0x96B591AF, 0x70F4DDD3, 0x66A02F45,
	0xBFBC09EC, 0x03BD9785, 0x7FAC6DD0, 0x31CB8504,
	0x96EB27B3, 0x55FD3941, 0xDA2547E6, 0xABCA0A9A,
	0x28507825, 0x530429F4, 0x0A2C86DA, 0xE9B66DFB,
	0x68DC1462, 0xD7486900, 0x680EC0A4, 0x27A18DEE,
	0x4F3FFEA2, 0xE887AD8C, 0xB58CE006, 0x7AF4D6B6,
	0xAACE1E7C, 0xD3375FEC, 0xCE78A399, 0x406B2A42,
	0x20FE9E35, 0xD9F385B9, 0xEE39D7AB, 0x3B124E8B,
	0x1DC9FAF7, 0x4B6D1856, 0x26A36631, 0xEAE397B2,
	0x3A6EFA74, 0xDD5B4332, 0x6841E7F7, 0xCA7820FB,
	0xFB0AF54E, 0xD8FEB397, 0x454056AC, 0xBA489527,
	0x55533A3A, 0x20838D87, 0xFE6BA9B7, 0xD096954B,
	0x55A867BC, 0xA1159A58, 0xCCA92963, 0x99E1DB33,
	0xA62A4A56, 0x3F3125F9, 0x5EF47E1C, 0x9029317C,
	0xFDF8E802, 0x04272F70, 0x80BB155C, 0x05282CE3,
	0x95C11548, 0xE4C66D22, 0x48C1133F, 0xC70F86DC,
	0x07F9C9EE, 0x41041F0F, 0x404779A4, 0x5D886E17,
	0x325F51EB, 0xD59BC0D1, 0xF2BCC18F, 0x41113564,
	0x257B7834, 0x602A9C60, 0xDFF8E8A3, 0x1F636C1B,
	0x0E12B4C2, 0x02E1329E, 0xAF664FD1, 0xCAD18115,
	0x6B2395E0, 0x333E92E1, 0x3B240B62, 0xEEBEB922,
	0x85B2A20E, 0xE6BA0D99, 0xDE720C8C, 0x2DA2F728,
	0xD0127845, 0x95B794FD, 0x647D0862, 0xE7CCF5F0,
	0x5449A36F, 0x877D48FA, 0xC39DFD27, 0xF33E8D1E,
	0x0A476341, 0x992EFF74, 0x3A6F6EAB, 0xF4F8FD37,
	0xA812DC60, 0xA1EBDDF8, 0x991BE14C, 0xDB6E6B0D,
	0xC67B5510, 0x6D672C37, 0x2765D43B, 0xDCD0E804,
	0xF1290DC7, 0xCC00FFA3, 0xB5390F92, 0x690FED0B,
	0x667B9FFB, 0xCEDB7D9C, 0xA091CF0B, 0xD9155EA3,
	0xBB132F88, 0x515BAD24, 0x7B9479BF, 0x763BD6EB,
	0x37392EB3, 0xCC115979, 0x8026E297, 0xF42E312D,
	0x6842ADA7, 0xC66A2B3B, 0x12754CCC, 0x782EF11C,
	0x6A124237, 0xB79251E7, 0x06A1BBE6, 0x4BFB6350,
	0x1A6B1018, 0x11CAEDFA, 0x3D25BDD8, 0xE2E1C3C9,
	0x44421659, 0x0A121386, 0xD90CEC6E, 0xD5ABEA2A,
	0x64AF674E, 0xDA86A85F, 0xBEBFE988, 0x64E4C3FE,
	0x9DBC8057, 0xF0F7C086, 0x60787BF8, 0x6003604D,
	0xD1FD8346, 0xF6381FB0, 0x7745AE04, 0xD736FCCC,
	0x83426B33, 0xF01EAB71, 0xB0804187, 0x3C005E5F,
	0x77A057BE, 0xBDE8AE24, 0x55464299, 0xBF582E61,
	0x4E58F48F, 0xF2DDFDA2, 0xF474EF38, 0x8789BDC2,
	0x5366F9C3, 0xC8B38E74, 0xB475F255, 0x46FCD9B9,
	0x7AEB2661, 0x8B1DDF84, 0x846A0E79, 0x915F95E2,
	0x466E598E, 0x20B45770, 0x8CD55591, 0xC902DE4C,
	0xB90BACE1, 0xBB8205D0, 0x11A86248, 0x7574A99E,
	0xB77F19B6, 0xE0A9DC09, 0x662D09A1, 0xC4324633,
	0xE85A1F02, 0x09F0BE8C, 0x4A99A025, 0x1D6EFE10,
	0x1AB93D1D, 0x0BA5A4DF, 0xA186F20F, 0x2868F169,
	0xDCB7DA83, 0x573906FE, 0xA1E2CE9B, 0x4FCD7F52,
	0x50115E01, 0xA70683FA, 0xA002B5C4, 0x0DE6D027,
	0x9AF88C27, 0x773F8641, 0xC3604C06, 0x61A806B5,
	0xF0177A28, 0xC0F586E0, 0x006058AA, 0x30DC7D62,
	0x11E69ED7, 0x2338EA63, 0x53C2DD94, 0xC2C21634,
	0xBBCBEE56, 0x90BCB6DE, 0xEBFC7DA1, 0xCE591D76,
	0x6F05E409, 0x4B7C0188, 0x39720A3D, 0x7C927C24,
	0x86E3725F, 0x724D9DB9, 0x1AC15BB4, 0xD39EB8FC,
	0xED545578, 0x08FCA5B5, 0xD83D7CD3, 0x4DAD0FC4,
	0x1E50EF5E, 0xB161E6F8, 0xA28514D9, 0x6C51133C,
	0x6FD5C7E7, 0x56E14EC4, 0x362ABFCE, 0xDDC6C837,
	0xD79A3234, 0x92638212, 0x670EFA8E, 0x406000E0,
}, {
	0x3A39CE37, 0xD3FAF5CF, 0xABC27737, 0x5AC52D1B,
	0x5CB0679E, 0x4FA33742, 0xD3822740, 0x99BC9BBE,
	0xD5118E9D, 0xBF0F7315, 0xD62D1C7E, 0xC700C47B,
	0xB78C1B6B, 0x21A19045, 0xB26EB1BE, 0x6A366EB4,
	0x5748AB2F, 0xBC946E79, 0xC6A376D2, 0x6549C2C8,
	0x530FF8EE, 0x468DDE7D, 0xD5730A1D, 0x4CD04DC6,
	0x2939BBDB, 0xA9BA4650, 0xAC9526E8, 0xBE5EE304,
	0xA1FAD5F0, 0x6A2D519A, 0x63EF8CE2, 0x9A86EE22,
	0xC089C2B8, 0x43242EF6, 0xA51E03AA, 0x9CF2D0A4,
	0x83C061BA, 0x9BE96A4D, 0x8FE51550, 0xBA645BD6,
	0x2826A2F9, 0xA73A3AE1, 0x4BA99586, 0xEF5562E9,
	0xC72FEFD3, 0xF752F7DA, 0x3F046F69, 0x77FA0A59,
	0x80E4A915, 0x87B08601, 0x9B09E6AD, 0x3B3EE593,
	0xE990FD5A, 0x9E34D797, 0x2CF0B7D9, 0x022B8B51,
	0x96D5AC3A, 0x017DA67D, 0xD1CF3ED6, 0x7C7D2D28,
	0x1F9F25CF, 0xADF2B89B, 0x5AD6B472, 0x5A88F54C,
	0xE029AC71, 0xE019A5E6, 0x47B0ACFD, 0xED93FA9B,
	0xE8D3C48D, 0x283B57CC, 0xF8D56629, 0x79132E28,
	0x785F0191, 0xED756055, 0xF7960E44, 0xE3D35E8C,
	0x15056DD4, 0x88F46DBA, 0x03A16125, 0x0564F0BD,
	0xC3EB9E15, 0x3C9057A2, 0x97271AEC, 0xA93A072A,
	0x1B3F6D9B, 0x1E6321F5, 0xF59C66FB, 0x26DCF319,
	0x7533D928, 0xB155FDF5, 0x03563482, 0x8ABA3CBB,
	0x28517711, 0xC20AD9F8, 0xABCC5167, 0xCCAD925F,
	0x4DE81751, 0x3830DC8E, 0x379D5862, 0x9320F991,
	0xEA7A90C2, 0xFB3E7BCE, 0x5121CE64, 0x774FBE32,
	0xA8B6E37E, 0xC3293D46, 0x48DE5369, 0x6413E680,
	0xA2AE0810, 0xDD6DB224, 0x69852DFD, 0x09072166,
	0xB39A460A, 0x6445C0DD, 0x586CDECF, 0x1C20C8AE,
	0x5BBEF7DD, 0x1B588D40, 0xCCD2017F, 0x6BB4E3BB,
	0xDDA26A7E, 0x3A59FF45, 0x3E350A44, 0xBCB4CDD5,
	0x72EACEA8, 0xFA6484BB, 0x8D6612AE, 0xBF3C6F47,
	0xD29BE463, 0x542F5D9E, 0xAEC2771B, 0xF64E6370,
	0x740E0D8D, 0xE75B1357, 0xF8721671, 0xAF537D5D,
	0x4040CB08, 0x4EB4E2CC, 0x34D2466A, 0x0115AF84,
	0xE1B00428, 0x95983A1D, 0x06B89FB4, 0xCE6EA048,
	0x6F3F3B82, 0x3520AB82, 0x011A1D4B, 0x277227F8,
	0x611560B1, 0xE7933FDC, 0xBB3A792B, 0x344525BD,
	0xA08839E1, 0x51CE794B, 0x2F32C9B7, 0xA01FBAC9,
	0xE01CC87E, 0xBCC7D1F6, 0xCF0111C3, 0xA1E8AAC7,
	0x1A908749, 0xD44FBD9A, 0xD0DADECB, 0xD50ADA38,
	0x0339C32A, 0xC6913667, 0x8DF9317C, 0xE0B12B4F,
	0xF79E59B7, 0x43F5BB3A, 0xF2D519FF, 0x27D9459C,
	0xBF97222C, 0x15E6FC2A, 0x0F91FC71, 0x9B941525,
	0xFAE59361, 0xCEB69CEB, 0xC2A86459, 0x12BAA8D1,
	0xB6C1075E, 0xE3056A0C, 0x10D25065, 0xCB03A442,
	0xE0EC6E0E, 0x1698DB3B, 0x4C98A0BE, 0x3278E964,
	0x9F1F9532, 0xE0D392DF, 0xD3A0342B, 0x8971F21E,
	0x1B0A7441, 0x4BA3348C, 0xC5BE7120, 0xC37632D8,
	0xDF359F8D, 0x9B992F2E, 0xE60B6F47, 0x0FE3F11D,
	0xE54CDA54, 0x1EDAD891, 0xCE6279CF, 0xCD3E7E6F,
	0x1618B166, 0xFD2C1D05, 0x848FD2C5, 0xF6FB2299,
	0xF523F357, 0xA6327623, 0x93A83531, 0x56CCCD02,
	0xACF08162, 0x5A75EBB5, 0x6E163697, 0x88D273CC,
	0xDE966292, 0x81B949D0, 0x4C50901B, 0x71C65614,
	0xE6C6C7BD, 0x327A140A, 0x45E1D006, 0xC3F27B9A,
	0xC9AA53FD, 0x62A80F00, 0xBB25BFE2, 0x35BDD2F6,
	0x71126905, 0xB2040222, 0xB6CBCF7C, 0xCD769C2B,
	0x53113EC0, 0x1640E3D3, 0x38ABBD60, 0x2547ADF0,
	0xBA38209C, 0xF746CE76, 0x77AFA1C5, 0x20756060,
	0x85CBFE4E, 0x8AE88DD8, 0x7AAAF9B0, 0x4CF9AA7E,
	0x1948C25C, 0x02FB8A8C, 0x01C36AE4, 0xD6EBE1F9,
	0x90D4F869, 0xA65CDEA0, 0x3F09252D, 0xC208E69F,
	0xB74E6132, 0xCE77E25B, 0x578FDFE3, 0x3AC372E6
}},
{
	0x243F6A88, 0x85A308D3, 0x13198A2E, 0x03707344,
	0xA4093822, 0x299F31D0, 0x082EFA98, 0xEC4E6C89,
	0x452821E6, 0x38D01377, 0xBE5466CF, 0x34E90C6C,
	0xC0AC29B7, 0xC97C50DD, 0x3F84D5B5, 0xB5470917,
	0x9216D5D9, 0x8979FB1B
}};

typedef union {
	uint64_t t;
	unsigned u[2];
	char b[8];
} Bu;

/* enc/dec one 8byte block
Blowfish is defined in terms of two 32bit numbers ("left" and "right")
At least the paper http://www.schneier.com/paper-blowfish-fse.html
says nothing about byte order ("Divide x into two 32-bit halves").
Our preset P and S are already defined as numbers, which is fine.
So we leave input/output byte swapping to the outer layer.
*/
static void bfish ( BFish *ctx, Bu *block, int dec ) {
	Bu bu;
	enum { /* byte indexes, A=MSB .. D=LSB */
#ifdef CPU_BIG_ENDIAN
		A,B,C,D
#else
		D,C,B,A
#endif
	};
	const unsigned *a = ctx->S[0], *b = ctx->S[1], *c = ctx->S[2], *d = ctx->S[3];
#define F(x,o) (((a[(int)(x.b[A+(o)]&0xff)] + b[(int)(x.b[B+(o)]&0xff)]) ^ c[(int)(x.b[C+(o)]&0xff)]) + d[(int)(x.b[D+(o)]&0xff)])
	unsigned *P, *E;
	int step;

	bu = *block;
	if ( dec ) {
		E = ctx->P + 1;
		P = E + 16;
		step = -1;
	} else {
		P = ctx->P;
		E = P + 16;
		step = 1;
	}

	do { /* two per rep to at least avoid the swapping w/o too much code */
		bu.u[0] ^= *P;
		bu.u[1] ^= F(bu,0);

		bu.u[1] ^= *(P += step);
		bu.u[0] ^= F(bu,4);
	} while (E != (P += step));
	block->u[1] = bu.u[0] ^ E[0];
	block->u[0] = bu.u[1] ^ E[step];
}	/* bfish */


static void bfishInit (BFish *ctx, unsigned char *key, int keyLen)
{
	int i, j, k;
	unsigned data;
	Bu block;

	*ctx = BFishInit;

	for (j = i = 0; i < 18; ++i) {
		for (data = 0, k = 0; k < 4; ++k) {
		/* http://www.schneier.com/blowfish-bug.txt */
			data = (data << 8) | key[j];
			if (++j >= keyLen)
				j = 0;
		}
		ctx->P[i] ^= data;
	}

	block.t = 0;
	for (i = 0; i < 18; i += 2) {
		bfish(ctx, &block, 0 );
		ctx->P[i] = block.u[0];
		ctx->P[i + 1] = block.u[1];
	}
	for (i = 0; i < 4; ++i)
		for (j = 0; j < 256; j += 2) {
			bfish(ctx, &block, 0);
			ctx->S[i][j] = block.u[0];
			ctx->S[i][j + 1] = block.u[1];
		}
	/* data = block[0] = block[1] = 0; -- wipe */
}


/* return !0 iff we had a bad key (duplicate in S-box) */
static int bfishChkkey (BFish *ctx)
{
	int i;
	for (i = 0; i < 4; ++i) {
		unsigned *s = ctx->S[i], *p=s+1, *e=s+256, *q;
		do {
			unsigned t = *p;
			for (q = p; s < q--; ) if (t == *q) return 1; /* boing */
		} while (e > ++p);
	}
	return 0;
}

typedef struct {
	BFish    bfish;
	int      swap; /* do byteswapping */
	Bu ev; /* encrypting vector/last cipher block */
	Bu dv; /* decrypting " */
} Bf;

/*
	blowfish function(data [,decrypt])

	does blowfish in CBC mode: every input block is XORed with the
	previous cipher clock before being encrypted.
	Applications should prefix every stream with an initialization vector.
*/
static int bfishCBC (lua_State *L)
{
	Bf *bf = (Bf*)lua_touserdata(L, lua_upvalueindex(1));
	int len, pushed=0, dec = lua_toboolean(L, 2);
	const char *bytes = luaL_checklstring(L, 1, &len);

/* cleartext will be 0-padded to 8 bytes, but ciphertext must be in blocks */
	if (dec && (7 & len)) luaL_error(L, "bad cipher len");
	while (len) { /* go by the 8K */
		Bu buf[1024], *b=buf;
		unsigned *u;
		int use = len, blocks;

		if (use >= (int)sizeof buf) {
			use = sizeof buf;
			blocks = 1024;
		} else {
			blocks = (use+7)>>3;
			buf[blocks - 1].t = 0; /* pad */
		}
		memcpy(buf, bytes, use);
		bytes += use;
		len -= use;
		use = blocks<<3;

		if (bf->swap)
			for (u = (buf+blocks)->u; --u >= buf->u; )
				*u = SWAP32(*u);
		u = (buf+blocks)->u;
		if ( dec )
			for ( ;blocks--; b++ ) {
				Bu ciph = *b;
				bfish(&bf->bfish, b, 1 );
				b->t ^= bf->dv.t;
				bf->dv = ciph;
			}
		else
			for ( ;blocks--; b++ ) {
				b->t ^= bf->ev.t;
				bfish(&bf->bfish, b, 0);
				bf->ev = *b;
			}
		if (bf->swap) while (--u >= buf->u) *u = SWAP32(*u);
		lua_pushlstring(L, (char*)buf, use);
		if (8 == ++pushed) { lua_concat(L, 8); pushed = 1; }
	}
	if (1 != pushed) lua_concat(L, pushed);

	return 1;
}	/* bfishCBC */


/*
	blowfish(key [,initvec [,byteorder]])

	initvec = printf(%08X%08X, left, right)
	byteorder = native|littleendian|bigendian|swap (default: bigendian)
*/
static int crypto_bfish (lua_State *L)
{
	int len;
	const char *s = luaL_checklstring(L, 1, &len);

	Bf *bf = (Bf *)lua_newuserdata(L, sizeof *bf);
	bfishInit(&bf->bfish, (unsigned char*)s, len);
	bf->ev.t = bf->dv.t = 0;
	bf->swap = /* default bigendian */
#ifdef CPU_BIG_ENDIAN
		0;
#else
		1;
#endif
	if ((s = lua_tostring(L, 3))) /* byte order */
		switch (*s) {
#ifdef CPU_BIG_ENDIAN
		case 's':
			bf->swap = 1;
#else
		case 'l':
		case 'n':
			bf->swap = 0;
#endif
		}
	if ((s = lua_tostring(L, 2))) { /* init vector */
		unsigned left, right;
		if (2 != sscanf(s,"%8X%8X", &left, &right)) luaL_error(L, "bad vector");
		/*
			sscanf reads in iv ints as from BE repr to native, which we want.
			need to fixup, if external is not BE.
		*/
		if (
#ifndef CPU_BIG_ENDIAN
			!
#endif
			bf->swap
		) {
			left = SWAP32(left);
			right = SWAP32(right);
		}
/*	THIS CODE BREAKS strict-aliasing -- but alas w/o a warning issued

		((unsigned*)&bf->ev)[0] = left;
		((unsigned*)&bf->ev)[1] = right;
*/
		bf->ev.u[0] = left;
		bf->ev.u[1] = right;
		bf->dv = bf->ev;
	}
	lua_pushcclosure(L, bfishCBC, 1);
	lua_pushboolean(L, bfishChkkey(&bf->bfish));
	return 2;
}	/* crypto_bfish */

static const luaL_reg cryptlib[] = {
	{"sha1", crypto_sha1},
	{"blowfish", crypto_bfish},
	{NULL, NULL}
};


/* ** Open crypto library */
LUALIB_API int luaopen_crypto (lua_State *L) {
	luaL_register(L, SLN_CRYPTNAME, cryptlib);
	return 1;
}
