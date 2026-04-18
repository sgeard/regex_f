#!/bin/bash

tmpdir=./tmp_gh
git clone https://github.com/sgeard/regex_f.git $tmpdir
svn export --force svn://persephone/projects/tcl_re $tmpdir
cd $tmpdir
git add .
git commit -m "Initial commit: Fortran interface to Tcl ARE regex engine"
git push

rm -rf $tmpdir
exit 0
