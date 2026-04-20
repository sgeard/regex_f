submodule (tcl_frx) tcl_frx_sm
    implicit none

contains
! ----------------------------------------------------------------
    ! Object procedures
    ! ----------------------------------------------------------------

    module procedure assign_regex_t
        error stop 'regex_t: assignment is not supported'
    end procedure assign_regex_t

    module procedure close_regex_t
        call this%delete
    end procedure close_regex_t

    module procedure delete_regex_t
        call tcl_re_delete_f(this%h)
        this%h = -1
    end procedure delete_regex_t

    module procedure compile_regex_t
        integer :: f
        character(len=len_trim(pattern)+1, kind=c_char) :: cpattern
        f = RE_ADVANCED
        if (present(flags)) f = flags
        if (this%h >= 0) call tcl_re_delete_f(this%h)
        cpattern = trim(pattern) // c_null_char
        this%h = int(tcl_re_compile_c(cpattern, int(f, c_int)))
        if (this%h == -2) then
            write(*,'(a)') '***Syntax error in re: '//trim(pattern)
        else if (this%h == -1) then
            write(*,'(a)') '***Internal error: cache full'
        end if
    end procedure compile_regex_t

    module procedure apply_regex_t
        if (this%h >= 0) then
            this%txt = text
            this%mat = tcl_re_apply_f(this%h, text)
        end if
    end procedure apply_regex_t

    module procedure matched_regex_t
        integer(c_int) :: r
        if (this%h >= 0) then
            r = tcl_re_matched_c(int(this%h, c_int))
            res = (r == 1)
        else
            res = .false.
        end if
    end procedure matched_regex_t

    module procedure n_matches_regex_t
        res = this%mat
    end procedure n_matches_regex_t

    module procedure get_match_regex_t
        integer :: i_start, i_end, r
        if (this%h >= 0 .and. midx <= this%mat) then
            r = tcl_re_get_match_indices_f(this%h, midx, i_start, i_end)
            if (r == 1) res = this%txt(i_start:i_end)
        end if
    end procedure get_match_regex_t

    module procedure is_compiled_regex_t
        res = this%h >= 0
    end procedure is_compiled_regex_t

    module procedure match_regex_t
        call this%compile(pattern, flags)
        if (this%h < 0) then
            res = .false.
            return
        end if
        call this%apply(text)
        res = this%matched()
    end procedure match_regex_t

    ! ----------------------------------------------------------------
    ! Functional interface
    ! ----------------------------------------------------------------

    module procedure tcl_re_compile_f
        integer :: f
        character(len=len_trim(pattern)+1, kind=c_char) :: cpattern
        f = RE_ADVANCED
        if (present(flags)) f = flags
        cpattern = trim(pattern) // c_null_char
        h = int(tcl_re_compile_c(cpattern, int(f, c_int)))
    end procedure tcl_re_compile_f

    module procedure tcl_re_apply_f
        character(len=len_trim(text)+1, kind=c_char) :: ctext
        ctext = trim(text) // c_null_char
        n = int(tcl_re_apply_c(int(h, c_int), ctext))
    end procedure tcl_re_apply_f

    module procedure tcl_re_get_match_indices_f
        integer(c_int) :: cs, ce, rc
        rc = tcl_re_get_match_indices_c(int(h,c_int), int(idx,c_int), cs, ce)
        if (rc == 1) then
            i_start = int(cs) + 1   ! C: 0-based  ->  Fortran: 1-based
            i_end   = int(ce)       ! C: exclusive ->  Fortran: inclusive
        else
            i_start = 0
            i_end   = -1
        end if
        r = int(rc)
    end procedure tcl_re_get_match_indices_f

    module procedure tcl_re_match_f
        integer :: f
        character(len=len_trim(pattern)+1, kind=c_char) :: cpat
        character(len=len_trim(text)+1,    kind=c_char) :: ctxt
        f = RE_ADVANCED
        if (present(flags)) f = flags
        cpat = trim(pattern) // c_null_char
        ctxt = trim(text)    // c_null_char
        r = int(tcl_re_match_c(cpat, ctxt, int(f, c_int)))
    end procedure tcl_re_match_f

    module procedure tcl_re_delete_f
        integer(c_int) :: ch, rc
        ch = int(h, c_int)
        rc = tcl_re_delete_c(ch)
        h  = int(ch)
    end procedure tcl_re_delete_f

end submodule tcl_frx_sm
