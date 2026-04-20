#ifndef tclInterface_h_included
#define tclInterface_h_included

/*
 * C interface to the Tcl ARE regular expression engine.
 */

#ifdef __cplusplus
extern "C" {
#endif

typedef int tcl_re_handle;

/*
 * Regex type flags -- may be combined with bitwise OR.
 * Values match the REG_* constants in the Tcl RE engine.
 */
#define TCL_RE_BASIC     0    /* Basic regular expressions (BRE)          */
#define TCL_RE_EXTENDED  1    /* Extended regular expressions (ERE)       */
#define TCL_RE_ADVANCED  3    /* Advanced regular expressions (ARE)       */
#define TCL_RE_ICASE     8    /* Case-insensitive matching                */
#define TCL_RE_NOSUB     16   /* Do not report subexpression matches      */
#define TCL_RE_EXPANDED  32   /* Whitespace and # comments ignored        */
#define TCL_RE_NEWLINE   192  /* Newlines act as line terminators         */

/**
 * Compile a regular expression and return a handle to it.
 *   flags   : combination of TCL_RE_* constants (TCL_RE_ADVANCED recommended)
 *   returns : >= 0  valid handle
 *             -1    cache full (call tcl_re_reset() and retry)
 *             -2    syntax error in pattern
 */
tcl_re_handle tcl_re_compile(const char *pattern, int flags);

/**
 * Apply a compiled regexp to a text string.
 *   returns : >= 0  number of subexpression matches (0 = whole match only)
 *             -1    invalid handle
 */
int tcl_re_apply(tcl_re_handle, const char *text);

/**
 * Get the byte-offset range for match index idx.
 *   idx = 0 : whole match;  idx >= 1 : subexpressions
 *   returns : 1  success (*i_start and *i_end filled, 0-based exclusive end)
 *             0  idx out of range
 *            -1  handle invalid or regexp not yet applied
 */
int tcl_re_get_match_indices(tcl_re_handle, int idx, int *i_start, int *i_end);

/**
 * One-shot compile-and-match test.
 *   returns : 1 if text matches pattern, 0 otherwise
 */
int tcl_re_match(const char *pattern, const char *text, int flags);

/**
 * Query whether the last tcl_re_apply() on this handle found a match.
 *   returns : 1 if matched, 0 if not matched or handle invalid
 */
int tcl_re_matched(tcl_re_handle h);

/**
 * Release a compiled regexp; sets *h to -1.
 *   returns : 1 on success, 0 if handle was invalid
 */
int tcl_re_delete(tcl_re_handle *h);

/**
 * Reset the internal cache; all existing handles become invalid.
 */
void tcl_re_reset(void);

#ifdef __cplusplus
}
#endif

#endif
