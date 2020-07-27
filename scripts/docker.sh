#!/bin/bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
  READLINK=greadlink
else
  READLINK=readlink
fi
DIR=$(dirname $(dirname $($READLINK -f $0)))
if [ -z $DIR ]; then exit 1; fi;

echo $DOCKER_PASSWORD | docker login -u=qianzhi2019 --password-stdin registry.ap-northeast-1.aliyuncs.com
docker build -f Dockerfile -t registry.ap-northeast-1.aliyuncs.com/splayerx/web-splayer-org-beta $DIR/dist
docker push registry.ap-northeast-1.aliyuncs.com/splayerx/web-splayer-org-beta
