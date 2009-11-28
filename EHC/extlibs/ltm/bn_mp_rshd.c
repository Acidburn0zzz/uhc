#include "tommath.h"
#ifdef BN_MP_RSHD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis
 *
 * LibTomMath is a library that provides multiple-precision
 * integer arithmetic as well as number theoretic functionality.
 *
 * The library was designed directly after the MPI library by
 * Michael Fromberger but has been written from scratch with
 * additional optimizations in place.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 *
 * Tom St Denis, tomstdenis@gmail.com, http://math.libtomcrypt.com
 */

/* shift right a certain amount of digits */
void mp_rshd (mp_int * a, int b)
{
  int     x;

  /* if b <= 0 then ignore it */
  if (b <= 0) {
    return;
  }

  /* if b > used then simply zero it and return */
  if (USED(a) <= b) {
    mp_zero (a);
    return;
  }

  {
    register mp_digit *bottom, *top;

    /* shift the digits down */

    /* bottom */
    bottom = DIGITS(a);

    /* top [offset into digits] */
    top = DIGITS(a) + b;

    /* this is implemented as a sliding window where 
     * the window is b-digits long and digits from 
     * the top of the window are copied to the bottom
     *
     * e.g.

     b-2 | b-1 | b0 | b1 | b2 | ... | bb |   ---->
                 /\                   |      ---->
                  \-------------------/      ---->
     */
    for (x = 0; x < (USED(a) - b); x++) {
      *bottom++ = *top++;
    }

    /* zero the top digits */
    for (; x < USED(a); x++) {
      *bottom++ = 0;
    }
  }
  
  /* remove excess digits */
  DEC_USED(a,b);
}
#endif

/* $Source: /cvs/libtom/libtommath/bn_mp_rshd.c,v $ */
/* $Revision: 1.3 $ */
/* $Date: 2006/03/31 14:18:44 $ */