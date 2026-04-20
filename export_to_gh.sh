#!/bin/bash

tmpdir=./tmp_gh
git clone git@github.com:sgeard/regex_f.git $tmpdir

# Clear tracked files so moves/deletions in SVN propagate. svn export --force
# overwrites existing files but does not remove files missing from the export,
# so without this step 'git add -A' would not see stale paths as deleted.
( cd $tmpdir && git ls-files -z | xargs -0 rm -f )

svn export --force svn://persephone/projects/tcl_re $tmpdir
cd $tmpdir
git add -A

if [[ $# == 1 ]]; then
    comment=$1
else
    default_comment="Sync from SVN r$(svnversion ..)"
    read -p "Comment [$default_comment] > " comment
    comment=${comment:-$default_comment}
fi
git commit -m "$comment"
git push

cd ..
rm -rf $tmpdir
