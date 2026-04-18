/*
 * tclInterface.c -- C interface to the Tcl ARE regular expression engine.
 *
 * Calls TclReComp/TclReExec directly; no Tcl interpreter or Tcl_Obj machinery
 * is required.  The engine is compiled in from re_engine/ alongside utf8proc.
 *
 * Match index pairs are returned as byte offsets (0-based, exclusive end)
 * into the UTF-8 text string.
 */

#include "tclInterface.h"
#include "re_engine/regex.h"
#include "utf8proc/utf8proc.h"

#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/* Internal cache                                                       */
/* ------------------------------------------------------------------ */

#define N_MAX_RE      32
#define N_MAX_MATCHES 64

typedef struct {
    regex_t  re;
    int      in_use;
    int      matched;                  /* 1 if last apply found a match */
    int      nsubs;                    /* re.re_nsub from last compile   */
    size_t   so[N_MAX_MATCHES];        /* byte offset: start (inclusive) */
    size_t   eo[N_MAX_MATCHES];        /* byte offset: end   (exclusive) */
} ReEntry;

static ReEntry s_cache[N_MAX_RE];
static int     s_initialized = 0;

static void ensure_init(void) {
    if (!s_initialized) {
        memset(s_cache, 0, sizeof(s_cache));
        s_initialized = 1;
    }
}

/* ------------------------------------------------------------------ */
/* UTF-8 helpers                                                        */
/* ------------------------------------------------------------------ */

/*
 * Decode a NUL-terminated UTF-8 string into a newly malloc'd Tcl_UniChar
 * array.  *nchars is set to the number of codepoints (not bytes).
 * Caller must free() the returned pointer.
 */
static Tcl_UniChar *utf8_to_unichars(const char *str, size_t *nchars) {
    size_t nbytes = strlen(str);
    Tcl_UniChar *buf = malloc((nbytes + 1) * sizeof(Tcl_UniChar));
    if (!buf) { *nchars = 0; return NULL; }

    size_t n = 0;
    const utf8proc_uint8_t *p = (const utf8proc_uint8_t *)str;
    while (*p) {
        utf8proc_int32_t cp;
        utf8proc_ssize_t adv = utf8proc_iterate(p, -1, &cp);
        if (adv <= 0) break;
        buf[n++] = (Tcl_UniChar)cp;
        p += adv;
    }
    buf[n] = 0;
    *nchars = n;
    return buf;
}

/*
 * Walk a UTF-8 string and return the byte offset of codepoint number
 * char_pos (0-based).  Returns the byte length of the string if char_pos
 * is past the end.
 */
static size_t unichar_to_byte(const char *str, size_t char_pos) {
    const utf8proc_uint8_t *p = (const utf8proc_uint8_t *)str;
    size_t n = 0;
    while (n < char_pos && *p) {
        utf8proc_int32_t cp;
        utf8proc_ssize_t adv = utf8proc_iterate(p, -1, &cp);
        if (adv <= 0) break;
        p += adv;
        n++;
    }
    return (size_t)((const char *)p - str);
}

/* ------------------------------------------------------------------ */
/* Public API                                                           */
/* ------------------------------------------------------------------ */

tcl_re_handle tcl_re_compile(const char *pattern, int flags) {
    ensure_init();

    int h = -1;
    for (int i = 0; i < N_MAX_RE; i++) {
        if (!s_cache[i].in_use) { h = i; break; }
    }
    if (h < 0) return -1;   /* cache full */

    size_t nchars;
    Tcl_UniChar *upat = utf8_to_unichars(pattern, &nchars);
    if (!upat) return -2;

    int status = TclReComp(&s_cache[h].re, upat, nchars, flags);
    free(upat);

    if (status != REG_OKAY) return -2;   /* compile error */

    s_cache[h].in_use  = 1;
    s_cache[h].matched = 0;
    s_cache[h].nsubs   = (int)s_cache[h].re.re_nsub;
    return h;
}

int tcl_re_apply(tcl_re_handle h, const char *text) {
    if (h < 0 || h >= N_MAX_RE || !s_cache[h].in_use) return -1;

    ReEntry *e   = &s_cache[h];
    size_t   nm  = (size_t)e->nsubs + 1;
    if (nm > N_MAX_MATCHES) nm = N_MAX_MATCHES;

    regmatch_t *matches = malloc(nm * sizeof(regmatch_t));
    if (!matches) return -1;

    size_t nchars;
    Tcl_UniChar *utext = utf8_to_unichars(text, &nchars);
    if (!utext) { free(matches); return -1; }

    int status = TclReExec(&e->re, utext, nchars, NULL, nm, matches, 0);
    free(utext);

    if (status != REG_OKAY) {
        free(matches);
        e->matched = 0;
        return 0;
    }

    /* Convert Unicode char positions -> byte offsets in original UTF-8 text */
    for (size_t i = 0; i < nm; i++) {
        if (matches[i].rm_so == (size_t)-1) {
            e->so[i] = (size_t)-1;
            e->eo[i] = (size_t)-1;
        } else {
            e->so[i] = unichar_to_byte(text, matches[i].rm_so);
            e->eo[i] = unichar_to_byte(text, matches[i].rm_eo);
        }
    }
    e->matched = 1;
    free(matches);
    return e->nsubs;
}

int tcl_re_get_match_indices(tcl_re_handle h, int index, int *i_start, int *i_end) {
    if (h < 0 || h >= N_MAX_RE || !s_cache[h].in_use)
        return -1;
    if (!s_cache[h].matched)
        return -1;
    if (index < 0 || index > s_cache[h].nsubs || index >= N_MAX_MATCHES)
        return 0;

    *i_start = (int)s_cache[h].so[index];
    *i_end   = (int)s_cache[h].eo[index];
    return 1;
}

int tcl_re_match(const char *pattern, const char *text, int flags) {
    tcl_re_handle h = tcl_re_compile(pattern, flags);
    if (h < 0) return 0;
    int result = (tcl_re_apply(h, text) >= 0) && s_cache[h].matched;
    tcl_re_delete(&h);
    return result;
}

int tcl_re_matched(tcl_re_handle h) {
    if (h < 0 || h >= N_MAX_RE || !s_cache[h].in_use) return 0;
    return s_cache[h].matched;
}

int tcl_re_delete(tcl_re_handle *h) {
    if (!h || *h < 0 || *h >= N_MAX_RE || !s_cache[*h].in_use) return 0;
    TclReFree(&s_cache[*h].re);
    s_cache[*h].in_use  = 0;
    s_cache[*h].matched = 0;
    *h = -1;
    return 1;
}

void tcl_re_reset(void) {
    for (int i = 0; i < N_MAX_RE; i++) {
        if (s_cache[i].in_use)
            TclReFree(&s_cache[i].re);
        s_cache[i].in_use  = 0;
        s_cache[i].matched = 0;
    }
}
