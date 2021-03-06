#! /usr/bin/env sh

set -e

cp -a /dist/. /var/task
if [ "${STATIC_MODULE}" != "" ]; then
    touch STATIC_MODULE
    ./lib/swipl/bin/x86_64-linux/swipl --goal=prolamb_go --toplevel=halt --stand_alone=true --foreign=save -o bootstrap -c prolamb ${STATIC_MODULE} 
    zip -9 -r /dist/${BUNDLE_NAME} bootstrap STATIC_MODULE lib/snowflake lib/lib* lib/psql* lib/swipl/lib/x86_64-linux
else
    zip -9 -r /dist/${BUNDLE_NAME} .
    zip -9 -d /dist/${BUNDLE_NAME} build.sh
fi
