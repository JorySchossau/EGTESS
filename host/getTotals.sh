#!/bin/bash

GENERATION=$1
shift
FOLDERS=$@

## here we use a hacky backdoor utility
## to check what is the highest generation
## we can use in this tool.
## Usage: $0 min specificFolder
## Output: anumber
if [[ $GENERATION == "min" ]]; then
	wc -l $FOLDERS/*.phy | sed 's/^[ \t]*//' | cut -d ' ' -f1 | sort | head -n 2 | tail -n 1
	exit
fi

help()
{
	echo
	echo "Usage: $0 GENERATION FOLDERS"
	echo "GENERATION: gen at which to extract sample."
	echo "FOLDERS: a list of folders to process."
	echo
	exit
}

if [ -z "$GENERATION" ];
then
	help
fi

if [ -z "$FOLDERS" ];
then
	help
fi

for folder in $FOLDERS; do
	echo -ne "processing [$folder]"
	rm $folder/totals.phy 2> /dev/null
	echo generation,g0,g1,p0,p1,p2 > $folder/totals
	for file in $folder/*.phy; do
		head -n $GENERATION $file | tail -n 1 >> $folder/totals
	done
	echo "done!"
	mv $folder/totals $folder/totals.phy
done
