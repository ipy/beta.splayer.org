#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  READLINK=greadlink
else
  READLINK=readlink
fi
DIR=$(dirname $(dirname $($READLINK -f $0)))
if [ -z $DIR ]; then exit 1; fi;
rm -fr $DIR/dist
git clone --branch=gh-pages --depth=1 git@github.com:${TRAVIS_REPO_SLUG:=beta.splayer.org}.git $DIR/dist
if [ -z $DIR/dist ]; then exit 1; fi;
rm -fr $DIR/dist/*
cp -r $DIR/src/* $DIR/dist
VERSION=`curl -is "https://github.com/chiflix/splayerx/releases/latest" | grep -E '^Location: ' | grep -oE "([0-9]+.)+[0-9]"`
echo "The latest version is: $VERSION"

openssl aes-256-cbc -K $encrypted_74f063b30305_key -iv $encrypted_74f063b30305_iv -in splayer-cdn-9cc583e96c06.json.enc -out splayer-cdn-9cc583e96c06.json -d
gcloud auth activate-service-account splayer-release-deployer@splayer-cdn.iam.gserviceaccount.com --key-file=splayer-cdn-9cc583e96c06.json
DOWNLOAD_URL_DMG="https://github.com/chiflix/splayerx/releases/download/$VERSION/SPlayer-$VERSION.dmg"
DOWNLOAD_URL_EXE="https://github.com/chiflix/splayerx/releases/download/$VERSION/SPlayer-Setup-$VERSION.exe"
curl -L "$DOWNLOAD_URL_DMG" | gsutil cp - gs://splayer-releases/download/SPlayer-$VERSION.dmg
curl -L "$DOWNLOAD_URL_EXE" | gsutil cp - gs://splayer-releases/download/SPlayer-Setup-$VERSION.exe

cat $DIR/src/index.html | sed "s/{{version}}/$VERSION/g" > $DIR/dist/index.html

cd $DIR/dist
git add -A
git commit -m "`date`"
git push
