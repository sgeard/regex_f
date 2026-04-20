/*
 * tcl_re_compat.h --
 *
 * Minimal compatibility shim replacing Tcl's tclInt.h, allowing the Tcl
 * regular expression engine to be compiled standalone without a Tcl
 * installation.  Only the symbols actually needed by the RE engine files
 * are provided.
 */

#ifndef TCL_RE_COMPAT_H_INCLUDED
#define TCL_RE_COMPAT_H_INCLUDED

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>     /* FILE, used by debug paths in regcomp.c/regexec.c */

/* Provided by tclInt.h in normal Tcl builds; needed by the RE engine. */
#define UCHAR(c)        ((unsigned char)(c))
#define TCL_Z_MODIFIER  "z"   /* printf modifier for size_t */

#include "utf8proc.h"

/* ------------------------------------------------------------------ */
/* Core types                                                           */
/* ------------------------------------------------------------------ */

typedef uint32_t  Tcl_UniChar;   /* Unicode codepoint */
typedef ptrdiff_t Tcl_Size;

/* ------------------------------------------------------------------ */
/* Symbol visibility                                                    */
/* ------------------------------------------------------------------ */

#define MODULE_SCOPE extern

/* ------------------------------------------------------------------ */
/* Memory allocation -- map to standard malloc                         */
/* ------------------------------------------------------------------ */

#define Tcl_Alloc(n)             malloc(n)
#define Tcl_AttemptAlloc(n)      malloc(n)
#define Tcl_Free(p)              free(p)
#define Tcl_AttemptRealloc(p,n)  realloc((p),(n))

/* ------------------------------------------------------------------ */
/* Unicode character classification                                     */
/* ------------------------------------------------------------------ */

/*
 * Bit-mask values matching those in Tcl's tclUtf.c.  The bit at position
 * utf8proc_category(codepoint) indicates membership of the category set.
 */
enum {
    TCLRE_ALPHA_BITS =
        (1 << UTF8PROC_CATEGORY_LU) | (1 << UTF8PROC_CATEGORY_LL) |
        (1 << UTF8PROC_CATEGORY_LT) | (1 << UTF8PROC_CATEGORY_LM) |
        (1 << UTF8PROC_CATEGORY_LO),
    TCLRE_DIGIT_BITS = (1 << UTF8PROC_CATEGORY_ND),
    TCLRE_SPACE_BITS = (1 << UTF8PROC_CATEGORY_ZS) |
                       (1 << UTF8PROC_CATEGORY_ZL) |
                       (1 << UTF8PROC_CATEGORY_ZP)
};

static inline int Tcl_UniCharIsAlnum(Tcl_UniChar ch) {
    return ((TCLRE_ALPHA_BITS | TCLRE_DIGIT_BITS)
            >> utf8proc_category(ch & 0x10FFFF)) & 1;
}
static inline int Tcl_UniCharIsAlpha(Tcl_UniChar ch) {
    return (TCLRE_ALPHA_BITS >> utf8proc_category(ch & 0x10FFFF)) & 1;
}
static inline int Tcl_UniCharIsDigit(Tcl_UniChar ch) {
    return utf8proc_category(ch & 0x10FFFF) == UTF8PROC_CATEGORY_ND;
}
static inline int Tcl_UniCharIsSpace(Tcl_UniChar ch) {
    /* ASCII fast path covers the common case */
    if (ch < 0x80)
        return ch == ' ' || ch == '\t' || ch == '\n' ||
               ch == '\r' || ch == '\f' || ch == '\v';
    return (TCLRE_SPACE_BITS >> utf8proc_category(ch & 0x10FFFF)) & 1;
}

/* ------------------------------------------------------------------ */
/* Unicode case conversion                                              */
/* ------------------------------------------------------------------ */

static inline Tcl_UniChar Tcl_UniCharToLower(Tcl_UniChar ch) {
    return (Tcl_UniChar)utf8proc_tolower(ch & 0x10FFFF);
}
static inline Tcl_UniChar Tcl_UniCharToUpper(Tcl_UniChar ch) {
    return (Tcl_UniChar)utf8proc_toupper(ch & 0x10FFFF);
}
static inline Tcl_UniChar Tcl_UniCharToTitle(Tcl_UniChar ch) {
    return (Tcl_UniChar)utf8proc_totitle(ch & 0x10FFFF);
}

