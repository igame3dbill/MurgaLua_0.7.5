/*
 ---------------------------------------------------------------------------
 Copyright (c) 2003, Dr Brian Gladman, Worcester, UK.   All rights reserved.

 LICENSE TERMS

 The free distribution and use of this software in both source and binary
 form is allowed (with or without changes) provided that:

   1. distributions of this source code include the above copyright
      notice, this list of conditions and the following disclaimer;

   2. distributions in binary form include the above copyright
      notice, this list of conditions and the following disclaimer
      in the documentation and/or other associated materials;

   3. the copyright holder's name is not used to endorse products
      built using this software without specific written permission.

 ALTERNATIVELY, provided that this notice is retained in full, this product
 may be distributed under the terms of the GNU General Public License (GPL),
 in which case the provisions of the GPL apply INSTEAD OF those given above.

 DISCLAIMER

 This software is provided 'as is' with no explicit or implied warranties
 in respect of its properties, including, but not limited to, correctness
 and/or fitness for purpose.
 ---------------------------------------------------------------------------
 Issue 23/03/2004

 These subroutines implement multiple block AES modes for ECB, CBC, CFB,
 OFB and CTR encryption according to the prototypes in aes_modes.h. The
 code relies on dubious pointer manipulation on the assumption that the
 lowest 4 bits of a pointer can be used to assess alignment in memory.


 LWL: Added comments to CTR mode encryption while I try to understand the code.
 LWL: Added code for aes_ctr_set_bpos().
*/

#include <memory.h>
#include <assert.h>

#include "aesopt.h"
#include "aes_modes.h"

#ifdef _MSC_VER
#pragma intrinsic(memcpy)
#define in_line __inline
#else
#define in_line
#endif

#define BFR_BLOCKS      8

/* These values are used to detect long word alignment in order */
/* to speed up some GCM buffer operations. This facility may    */
/* not work on some machines                                    */

#define lp08(x)         ((aes_08t*)(x))
#define lp32(x)         ((aes_32t*)(x))
#define ADR_MASK        3
#define lp_inc          4

void aes_mode_reset(aes_encrypt_ctx ctx[1])
{
    ctx->inf.b[2] = 0;
}

aes_rval aes_ecb_encrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, const aes_encrypt_ctx ctx[1])
{   int nb = len >> 4;

    if(len & (AES_BLOCK_SIZE - 1))
        return aes_error;

    while(nb--)
    {
        aes_encrypt(ibuf, obuf, ctx);
        ibuf += AES_BLOCK_SIZE;
        obuf += AES_BLOCK_SIZE;
    }

    return aes_good;
}

aes_rval aes_ecb_decrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, const aes_decrypt_ctx ctx[1])
{   int nb = len >> 4;

    if(len & (AES_BLOCK_SIZE - 1))
        return aes_error;

    while(nb--)
    {
        aes_decrypt(ibuf, obuf, ctx);
        ibuf += AES_BLOCK_SIZE;
        obuf += AES_BLOCK_SIZE;
    }

    return aes_good;
}

aes_rval aes_cbc_encrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, unsigned char *iv, const aes_encrypt_ctx ctx[1])
{   int nb = len >> 4;

    if(len & (AES_BLOCK_SIZE - 1))
        return aes_error;

    if(!((iv - ibuf) & ADR_MASK) && !((obuf - ibuf) & ADR_MASK))
        while(nb--)
        {
            lp32(iv)[0] ^= lp32(ibuf)[0];
            lp32(iv)[1] ^= lp32(ibuf)[1];
            lp32(iv)[2] ^= lp32(ibuf)[2];
            lp32(iv)[3] ^= lp32(ibuf)[3];
            aes_encrypt(iv, iv, ctx);
            memcpy(obuf, iv, AES_BLOCK_SIZE);
            ibuf += AES_BLOCK_SIZE;
            obuf += AES_BLOCK_SIZE;
        }
    else
        while(nb--)
        {
            iv[ 0] ^= ibuf[ 0]; iv[ 1] ^= ibuf[ 1];
            iv[ 2] ^= ibuf[ 2]; iv[ 3] ^= ibuf[ 3];
            iv[ 4] ^= ibuf[ 4]; iv[ 5] ^= ibuf[ 5];
            iv[ 6] ^= ibuf[ 6]; iv[ 7] ^= ibuf[ 7];
            iv[ 8] ^= ibuf[ 8]; iv[ 9] ^= ibuf[ 9];
            iv[10] ^= ibuf[10]; iv[11] ^= ibuf[11];
            iv[12] ^= ibuf[12]; iv[13] ^= ibuf[13];
            iv[14] ^= ibuf[14]; iv[15] ^= ibuf[15];
            aes_encrypt(iv, iv, ctx);
            memcpy(obuf, iv, AES_BLOCK_SIZE);
            ibuf += AES_BLOCK_SIZE;
            obuf += AES_BLOCK_SIZE;
        }

    return aes_good;
}

