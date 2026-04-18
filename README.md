# tcl_frx
This is a Fortran wrapper around the regex engine in Tcl (written by Henry Spencer).
The full interface should be read from the code

```tcl_frx.f90``` 

which defines all the hooks provided including the flags.
Flags should be combined with IOR.

## Example
See example.f90 for usage.
