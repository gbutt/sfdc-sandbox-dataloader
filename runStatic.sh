#!/bin/bash
trap "exit;" SIGINT SIGTERM

ETL_NAME=$1

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

mkdir -p work/csv

cp conf/static/$ETL_NAME.csv work/csv/

./runEtl.sh $ETL_NAME import