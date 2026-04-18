! Example: extract subgroups from a simple fraction arithmetic expression
program example

    use tcl_frx
    implicit none

    type(regex_t) :: rx
    character(*), parameter :: line = '1/2 + 3/7'
    character(*), parameter :: pat  = '^(\d+)/(\d+) *([+\-]) *(\d+)/(\d+)$'
    integer :: num, denom, i, j
    integer :: numbers(4)
    character(len=1)  :: op
    character(len=:), allocatable :: str

    call rx%compile(pat)
    call rx%apply(line)

    if (.not. rx%matched()) then
        stop '*** Match failed'
    end if
    if (rx%n_matches() /= 5) then
        stop '*** Incorrect match'
    end if

    j = 1
    do i=1,rx%n_matches()
        str = rx%get_match(i)
        if (i == 3) then
            op = str
        else
            read(str,*) numbers(j)
            j = j+1
        end if
    end do

    associate (a=>numbers(1), b=>numbers(2), c=>numbers(3), d=>numbers(4))
        if (op == '+') then
            num = a*d + c*b
        else
            num = a*d - c*b
        end if
        denom = b*d
        write(*,'(5(i0,a),i0)') a, '/', b, '  '//op//'  ', c, '/', d, ' = ', num, '/', denom
    end associate

end program example
