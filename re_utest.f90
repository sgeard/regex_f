program re_utest
  use tcl_frx
  implicit none

  logical :: ok
  character(len=12) :: pattern = '^a([0-9]+)b$'
  character(len=7)  :: text    = 'a34567b'

  ! --- Object interface ---
  obj_iface: block
    type(regex_t) :: rx1
    write(*,'(/a)') '=== Object interface ==='
    call rx1%compile(pattern)
    call rx1%apply(text)

    call check_result('Number of matches',1,rx1%n_matches())
    write(*,fmt='(a)',advance='no') 'Match values'//' ... '
    if (rx1%get_match(0) == text .and. rx1%get_match(1) == '34567') then
      write(*,fmt='(a)') 'passed'
    else
      write(*,fmt='(a)') 'FAILED'
    end if

    ! Object: case-insensitive flag (combine type + modifier)
    write(*,'(a)', advance='no') 'Case insensitive flag ... '
    call rx1%compile('[a-z]+', flags=ior(RE_ADVANCED, RE_ICASE))
    call rx1%apply('HELLO')
    ok = rx1%matched() ! Should match
    call rx1%apply('12345')
    ok = ok .and. .not. rx1%matched()
    call result_msg(ok)
    call rx1%delete
    write(*,fmt='(a)',advance='no') 'Handle release'//' ... '
    call result_msg(.not. rx1%is_compiled())
  end block obj_iface

  ! --- Functional interface ---
  fun_iface: block
    integer :: h, nmatches, i_start, i_end, r
    write(*,'(/a)') '=== Functional interface ==='
    call tcl_re_compile_f(pattern, h)
    nmatches = tcl_re_apply_f(h, text)
    call check_result('Number of matches',1,nmatches)

    write(*,fmt='(a)',advance='no') 'Match values'//' ... '
    r = tcl_re_get_match_indices_f(h, 0, i_start, i_end)
    if (r == -1) then
      stop '***Error: regex failure'
    end if
    ok = (i_start == 1) .and. (i_end == len(text))
    r = tcl_re_get_match_indices_f(h, 1, i_start, i_end)
    ok = ok .and. (i_start == 2) .and. (i_end == 6)
    call result_msg(ok)
    call tcl_re_delete_f(h)
    write(*,fmt='(a)',advance='no') 'Handle release'//' ... '
    call result_msg(h==-1)
  end block fun_iface

contains

  subroutine check_result(str, ref, actual)
    character(len=*), intent(in) :: str
    integer, intent(in) :: ref
    integer, intent(in) :: actual

    write(*,fmt='(a)',advance='no') str//' ... '
    call result_msg(actual == ref)
  end subroutine check_result

  subroutine result_msg(ok)
    logical, intent(in) :: ok
    if (ok) then
      write(*,'(a)') 'passed'
    else
      write(*,'(a)') 'FAILED'
    end if
  end subroutine result_msg
end program re_utest
