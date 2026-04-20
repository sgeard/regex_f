# tcl_frx
This is a Fortran wrapper around the regex engine in Tcl (written by Henry Spencer).
The full interface should be read from the code

```tcl_frx.f90``` 

which defines all the hooks provided including the flags.
Flags should be combined with IOR.
To avoid memory management work copying (assignment) is a runtime error.

# compilers
The following are known to work in release and debug builds:
* gfortran 15.2.0
* ifx 2025.2.1
* flang 23.0.0git
* lfortran 0.61.0

## Building
Currently only _make_ is supported, _all_ and _example_ are targets.

The directory structure is suitable for _fpm_ but currently it doesn't support excluding some files by name.

## Example
This is example.f90

```f90
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

    ! Compile the rx - this is essential. The string is passed to the internal engine
    ! where it is compiled and stored internally (accessible by a handle).
    call rx%compile(pat)

    ! Use the compiled rx on the given text. The same rx can be used for diffetent text,
    ! no need to recompile unless the rx pattern has changed.
    call rx%apply(line)

    ! Check for matches, whether there are ny and if so how many
    if (.not. rx%matched()) then
        stop '*** Match failed'
    end if
    if (rx%n_matches() /= 5) then
        stop '*** Incorrect match'
    end if

    ! Retrieve all the matches. 0 is a valid index and alwasy returns the whole input string
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
```
