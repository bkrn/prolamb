#! /usr/bin/env sh

cp -a /dist/. /var/task
zip -r /dist/bundle.zip .
zip -d /dist/bundle.zip  build.sh
