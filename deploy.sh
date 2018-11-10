#!/bin/bash

BUILD_DIR="/build"
REPO="doproyect/web"
SITE="staging.doproyect.com"
DIR="$BUILD_DIR/$REPO"

cd $DIR
unset GIT_DIR

while read local_ref local_sha remote_ref remote_sha
do
  if [ "$remote_ref" = "refs/heads/master" ]; then
    echo "You cannot push to master!"
    exit 1
  fi
  if [ "$remote_ref" = "refs/heads/develop" ];
  then
    rm -f /tmp/build.log
    echo "### deploy"
    echo "fetching code"
    git checkout develop -f &>> /tmp/build.log
    git pull &>> /tmp/build.log
    echo "updating packages"
    yarn >> /tmp/build.log
    echo "building"
    yarn build >> /tmp/build.log
    echo "uploading"
    rm -rf /srv/http/$SITE/* >> /tmp/build.log
    cp -r build/* /srv/http/$SITE/ >> /tmp/build.log
    echo "done"
  fi
done
