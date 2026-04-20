!
! tcl_frx -- Modern Fortran interface to the Tcl ARE regex engine.
!
! The C layer (tclInterface.c) works with 0-based, exclusive-end byte
! offsets.  The Fortran wrappers convert to 1-based inclusive indices so
! that standard Fortran substring syntax (str(i_start:i_end)) works
! directly.
!
! Written by Claude 4.6, reviewed and approved by S Geard, 10/04/2026

module tcl_frx
    use iso_c_binding, only: c_int, c_char, c_null_char
    implicit none
    private

    ! ----------------------------------------------------------------
    ! Regex flags -- may be combined with ior().
    ! Values match the TCL_RE_* constants in tclInterface.h.
    ! ----------------------------------------------------------------
    integer, parameter, public :: RE_BASIC    = 0    ! Basic (BRE)
    integer, parameter, public :: RE_EXTENDED = 1    ! Extended (ERE)
    integer, parameter, public :: RE_ADVANCED = 3    ! Advanced ARE (default)
    integer, parameter, public :: RE_ICASE    = 8    ! Case-insensitive
    integer, parameter, public :: RE_NOSUB    = 16   ! Suppress subexpression reporting
    integer, parameter, public :: RE_EXPANDED = 32   ! Whitespace/# comments ignored
    integer, parameter, public :: RE_NEWLINE  = 192  ! Newlines as line terminators

    ! ----------------------------------------------------------------
    ! Object interface
    ! ----------------------------------------------------------------
    type, public :: regex_t
        integer, private :: h   = -1   ! -1 = not compiled; >= 0 valid handle
        integer, private :: mat = 0
        character(len=:), allocatable, private :: txt
    contains
        procedure, public :: compile     => compile_regex_t
        procedure, public :: apply       => apply_regex_t
        procedure, public :: matched     => matched_regex_t   ! .true. if last apply succeeded
        procedure, public :: n_matches   => n_matches_regex_t
        procedure, public :: get_match   => get_match_regex_t
        procedure, public :: delete      => delete_regex_t
        procedure, public :: is_compiled => is_compiled_regex_t
        procedure         :: assign_regex_t
        generic           :: assignment(=) => assign_regex_t
        final             :: close_regex_t
    end type regex_t

    ! ----------------------------------------------------------------
    ! Raw C bindings (private)
    ! ----------------------------------------------------------------
    interface
        function tcl_re_compile_c(pattern, flags) result(h) &
            bind(c, name='tcl_re_compile')
          import :: c_char, c_int
          character(kind=c_char), intent(in) :: pattern(*)
          integer(c_int), value, intent(in)  :: flags
          integer(c_int) :: h
        end function

        function tcl_re_apply_c(h, text) result(n) &
            bind(c, name='tcl_re_apply')
          import :: c_int, c_char
          integer(c_int), value, intent(in) :: h
          character(kind=c_char), intent(in) :: text(*)
          integer(c_int) :: n
        end function

        function tcl_re_get_match_indices_c(h, idx, i_start, i_end) result(r) &
            bind(c, name='tcl_re_get_match_indices')
          import :: c_int
          integer(c_int), value, intent(in)  :: h, idx
          integer(c_int),        intent(out) :: i_start, i_end
          integer(c_int) :: r
        end function

        function tcl_re_match_c(pattern, text, flags) result(r) &
            bind(c, name='tcl_re_match')
          import :: c_int, c_char
          character(kind=c_char), intent(in) :: pattern(*), text(*)
          integer(c_int), value, intent(in)  :: flags
          integer(c_int) :: r
        end function

        function tcl_re_matched_c(h) result(r) &
            bind(c, name='tcl_re_matched')
          import :: c_int
          integer(c_int), value, intent(in) :: h
          integer(c_int) :: r
        end function

        function tcl_re_delete_c(h) result(r) &
            bind(c, name='tcl_re_delete')
          import :: c_int
          integer(c_int), intent(inout) :: h
          integer(c_int) :: r
        end function

        subroutine tcl_re_reset_c() bind(c, name='tcl_re_reset')
        end subroutine
    end interface

    ! ----------------------------------------------------------------
    ! Module procedure declarations (implementation in tcl_frx_sm.f90)
    ! ----------------------------------------------------------------
    interface
        module subroutine assign_regex_t(lhs, rhs)
            class(regex_t), intent(out) :: lhs
            class(regex_t), intent(in)  :: rhs
        end subroutine

        module subroutine close_regex_t(this)
            type(regex_t), intent(inout) :: this
        end subroutine

        module subroutine delete_regex_t(this)
            class(regex_t), intent(inout) :: this
        end subroutine

        module subroutine compile_regex_t(this, pattern, flags)
            class(regex_t),    intent(inout) :: this
            character(len=*),  intent(in)    :: pattern
            integer, optional, intent(in)    :: flags
        end subroutine

        module subroutine apply_regex_t(this, text)
            class(regex_t),   intent(inout) :: this
            character(len=*), intent(in)    :: text
        end subroutine

        logical module function matched_regex_t(this) result(res)
            class(regex_t), intent(in) :: this
        end function

        integer module function n_matches_regex_t(this) result(res)
            class(regex_t), intent(in) :: this
        end function

        module function get_match_regex_t(this, midx) result(res)
            class(regex_t), intent(in) :: this
            integer,        intent(in) :: midx
            character(len=:), allocatable :: res
        end function

        module function is_compiled_regex_t(this) result(res)
            class(regex_t), intent(in) :: this
            logical :: res
        end function is_compiled_regex_t

        module subroutine tcl_re_compile_f(pattern, h, flags)
            character(len=*),  intent(in)  :: pattern
            integer,           intent(out) :: h
            integer, optional, intent(in)  :: flags
        end subroutine

        integer module function tcl_re_apply_f(h, text) result(n)
            integer,          intent(in) :: h
            character(len=*), intent(in) :: text
        end function

        integer module function tcl_re_get_match_indices_f(h, idx, i_start, i_end) result(r)
            integer, intent(in)  :: h, idx
            integer, intent(out) :: i_start, i_end
        end function

        integer module function tcl_re_match_f(pattern, text, flags) result(r)
            character(len=*),  intent(in) :: pattern, text
            integer, optional, intent(in) :: flags
        end function

        module subroutine tcl_re_delete_f(h)
            integer, intent(inout) :: h
        end subroutine
    end interface

    public :: tcl_re_compile_f
    public :: tcl_re_apply_f
    public :: tcl_re_get_match_indices_f
    public :: tcl_re_match_f
    public :: tcl_re_delete_f
    public :: tcl_re_reset_c

end module tcl_frx
