#!/bin/sh
#
# Crawl-Anywhere
#
# Author: Sebastian Gierh <sgi@xima.de>
#
# Create a new core
#

# Crawl-Anywhere (CA) - Variables
CA_HOME=/opt/crawler
CA_SCRIPTS=$CA_HOME/scripts
CA_CORES_DIR=$CA_HOME/cores

# Solr - Variables
SOLR_HOME=/opt/solr
SOLR_CORES_DIR=$SOLR_HOME/server/solr

# usage information
usage() {
	echo "Usage : $CA_SCRIPTS/createCore.sh {CoreName}"
}

# replaces placeholders in given file
renderTemplate() {
	eval "echo \"$(cat $1)\""
}

###
# Crawl-Anywhere target/core
###

# create cores directory if its not exists
if [ ! -d $CA_CORES_DIR ]
	then
		mkdir $CA_CORES_DIR
fi

# abort if not enough arguments
if [ $# -lt 1 ]
	then
		usage
		exit 1;
fi

# create directory of new core if its not exists yet
newCore="$CA_CORES_DIR/$1"
if [ -d $newCore ]
	then
		echo "ABORT: Crawl-Anywhere target '$newCore' already exists!\n"
		exit 2;
fi

mkdir $newCore
cd $newCore
mkdir config
mkdir pipeline_queue
mkdir indexer_queue

###
# Configuration
###

cd config
ln -s $CA_HOME/config/crawler crawler
ln -s $CA_HOME/config/profiles profiles
ln -s $CA_HOME/config/profiles.sm profiles.sm

# Pipeline config
mkdir pipeline
cd pipeline
ln -s $CA_HOME/config/pipeline/* .
rm solrmapping.xml
cp $CA_HOME/config/pipeline/solrmapping.xml .
rm simplepipeline.xml

# Variables for simplepipeline.xml.tmpl
logfilename="$newCore/log/pipeline.log"
rootdir="$newCore/pipeline_queue"
onsuccessmoveto="$newCore/pipeline_queue/_success/{//source_id}"
onerrormoveto="$newCore/pipeline_queue/_error/{//source_id}"
mappingdefinitionfile="$newCore/config/pipeline/contenttypemapping.txt"
scriptspath="$newCore/config/pipeline/scripts"
ngp="$newCore/config/profiles"
queuedir="$newCore/indexer_queue"
solrmappings="$newCore/config/pipeline/solrmapping.xml"
solrboosts="$newCore/config/pipeline/solrboost.xml"

renderTemplate simplepipeline.xml.tmpl > simplepipeline.xml
rm simplepipeline.xml.tmpl

# Indexer config
cd config
mkdir indexer
cd indexer
ln -s $CA_HOME/config/indexer/* .
rm indexer.xml

# Variables for indexer.xml.tmpl
corename="$1"
logfilename="$newCore/log/indexer.log"
queuepath="$newCore/indexer_queue"
onsuccessmoveto="$newCore/indexer_queue/_success"
onerrormoveto="$newCore/indexer_queue/_error"

renderTemplate indexer.xml.tmpl > indexer.xml
rm indexer.xml.tmpl

###
# Solr core
###

cd $SOLR_HOME

# create directory of new core if its not exists yet
newCore="$SOLR_CORES_DIR/$1"
if [ -d $newCore ]
	then
		echo "ABORT: Solr core '$newCore' already exists!\n"
		exit 3;
fi

# configuration progress
mkdir $newCore
cp -r $CA_HOME/install/solr/solr-4.10.0/conf $newCore/.
cp -r $CA_HOME/install/solr/solr-4.10.0/lib $newCore/.

# call Solr API for creating a new core
# @see: https://wiki.apache.org/solr/CoreAdmin#CREATE
echo "Creating Solr Core ..."
curl "http://localhost:8983/solr/admin/cores?action=CREATE&name=$1&instanceDir=$newCore"
echo "^^^ The lines above are showing the output from Solr. ^^^"

###
# Finish
###

echo "Finished!"
echo "Check the permission of the created directories: \n\t$CA_CORES_DIR/$1 \n\t$SOLR_CORES_DIR/$1"
echo "Check your core-specific simplepipeline.xml and indexer.xml inside the directories: \n\t$CA_CORES_DIR/$1/config/pipeline \n\t$CA_CORES_DIR/$1/config/indexer\n"

exit 0;
