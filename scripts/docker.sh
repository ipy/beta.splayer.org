#!/bin/bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
  READLINK=greadlink
else
  READLINK=readlink
fi
DIR=$(dirname $(dirname $($READLINK -f $0)))
if [ -z $DIR ]; then exit 1; fi;

docker login -u=qianzhi2019 -p=$DOCKER_PASSWORD registry.ap-northeast-1.aliyuncs.com
docker build -t registry.ap-northeast-1.aliyuncs.com/splayerx/web-splayer-org-beta $DIR/dist
docker push registry.ap-northeast-1.aliyuncs.com/splayerx/web-splayer-org-beta
