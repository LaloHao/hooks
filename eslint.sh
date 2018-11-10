#!/bin/bash

TEMPDIR=`mktemp -d`
COMMAND="eslint --color -c /git/.eslintrc.js"

echo "### eslint"

oldrev=$1
newrev=$2
refname=$3
NULL_COMMIT=$(printf '0%.0s' {1..40})

while read oldrev newrev refname; do
  if [[ "$newrev" = $NULL_COMMIT ]]; then
    # branch deleted
    continue;
  fi

  if [[ "$oldrev" = $NULL_COMMIT ]]; then
    # new branch created
    oldrev=HEAD
  fi

  # Get the file names, without directory, of the files that have been modified
  # between the new revision and the old revision
  files=`git diff --name-only ${oldrev}..${newrev}`

  # Get a list of all objects in the new revision
  objects=`git ls-tree --full-name -r ${newrev}`

  for file in $files; do
    # Search for the file name in the list of all objects
    object=`echo -e "${objects}" | egrep "(\s)${file}\$" | awk '{ print $3 }'`

    # If it's not present, then continue to the the next itteration
    if [ -z ${object} ]; then
      continue;
    fi

    # Otherwise, create all the necessary sub directories in the new temp directory
    mkdir -p "${TEMPDIR}/`dirname ${file}`" &>/dev/null
    # and output the object content into it's original file name
    git cat-file blob ${object} > ${TEMPDIR}/${file}
  done
done

# lint js files
files_found=`find ${TEMPDIR} -name '*.js' | xargs echo -n`
resulting_status=0

if [ ${#files_found} -ne 0 ]; then
  results=`eval "$COMMAND $files_found"`
  resulting_status=$?
  if [ -z "$results" ]; then
    echo "passed"
  else
    echo "$results" | sed "s/${TEMPDIR//\//\\/}\///"
  fi
fi

rm -rf ${TEMPDIR} &> /dev/null

exit $resulting_status
