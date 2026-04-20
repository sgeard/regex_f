/*
 * tclInt.h -- stub replacing Tcl's internal header.
 *
 * The RE engine source files (in ../re_engine/) include regex.h which
 * includes tclInt.h.  This stub is picked up via -I compat and redirects
 * to tcl_re_compat.h so the Tcl-specific symbols needed by the RE engine
 * are provided without a Tcl installation.
 *
 * Sibling directory ../re_engine/ holds byte-for-byte copies of the Tcl
 * sources so future Tcl updates can be dropped in by re-copying the files.
 */
#include "tcl_re_compat.h"