/* ------------------------------------------------------------------ */
/* Thread-local data                                                    */
/*                                                                      */
/* regcustom.h uses Tcl_ThreadDataKey / Tcl_GetThreadData to give the  */
/* RE engine a per-thread working-memory block (struct vars).  We       */
/* implement this with a void* key stored at each static call site,     */
/* which is correct for single-threaded use.  The RE engine is never    */
/* re-entered from the same thread, so one buffer per call site is      */
/* safe.  For a multi-threaded application, replace with a proper       */
/* pthread_key_t implementation.                                        */
/* ------------------------------------------------------------------ */

typedef void *Tcl_ThreadDataKey;   /* NULL until first use */

static inline void *Tcl_GetThreadData(Tcl_ThreadDataKey *key, size_t size) {
    if (*key == NULL)
        *key = calloc(1, size);
    return *key;
}

/* ------------------------------------------------------------------ */
/* Minimal Tcl_DString                                                  */
/*                                                                      */
/* Only the operations used by regc_locale.c are implemented:          */
/*   Init, Free, and UniCharToUtfDString.                              */
/* ------------------------------------------------------------------ */

#define TCL_DSTRING_STATIC_SIZE 200

typedef struct {
    char *string;
    int   length;
    int   spaceAvl;
    char  staticSpace[TCL_DSTRING_STATIC_SIZE];
} Tcl_DString;

static inline void Tcl_DStringInit(Tcl_DString *dsPtr) {
    dsPtr->string        = dsPtr->staticSpace;
    dsPtr->length        = 0;
    dsPtr->spaceAvl      = TCL_DSTRING_STATIC_SIZE;
    dsPtr->staticSpace[0] = '\0';
}

static inline void Tcl_DStringFree(Tcl_DString *dsPtr) {
    if (dsPtr->string != dsPtr->staticSpace)
        free(dsPtr->string);
    Tcl_DStringInit(dsPtr);
}

/* Encode a single Unicode codepoint as UTF-8; returns bytes written. */
static inline int TclReUniCharToUtf(uint32_t ch, char *buf) {
    if (ch < 0x80) {
        buf[0] = (char)ch;
        return 1;
    } else if (ch < 0x800) {
        buf[0] = (char)(0xC0 | (ch >> 6));
        buf[1] = (char)(0x80 | (ch & 0x3F));
        return 2;
    } else if (ch < 0x10000) {
        buf[0] = (char)(0xE0 | (ch >> 12));
        buf[1] = (char)(0x80 | ((ch >> 6) & 0x3F));
        buf[2] = (char)(0x80 | (ch & 0x3F));
        return 3;
    } else {
        buf[0] = (char)(0xF0 | (ch >> 18));
        buf[1] = (char)(0x80 | ((ch >> 12) & 0x3F));
        buf[2] = (char)(0x80 | ((ch >> 6) & 0x3F));
        buf[3] = (char)(0x80 | (ch & 0x3F));
        return 4;
    }
}

/* Convert a Tcl_UniChar array to UTF-8, storing the result in dsPtr. */
static inline const char *Tcl_UniCharToUtfDString(
    const Tcl_UniChar *uniStr, size_t numChars, Tcl_DString *dsPtr)
{
    size_t maxBytes = numChars * 4 + 1;
    if (maxBytes > (size_t)dsPtr->spaceAvl) {
        if (dsPtr->string != dsPtr->staticSpace)
            free(dsPtr->string);
        dsPtr->string   = (char *)malloc(maxBytes);
        dsPtr->spaceAvl = (int)maxBytes;
    }
    char *p = dsPtr->string;
    for (size_t i = 0; i < numChars; i++)
        p += TclReUniCharToUtf(uniStr[i], p);
    *p = '\0';
    dsPtr->length = (int)(p - dsPtr->string);
    return dsPtr->string;
}

#endif /* TCL_RE_COMPAT_H_INCLUDED */
