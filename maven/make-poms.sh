#!/bin/sh

if [ $# -ne 1 ]
then
  echo "make-poms: usage: version" 1>&2
  exit 1
fi

VERSION="$1"
shift

PROJECTS=`./make-list-projects.sh | awk -F: '{print $1}'` || exit 1

for PROJECT in ${PROJECTS}
do
  echo "make-poms: info: generating pom for ${PROJECT}" 1>&2 
  "./${PROJECT}.pom.sh" "${VERSION}" > "output/${PROJECT}.pom.tmp" || exit 1
  mv "output/${PROJECT}.pom.tmp" "output/${PROJECT}.pom" || exit 1
done

