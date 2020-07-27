#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  READLINK=greadlink
else
  READLINK=readlink
fi
DIR=$(dirname $(dirname $($READLINK -f $0)))
if [ -z $DIR ]; then exit 1; fi;

cd $DIR
npm install

rm -fr $DIR/dist
git clone --branch=gh-pages --depth=1 git@github.com:${TRAVIS_REPO_SLUG:=beta.splayer.org}.git $DIR/dist
if [ -z $DIR/dist ]; then exit 1; fi;

set -e
rm -fr $DIR/dist/*
cp -r $DIR/src/* $DIR/dist

openssl aes-256-cbc -K $encrypted_74f063b30305_key -iv $encrypted_74f063b30305_iv -in splayer-cdn-9cc583e96c06.json.enc -out splayer-cdn-9cc583e96c06.json -d
gcloud auth activate-service-account splayer-release-deployer@splayer-cdn.iam.gserviceaccount.com --key-file=splayer-cdn-9cc583e96c06.json

node $DIR/scripts/getUpdateInfo.js

set +e
cd $DIR/dist
if (git diff --quiet && git diff --staged --quiet); then
git add . -A
git commit -m "`date`"
git push
fi
