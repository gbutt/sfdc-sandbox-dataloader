#!/bin/bash
trap "exit;" SIGINT SIGTERM

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

function runDataLoader {
	PHASE=$1
	java -cp ../lib/dataloader-38.0.1-uber.jar -Dsalesforce.config.dir=conf/$PHASE com.salesforce.dataloader.process.ProcessRunner process.name=$PHASE | grep --line-buffered -v 'Reading log-conf.xml in' | cat
}

function replaceFilters {
	# convert filter.txt into a list of comma-separated, single-quoted values
	FILTERS=`sed "s/^/'/" ../filter.txt | sed "s/$/',/" | sed '$ s/.$//' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
	# rewrite process-conf.xml with filter values
	sed -i '' "s/REPLACE_ME/$FILTERS/g" conf/extract/process-conf.xml
}

ETL_NAME=$1

if [[ $2 = '' || $2 = 'extract' ]]; then
	EXTRACT=true
fi
if [[ $2 = '' || $2 = 'import' ]]; then
	IMPORT=true
fi

# run Dataloader passing in the process name 
pushd work > /dev/null

if [[ $EXTRACT ]]; then
	echo running $ETL_NAME extract

	mkdir -p csv
	cp ../conf/beans/$ETL_NAME.xml conf/extract/process-conf.xml
	replaceFilters
	runDataLoader 'extract'
fi

if [[ $IMPORT ]]; then
	echo running $ETL_NAME import

	mkdir -p maps
	cp ../conf/beans/$ETL_NAME.xml conf/import/process-conf.xml
	cp ../conf/maps/$ETL_NAME.sdl maps/
	runDataLoader 'import'
fi

popd > /dev/null

