# tcl_frx
This is a Fortran wrapper around the regex engine in Tcl (written by Henry Spencer).
The full interface should be read from the code

```tcl_frx.f90``` 

which defines all the hooks provided including the flags.
Flags should be combined with IOR.
To avoid memory management work copying (assignment) is a runtime error.

## Example
See example.f90 for usage.
