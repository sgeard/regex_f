program re_utest
  use tcl_frx
  implicit none

  logical :: any_failed = .false.
  character(len=12) :: pattern = '^a([0-9]+)b$'
  character(len=7)  :: text    = 'a34567b'

  ! --- Object interface ---
  obj_iface: block
    type(regex_t) :: rx1
    logical :: ok
    write(*,'(/a)') '=== Object interface ==='
    call rx1%compile(pattern)
    call rx1%apply(text)

    call check_result('Number of matches', 1, rx1%n_matches())
    write(*,fmt='(a)',advance='no') 'Match values'//' ... '
    call result_msg(rx1%get_match(0) == text .and. rx1%get_match(1) == '34567')

    ! Case-insensitive flag (combine type + modifier)
    write(*,fmt='(a)',advance='no') 'Case insensitive flag ... '
    call rx1%compile('[a-z]+', flags=ior(RE_ADVANCED, RE_ICASE))
    call rx1%apply('HELLO')
    ok = rx1%matched()                                         ! should match
    call rx1%apply('12345')
    ok = ok .and. .not. rx1%matched()                          ! shouldn't
    call result_msg(ok)
    call rx1%delete
    write(*,fmt='(a)',advance='no') 'Handle release'//' ... '
    call result_msg(.not. rx1%is_compiled())

    ! One-shot object method
    write(*,fmt='(a)',advance='no') 'One-shot match (positive) ... '
    call result_msg(rx1%match(pattern, text))
    write(*,fmt='(a)',advance='no') 'One-shot leaves state ... '
    call result_msg(rx1%is_compiled() .and. rx1%get_match(1) == '34567')
    write(*,fmt='(a)',advance='no') 'One-shot match (negative) ... '
    call result_msg(.not. rx1%match(pattern, 'hello'))
    write(*,fmt='(a)',advance='no') 'One-shot match (ICASE) ... '
    call result_msg(rx1%match('[a-z]+', 'HELLO', flags=ior(RE_ADVANCED, RE_ICASE)))
  end block obj_iface

  ! --- Functional interface ---
  fun_iface: block
    integer :: h, nmatches, i_start, i_end, r
    logical :: ok
    write(*,'(/a)') '=== Functional interface ==='
    call tcl_re_compile_f(pattern, h)
    nmatches = tcl_re_apply_f(h, text)
    call check_result('Number of matches', 1, nmatches)

    write(*,fmt='(a)',advance='no') 'Match values'//' ... '
    r = tcl_re_get_match_indices_f(h, 0, i_start, i_end)
    if (r == -1) stop '***Error: regex failure'
    ok = (i_start == 1) .and. (i_end == len(text))
    r = tcl_re_get_match_indices_f(h, 1, i_start, i_end)
    ok = ok .and. (text(i_start:i_end) == '34567')
    call result_msg(ok)
    call tcl_re_delete_f(h)
    write(*,fmt='(a)',advance='no') 'Handle release'//' ... '
    call result_msg(h == -1)

    ! One-shot functional
    write(*,fmt='(a)',advance='no') 'One-shot match (positive) ... '
    call result_msg(tcl_re_match_f(pattern, text) == 1)
    write(*,fmt='(a)',advance='no') 'One-shot match (negative) ... '
    call result_msg(tcl_re_match_f(pattern, 'hello') == 0)
    write(*,fmt='(a)',advance='no') 'One-shot match (ICASE) ... '
    call result_msg(tcl_re_match_f('[a-z]+', 'HELLO', flags=ior(RE_ADVANCED, RE_ICASE)) == 1)
  end block fun_iface

  if (any_failed) then
    write(*,'(/a)') '*** One or more tests FAILED'
    stop 1
  else
    write(*,'(/a)') 'All tests passed'
  end if

contains

  subroutine check_result(str, ref, actual)
    character(len=*), intent(in) :: str
    integer, intent(in) :: ref, actual

    write(*,fmt='(a)',advance='no') str//' ... '
    call result_msg(actual == ref)
  end subroutine check_result

  subroutine result_msg(ok)
    logical, intent(in) :: ok
    if (ok) then
      write(*,'(a)') 'passed'
    else
      write(*,'(a)') 'FAILED'
      any_failed = .true.
    end if
  end subroutine result_msg
end program re_utest
