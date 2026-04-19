#!/bin/bash

tmpdir=./tmp_gh
git clone git@github.com:sgeard/regex_f.git $tmpdir
svn export --force svn://persephone/projects/tcl_re $tmpdir
cd $tmpdir
git add -A
git commit -m "Sync from SVN r$(svnversion ..)"
git push

cd ..
rm -rf $tmpdir
