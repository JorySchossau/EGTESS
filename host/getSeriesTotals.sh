#!/bin/bash

TARGETFOLDER=${1%/} # removes trailing slash

help()
{
	echo
	echo "Usage: $0 <TARGETFOLDER>"
	echo
	echo "Creates a totalsNUM.phy for each 1 million generations timepoint."
	echo
}

if [ -z "$1" ]; then
	help
	exit
fi

MIN=$(./getTotals.sh min $TARGETFOLDER)
echo "Limit is $MIN"
echo
for n in $(seq 62 62 $MIN); do
	echo "Slicing generation $n..."
	./getTotals.sh $n $TARGETFOLDER
	mv $TARGETFOLDER/totals.phy $TARGETFOLDER/totals$n.phy
done
echo "Done Slicing"


