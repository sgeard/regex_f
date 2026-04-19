.PHONY: all clean veryclean help

# -----------------------------------------------------------------------
# Compiler and build-mode selection  (mirrors code/ and hp/ projects)
# Usage:  make [intel=t] [release=t]
# -----------------------------------------------------------------------
ifdef release
    OBJ_DIR_SUFF := _release
else
    OBJ_DIR_SUFF := _debug
endif

ifdef intel
    ODIR  := obj_intel$(OBJ_DIR_SUFF)
    CC    := gcc
    FC    := ifx
    # RE_COPTS: flags for copied third-party C (no -Wall to avoid false positives)
    # COPTS:    flags for our own tclInterface.c (with -Wall)
    RE_COPTS := -I re_engine -I utf8proc -DUTF8PROC_STATIC
    COPTS    := $(RE_COPTS) -Wall
    FOPTS    := -fPIC -fpp -module $(ODIR) -I$(ODIR) -diag-disable=7712
    ifdef release
        RE_COPTS += -O2
        COPTS    += -O2
        FOPTS    += -O3 -xHost -fp-model precise -warn all
    else
        RE_COPTS += -g
        COPTS    += -g
        FOPTS    += -D_DEBUG -O0 -g -check bounds -warn all -traceback -debug-parameters used
    endif
    LINK_OPTS := -static-intel
else ifdef flang
    ODIR  := obj_flang$(OBJ_DIR_SUFF)
    CC    := gcc
    FC    := flang
    RE_COPTS := -I re_engine -I utf8proc -DUTF8PROC_STATIC -fPIC
    COPTS    := $(RE_COPTS) -Wall
    FOPTS    := -cpp -fimplicit-none -module-dir $(ODIR) -I$(ODIR)
    ifdef release
        RE_COPTS += -O2
        COPTS    += -O2
        FOPTS    += -O3
    else
        RE_COPTS += -g
        COPTS    += -g
        FOPTS    += -D_DEBUG -O0 -g
    endif
    # local flang install doesn't know the system gcc runtime path
    LINK_OPTS := -L/usr/lib/gcc/x86_64-mageia-linux/12
else ifdef lfortran
    ODIR  := obj_lfortran$(OBJ_DIR_SUFF)
    CC    := gcc
    FC    := lfortran
    RE_COPTS := -I re_engine -I utf8proc -DUTF8PROC_STATIC -fPIC
    COPTS    := $(RE_COPTS) -Wall
    FOPTS    := --cpp -J $(ODIR) -I$(ODIR)
    ifdef release
        RE_COPTS += -O2
        COPTS    += -O2
        FOPTS    += -O2
    else
        RE_COPTS += -g
        COPTS    += -g
        FOPTS    += -g --array-bounds-checking
    endif
    # lfortran invokes clang as linker; point it at system gcc runtime
    LINK_OPTS := -L/usr/lib/gcc/x86_64-mageia-linux/12
else
    ODIR  := obj_gfortran$(OBJ_DIR_SUFF)
    CC    := gcc
    FC    := gfortran
    RE_COPTS := -I re_engine -I utf8proc -DUTF8PROC_STATIC
    COPTS    := $(RE_COPTS) -Wall
    FOPTS    := -fPIC -cpp -std=f2018 -fimplicit-none -ffree-line-length-200 -Wall -Wextra -J$(ODIR) -I$(ODIR)
    ifdef release
        RE_COPTS += -O2
        COPTS    += -O2
        FOPTS    += -O3
    else
        RE_COPTS += -g
        COPTS    += -g
        FOPTS    += -D_DEBUG -ggdb -fbounds-check -ffpe-trap=denormal,invalid
    endif
    LINK_OPTS :=
endif

# -----------------------------------------------------------------------
# Sources and objects
# -----------------------------------------------------------------------
RE_DIR  := re_engine
UTF_DIR := utf8proc

# RE engine: only these four need compiling; they #include the rest
# (regc_*.c, rege_*.c) via unity-build.
RE_SRCS  := $(RE_DIR)/regcomp.c $(RE_DIR)/regexec.c \
            $(RE_DIR)/regfree.c  $(RE_DIR)/regerror.c

# utf8proc_data.c is #included by utf8proc.c — not compiled separately.
UTF_SRCS := $(UTF_DIR)/utf8proc.c

RE_OBJS  := $(addprefix $(ODIR)/, $(notdir $(RE_SRCS:.c=.o)))
UTF_OBJS := $(addprefix $(ODIR)/, $(notdir $(UTF_SRCS:.c=.o)))
C_OBJS   := $(RE_OBJS) $(UTF_OBJS) $(ODIR)/tclInterface.o
F_OBJ    := $(ODIR)/tcl_frx.o
F_SM_OBJ := $(ODIR)/tcl_frx_sm.o
LIB      := $(ODIR)/libtclInterface.a

# -----------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------
EXE      := $(ODIR)/re_utest_f
EXAMPLE  := $(ODIR)/example

all: $(ODIR) $(EXE)

$(EXE): re_utest.f90 $(LIB)
	$(FC) $(FOPTS) -o $@ re_utest.f90 $(LIB) $(LINK_OPTS) -lpthread -lm -ldl
	@echo "$@ created"

$(EXAMPLE): example.f90 $(LIB)
	$(FC) $(FOPTS) -o $@ example.f90 $(LIB) $(LINK_OPTS) -lpthread -lm -ldl
	@echo "$@ created"

$(LIB): $(C_OBJS) $(F_OBJ) $(F_SM_OBJ)
	ar rcv $@ $^

$(F_OBJ): tcl_frx.f90 | $(ODIR)
	$(FC) $(FOPTS) -c $< -o $@

$(F_SM_OBJ): tcl_frx_sm.f90 $(F_OBJ)
	$(FC) $(FOPTS) -c $< -o $@

$(ODIR)/tclInterface.o: tclInterface.c | $(ODIR)
	$(CC) $(COPTS) -c -o $@ $<

$(RE_OBJS): $(ODIR)/%.o: $(RE_DIR)/%.c | $(ODIR)
	$(CC) $(RE_COPTS) -c -o $@ $<

$(UTF_OBJS): $(ODIR)/%.o: $(UTF_DIR)/%.c | $(ODIR)
	$(CC) $(RE_COPTS) -c -o $@ $<

$(ODIR):
	mkdir -p $(ODIR)

clean:
	@$(RM) -vr $(ODIR)

veryclean: clean
	@$(RM) -rvf obj_*

help:
	@echo "Usage:  make [intel=t] [flang=t] [lfortran=t] [release=t]"
	@echo "ODIR      = $(ODIR)"
	@echo "CC        = $(CC)   COPTS = $(COPTS)"
	@echo "FC        = $(FC)   FOPTS = $(FOPTS)"
	@echo "LIB       = $(LIB)"
