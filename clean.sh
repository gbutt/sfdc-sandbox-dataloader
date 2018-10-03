#!/bin/bash

trap "exit;" SIGINT SIGTERM

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

# copy files to a tmp folder to preserve them
mkdir -p tmp/conf/import
mkdir -p tmp/conf/extract
cp work/key.txt tmp
cp work/conf/extract/config.properties tmp/conf/extract
cp work/conf/import/config.properties tmp/conf/import
cp conf/log-conf.xml tmp

# remove work folder and rename tmp to work
rm -rf work
mv tmp work