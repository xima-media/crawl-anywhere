#!/bin/sh
#
# Crawl-Anywhere
#
# Author: Sebastian Gierh <sgi@xima.de>
#
# Core switch script
#

# Get the path of crawl anywhere root directory
HOME=/opt/crawler
SCRIPTS=$HOME/scripts

# Init Variables
. $SCRIPTS/init.inc.sh

usage() {
	echo "Usage : $SCRIPTS/switchCore.sh {CoresDirectory}"
}

if [ $# -lt 1 ]; then
	usage
	exit 0
fi

getPID() {
	if [ -e "$1" ]; then
		cat $1
		return 0
	fi
	return 1
}

PID_INDEXER=$(getPID "$LOG_DIR/indexer.pid")
PID_PIPELINE=$(getPID "$LOG_DIR/pipeline.pid")

result=

# Get next directory by current dirname
# $1 dir to work in
# $2 dirname inside $1
nextDir() {
	local curDir=0
	local firstDir=

	for x in $1*/; do
		if [ -z $firstDir ]; then
			firstDir=$x
		fi
		if [ -d $x ]; then
			if [ $curDir -eq 1 ]; then
				result=$x
				return 0
			fi
			if [ "$x" = "$1$2/" ]; then
				curDir=1
			fi
		fi
	done

	result=$firstDir
	return 0
}

# stop/start indexer and pipeline with core configuration
# $1 path to core
# $2 path to scripts
handleScript() {
	if [ -z $1 ]; then
		echo "Missing core!"
		return 1
	fi

	# pipeline
	sh "$2/pipeline.sh" stop &> /dev/null
	sleep 10
	sh "$2/pipeline.sh" start "$1config/pipeline/simplepipeline.xml" &> /dev/null
	sleep 5
	sh "$2/pipeline.sh" status

	# indexer
	sh "$2/indexer.sh" stop &> /dev/null
	sleep 10
	sh "$2/indexer.sh" start "$1config/indexer/indexer.xml" &> /dev/null
	sleep 5
	sh "$2/indexer.sh" status

	return 0
}

### Main ###

[ -n $PID_PIPELINE ] && PID=$PID_PIPELINE || PID=$PID_INDEXER

# get current running core
currentCore=
if [ -n $PID ]; then
	currentCore="$( ps -o args $PID | grep -oP '(?<=\s-p\s)\S*' | grep -oP "(?<=$1)[^/]+" )"
fi
if [ -z $currentCore ]; then
	currentCore="$1./"
fi

# get next core
nextDir "$1" "$currentCore"

ignoredDirs="-I_error -I_success"
pipelinerQueue="pipeline_queue"
indexerQueue="indexer_queue"

while [ ! "$(ls -A $ignoredDirs $result$pipelinerQueue)" ] && [ ! "$(ls -A $ignoredDirs $result$indexerQueue)" ]; do
	nextCore="$( echo $result | grep -oP "(?<=$1)[^/]+" )"
	nextDir "$1" "$nextCore"
done

nextCore="$( echo $result | grep -oP "(?<=$1)[^/]+" )"

# try switch
if [ $currentCore != $nextCore ]; then
	echo "Trying to switch core from '$currentCore' to '$nextCore'"
	handleScript "$1$nextCore/" "$SCRIPTS"
else
	echo "Stay on core '$currentCore' because no other core has got documents"
fi

exit 0;
