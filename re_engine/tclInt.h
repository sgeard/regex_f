/*
 * tclInt.h -- stub replacing Tcl's internal header.
 *
 * The RE engine source files include regex.h which includes tclInt.h.
 * This stub redirects to tcl_re_compat.h so that all Tcl-specific
 * symbols needed by the RE engine are provided without a Tcl installation.
 *
 * All copied Tcl source files in this directory are left byte-for-byte
 * identical to their originals so that future Tcl updates can be dropped
 * in by simply re-copying the files.
 */
#include "tcl_re_compat.h"
