#!/bin/bash
# trap "exit;" SIGINT SIGTERM

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

if [[ $2 = '' || $2 = 'extract' ]]; then
	EXTRACT=true
fi
if [[ $2 = '' || $2 = 'import' ]]; then
	IMPORT=true
fi

ETLs=()
file=$1
while read line || [ -n "$line" ]; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ "$line" = "" ]] && continue
    ETLs+=($line)
done < "$file"

if [[ $EXTRACT ]]; then
    for etl in "${ETLs[@]}"; do
        ./runEtl.sh $etl extract
    done
fi

if [[ $IMPORT ]]; then
    for etl in "${ETLs[@]}"; do
        ./runEtl.sh $etl import
    done
fi