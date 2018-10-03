#!/bin/bash

# Note: you can pass 'extract' or 'import' to this script

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

./preLoad.sh

./runEtlSet.sh etls/sales_data.txt $1

./postLoad.sh