aes_rval aes_cbc_decrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, unsigned char *iv, const aes_decrypt_ctx ctx[1])
{   unsigned char tmp[AES_BLOCK_SIZE];
    int nb = len >> 4;

    if(len & (AES_BLOCK_SIZE - 1))
        return aes_error;

    if(!((iv - ibuf) & ADR_MASK) && !((obuf - ibuf) & ADR_MASK))
        while(nb--)
        {
            memcpy(tmp, ibuf, AES_BLOCK_SIZE);
            aes_decrypt(ibuf, obuf, ctx);
            lp32(obuf)[0] ^= lp32(iv)[0];
            lp32(obuf)[1] ^= lp32(iv)[1];
            lp32(obuf)[2] ^= lp32(iv)[2];
            lp32(obuf)[3] ^= lp32(iv)[3];
            memcpy(iv, tmp, AES_BLOCK_SIZE);
            ibuf += AES_BLOCK_SIZE;
            obuf += AES_BLOCK_SIZE;
        }
    else
        while(nb--)
        {
            memcpy(tmp, ibuf, AES_BLOCK_SIZE);
            aes_decrypt(ibuf, obuf, ctx);
            obuf[ 0] ^= iv[ 0]; obuf[ 1] ^= iv[ 1];
            obuf[ 2] ^= iv[ 2]; obuf[ 3] ^= iv[ 3];
            obuf[ 4] ^= iv[ 4]; obuf[ 5] ^= iv[ 5];
            obuf[ 6] ^= iv[ 6]; obuf[ 7] ^= iv[ 7];
            obuf[ 8] ^= iv[ 8]; obuf[ 9] ^= iv[ 9];
            obuf[10] ^= iv[10]; obuf[11] ^= iv[11];
            obuf[12] ^= iv[12]; obuf[13] ^= iv[13];
            obuf[14] ^= iv[14]; obuf[15] ^= iv[15];
            memcpy(iv, tmp, AES_BLOCK_SIZE);
            ibuf += AES_BLOCK_SIZE;
            obuf += AES_BLOCK_SIZE;
        }

    return aes_good;
}

