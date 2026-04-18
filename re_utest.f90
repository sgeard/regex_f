program re_utest
  use reInterface
  implicit none

  type(regex_t) :: rx1
  integer :: h, nmatches, i, i_start, i_end, r

  character(len=12) :: pattern = '^a([0-9]+)b$'
  character(len=7)  :: text    = 'a34567b'

  ! --- Object interface ---
  print *, '=== Object interface ==='
  call rx1%compile(pattern)
  call rx1%apply(text)
  print *, 'matched =', rx1%matched(), '  n_matches =', rx1%n_matches()
  do i = 0, rx1%n_matches()
    print '(a,i0,a,a,a)', '  match(', i, ') = "', rx1%get_match(i), '"'
  end do

  ! Object: case-insensitive flag (combine type + modifier)
  print *, '--- RE_ICASE test ---'
  call rx1%compile('[a-z]+', flags=ior(RE_ADVANCED, RE_ICASE))
  call rx1%apply('HELLO')
  print *, '"HELLO" ~ [a-z]+ icase: matched =', rx1%matched()
  call rx1%apply('12345')
  print *, '"12345" ~ [a-z]+ icase: matched =', rx1%matched()
  call rx1%delete

  ! --- Functional interface ---
  print *, '=== Functional interface ==='
  call tcl_re_compile_f(pattern, h)
  if (h < 0) then
    print *, 'ERROR: compile failed, h =', h
    stop 1
  end if
  print *, 'Compiled "', trim(pattern), '", handle =', h

  nmatches = tcl_re_apply_f(h, text)
  print *, 'Applied to "', trim(text), '", subexpressions =', nmatches
  do i = 0, nmatches
    r = tcl_re_get_match_indices_f(h, i, i_start, i_end)
    if (r == 1) then
      if (i == 0) then
        print *, '  whole match   : "', text(i_start:i_end), '"'
      else
        print '(a,i0,a,a,a)', '  subexpression ', i, ': "', &
            text(i_start:i_end), '"'
      end if
    end if
  end do

  ! One-shot tests
  print *, '--- One-shot tests ---'
  print *, '"', trim(text), '" ~ "', trim(pattern), '":', &
      tcl_re_match_f(pattern, text) == 1
  print *, '"hello" ~ "', trim(pattern), '":', &
      tcl_re_match_f(pattern, 'hello') == 1
  print *, '"HELLO" ~ [a-z]+ icase:', &
      tcl_re_match_f('[a-z]+', 'HELLO', flags=ior(RE_ADVANCED, RE_ICASE)) == 1

  call tcl_re_delete_f(h)
  print *, 'Handle released, h =', h

end program re_utest