aes_rval aes_cfb_encrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, unsigned char *iv, aes_encrypt_ctx ctx[1])
{   int cnt = 0, b_pos = (int)ctx->inf.b[2], nb;

    if(b_pos)           /* complete any partial block   */
    {
        while(b_pos < AES_BLOCK_SIZE && cnt < len)
            *obuf++ = iv[b_pos++] ^= *ibuf++, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    if(nb = (len - cnt) >> 4)   /* process whole blocks */
    {
        if(!((iv - ibuf) & ADR_MASK) && !((obuf - ibuf) & ADR_MASK))
            while(cnt + AES_BLOCK_SIZE <= len)
            {
                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                lp32(obuf)[0] = lp32(iv)[0] ^= lp32(ibuf)[0];
                lp32(obuf)[1] = lp32(iv)[1] ^= lp32(ibuf)[1];
                lp32(obuf)[2] = lp32(iv)[2] ^= lp32(ibuf)[2];
                lp32(obuf)[3] = lp32(iv)[3] ^= lp32(ibuf)[3];
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
        else
            while(cnt + AES_BLOCK_SIZE <= len)
            {
                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                obuf[ 0] = iv[ 0] ^= ibuf[ 0]; obuf[ 1] = iv[ 1] ^= ibuf[ 1];
                obuf[ 2] = iv[ 2] ^= ibuf[ 2]; obuf[ 3] = iv[ 3] ^= ibuf[ 3];
                obuf[ 4] = iv[ 4] ^= ibuf[ 4]; obuf[ 5] = iv[ 5] ^= ibuf[ 5];
                obuf[ 6] = iv[ 6] ^= ibuf[ 6]; obuf[ 7] = iv[ 7] ^= ibuf[ 7];
                obuf[ 8] = iv[ 8] ^= ibuf[ 8]; obuf[ 9] = iv[ 9] ^= ibuf[ 9];
                obuf[10] = iv[10] ^= ibuf[10]; obuf[11] = iv[11] ^= ibuf[11];
                obuf[12] = iv[12] ^= ibuf[12]; obuf[13] = iv[13] ^= ibuf[13];
                obuf[14] = iv[14] ^= ibuf[14]; obuf[15] = iv[15] ^= ibuf[15];
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
    }

    while(cnt < len)
    {
        if(!b_pos)
            aes_encrypt(iv, iv, ctx);

        while(cnt < len && b_pos < AES_BLOCK_SIZE)
            *obuf++ = iv[b_pos++] ^= *ibuf++, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    ctx->inf.b[2] = b_pos;
    return aes_good;
}

aes_rval aes_cfb_decrypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, unsigned char *iv, aes_encrypt_ctx ctx[1])
{   int cnt = 0, b_pos = (int)ctx->inf.b[2], nb;

    if(b_pos)           /* complete any partial block   */
    {   aes_08t t;

        while(b_pos < AES_BLOCK_SIZE && cnt < len)
            t = *ibuf++, *obuf++ = t ^ iv[b_pos], iv[b_pos++] = t, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    if(nb = (len - cnt) >> 4)   /* process whole blocks */
    {
        if(!((iv - ibuf) & ADR_MASK) && !((obuf - ibuf) & ADR_MASK))
            while(cnt + AES_BLOCK_SIZE <= len)
            {   aes_32t t;

                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                t = lp32(ibuf)[0], lp32(obuf)[0] = t ^ lp32(iv)[0], lp32(iv)[0] = t;
                t = lp32(ibuf)[1], lp32(obuf)[1] = t ^ lp32(iv)[1], lp32(iv)[1] = t;
                t = lp32(ibuf)[2], lp32(obuf)[2] = t ^ lp32(iv)[2], lp32(iv)[2] = t;
                t = lp32(ibuf)[3], lp32(obuf)[3] = t ^ lp32(iv)[3], lp32(iv)[3] = t;
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
        else
            while(cnt + AES_BLOCK_SIZE <= len)
            {   aes_08t t;

                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                t = ibuf[ 0], obuf[ 0] = t ^ iv[ 0], iv[ 0] = t;
                t = ibuf[ 1], obuf[ 1] = t ^ iv[ 1], iv[ 1] = t;
                t = ibuf[ 2], obuf[ 2] = t ^ iv[ 2], iv[ 2] = t;
                t = ibuf[ 3], obuf[ 3] = t ^ iv[ 3], iv[ 3] = t;
                t = ibuf[ 4], obuf[ 4] = t ^ iv[ 4], iv[ 4] = t;
                t = ibuf[ 5], obuf[ 5] = t ^ iv[ 5], iv[ 5] = t;
                t = ibuf[ 6], obuf[ 6] = t ^ iv[ 6], iv[ 6] = t;
                t = ibuf[ 7], obuf[ 7] = t ^ iv[ 7], iv[ 7] = t;
                t = ibuf[ 8], obuf[ 8] = t ^ iv[ 8], iv[ 8] = t;
                t = ibuf[ 9], obuf[ 9] = t ^ iv[ 9], iv[ 9] = t;
                t = ibuf[10], obuf[10] = t ^ iv[10], iv[10] = t;
                t = ibuf[11], obuf[11] = t ^ iv[11], iv[11] = t;
                t = ibuf[12], obuf[12] = t ^ iv[12], iv[12] = t;
                t = ibuf[13], obuf[13] = t ^ iv[13], iv[13] = t;
                t = ibuf[14], obuf[14] = t ^ iv[14], iv[14] = t;
                t = ibuf[15], obuf[15] = t ^ iv[15], iv[15] = t;
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
    }

    while(cnt < len)
    {   aes_08t t;

        if(!b_pos)
            aes_encrypt(iv, iv, ctx);

        while(cnt < len && b_pos < AES_BLOCK_SIZE)
            t = *ibuf++, *obuf++ = t ^ iv[b_pos], iv[b_pos++] = t, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    ctx->inf.b[2] = b_pos;
    return aes_good;
}

aes_rval aes_ofb_crypt(const unsigned char *ibuf, unsigned char *obuf,
                    int len, unsigned char *iv, aes_encrypt_ctx ctx[1])
{   int cnt = 0, b_pos = (int)ctx->inf.b[2], nb;

    if(b_pos)           /* complete any partial block   */
    {
        while(b_pos < AES_BLOCK_SIZE && cnt < len)
            *obuf++ = iv[b_pos++] ^ *ibuf++, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    if(nb = (len - cnt) >> 4)   /* process whole blocks */
    {
        if(!((iv - ibuf) & ADR_MASK) && !((obuf - ibuf) & ADR_MASK))
            while(cnt + AES_BLOCK_SIZE <= len)
            {
                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                lp32(obuf)[0] = lp32(iv)[0] ^ lp32(ibuf)[0];
                lp32(obuf)[1] = lp32(iv)[1] ^ lp32(ibuf)[1];
                lp32(obuf)[2] = lp32(iv)[2] ^ lp32(ibuf)[2];
                lp32(obuf)[3] = lp32(iv)[3] ^ lp32(ibuf)[3];
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
        else
            while(cnt + AES_BLOCK_SIZE <= len)
            {
                assert(b_pos == 0);
                aes_encrypt(iv, iv, ctx);
                obuf[ 0] = iv[ 0] ^ ibuf[ 0]; obuf[ 1] = iv[ 1] ^ ibuf[ 1];
                obuf[ 2] = iv[ 2] ^ ibuf[ 2]; obuf[ 3] = iv[ 3] ^ ibuf[ 3];
                obuf[ 4] = iv[ 4] ^ ibuf[ 4]; obuf[ 5] = iv[ 5] ^ ibuf[ 5];
                obuf[ 6] = iv[ 6] ^ ibuf[ 6]; obuf[ 7] = iv[ 7] ^ ibuf[ 7];
                obuf[ 8] = iv[ 8] ^ ibuf[ 8]; obuf[ 9] = iv[ 9] ^ ibuf[ 9];
                obuf[10] = iv[10] ^ ibuf[10]; obuf[11] = iv[11] ^ ibuf[11];
                obuf[12] = iv[12] ^ ibuf[12]; obuf[13] = iv[13] ^ ibuf[13];
                obuf[14] = iv[14] ^ ibuf[14]; obuf[15] = iv[15] ^ ibuf[15];
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
                cnt  += AES_BLOCK_SIZE;
            }
    }

    while(cnt < len)
    {
        if(!b_pos)
            aes_encrypt(iv, iv, ctx);

        while(cnt < len && b_pos < AES_BLOCK_SIZE)
            *obuf++ = iv[b_pos++] ^ *ibuf++, cnt++;

        b_pos = (b_pos == AES_BLOCK_SIZE ? 0 : b_pos);
    }

    ctx->inf.b[2] = b_pos;
    return aes_good;
}

/* LWL: Length of encryption buffer, multiple of AES encryption block size */
#define BFR_LENGTH  (BFR_BLOCKS * AES_BLOCK_SIZE)

/*
	LWL: (En/De)crypt data using AES in CTR mode
	ibuf = input buffer
	obuf = output buffer (can be same as ibuf)
	len = number of bytes in input buffer
	cbuf = counter/nonce for CTR mode, at least as large as AES_BLOCK_SIZE
	ctr_inc = pointer to function that increments cbuf
	ctx = encryption/decryption context

	In the comments, 'crypt' = encrypt or decrypt (since CTR only needs one
	function to do both)
*/
aes_rval aes_ctr_crypt(const unsigned char *ibuf, unsigned char *obuf,
            int len, unsigned char *cbuf, cbuf_inc ctr_inc, aes_encrypt_ctx ctx[1])
{   aes_08t buf[BFR_LENGTH], *ip;
    int     i, blen, b_pos = (int)(ctx->inf.b[2]);
	/* ctx->inf.b[2] contains current position in cryption buffer */

	/*
		If there are leftover bytes in cryption buffer, use it to crypt
		as many bytes as possible or needed
	*/
    if(b_pos)
    {
        memcpy(buf, cbuf, AES_BLOCK_SIZE);
        aes_encrypt(buf, buf, ctx);
        while(b_pos < AES_BLOCK_SIZE && len--)
            *obuf++ = *ibuf++ ^ buf[b_pos++];
        if(len)	/* still more data to encrypt? increment counter */
            ctr_inc(cbuf), b_pos = 0;
    }

    while(len)
    {
		 	/* Find out how many bytes to crypt next */
        blen = (len > BFR_LENGTH ? BFR_LENGTH : len), len -= blen;

			/*
				Move in as many counters as needed to crypt 'blen' bytes.
				this part moves as many whole blocks as needed.

				=== I think the author is assuming a block size of 16
				(see the right shift by 4). ===
			*/
        for(i = 0, ip = buf; i < (blen >> 4); ++i)
        {
            memcpy(ip, cbuf, AES_BLOCK_SIZE);
            ctr_inc(cbuf);
            ip += AES_BLOCK_SIZE;
        }

			/* This part moves another counter to cover any remainder */
        i = (blen >> 4);
        if(blen & (AES_BLOCK_SIZE - 1))
            memcpy(ip, cbuf, AES_BLOCK_SIZE), i++;

			/* Get the crypt buffer to xor the input with */
        aes_ecb_encrypt(buf, buf, i * AES_BLOCK_SIZE, ctx);

			/*
				Here you can see that the author definitely assumes a block size
				of 16 (either 0-15 bytes or 4 32-bit words).

				Not sure what the if statement checks. 32-bit word alignment?
				Anyway the while loop XORs the input data whole blocks at a time.
			*/
        i = 0; ip = buf;
        if(!((obuf - ip) & ADR_MASK))
            while(i + AES_BLOCK_SIZE <= blen)
            {
						/* XOR input data 4 bytes (a 32-bit word) at a time */
                lp32(obuf)[0] = lp32(ibuf)[0] ^ lp32(ip)[0];
                lp32(obuf)[1] = lp32(ibuf)[1] ^ lp32(ip)[1];
                lp32(obuf)[2] = lp32(ibuf)[2] ^ lp32(ip)[2];
                lp32(obuf)[3] = lp32(ibuf)[3] ^ lp32(ip)[3];
                i += AES_BLOCK_SIZE;
                ip += AES_BLOCK_SIZE;
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
            }
        else
            while(i + AES_BLOCK_SIZE <= blen)
            {
						/* XOR input data one byte at a time 16 (block size) times */
                obuf[ 0] = ibuf[ 0] ^ ip[ 0]; obuf[ 1] = ibuf[ 1] ^ ip[ 1];
                obuf[ 2] = ibuf[ 2] ^ ip[ 2]; obuf[ 3] = ibuf[ 3] ^ ip[ 3];
                obuf[ 4] = ibuf[ 4] ^ ip[ 4]; obuf[ 5] = ibuf[ 5] ^ ip[ 5];
                obuf[ 6] = ibuf[ 6] ^ ip[ 6]; obuf[ 7] = ibuf[ 7] ^ ip[ 7];
                obuf[ 8] = ibuf[ 8] ^ ip[ 8]; obuf[ 9] = ibuf[ 9] ^ ip[ 9];
                obuf[10] = ibuf[10] ^ ip[10]; obuf[11] = ibuf[11] ^ ip[11];
                obuf[12] = ibuf[12] ^ ip[12]; obuf[13] = ibuf[13] ^ ip[13];
                obuf[14] = ibuf[14] ^ ip[14]; obuf[15] = ibuf[15] ^ ip[15];
                i += AES_BLOCK_SIZE;
                ip += AES_BLOCK_SIZE;
                ibuf += AES_BLOCK_SIZE;
                obuf += AES_BLOCK_SIZE;
            }

			/* XOR the remaining input data in 'buf' that was less than a block */
        while(i++ < blen)
            *obuf++ = *ibuf++ ^ ip[b_pos++];
    }

	/* Store location of first unused byte in crypt buffer in the context */
    ctx->inf.b[2] = b_pos;
    return aes_good;
}

/*
	LWL: This function will set the value that will be used as b_pos in
	aes_ctr_crypt() above so that one can start at a specified location in the
	"key stream" provided by a specific counter value.

	bpos must be between 0 and AES_BLOCK_SIZE - 1.
*/
void aes_ctr_set_bpos(aes_encrypt_ctx cx[1], int bpos)
{
	if (bpos < 0 || bpos > AES_BLOCK_SIZE - 1)
		bpos = 0;

	cx->inf.b[2] = bpos;
}

