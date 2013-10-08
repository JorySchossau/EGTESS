#!/bin/bash

PM="$1 $2 $3 $4 $5 $6 $7 $8 $9"
echo $PM
shift 9

RUN_DIR=$2
GENERATIONS=$3
PROGRAM=$1
REPLICATES=$4
LOCALMU=$5
DELTAMU=$6

function list() {
	echo
	echo "Games available:"
	echo
	ls -1 bin/*.exe
	echo
	exit
	exit
}

function help() {
echo
echo "Usage: $0 p a y o f f m a t windowsEXE NewOutFolderName Generations Replicates [mu deltaMu]"
echo
echo "Submits a Condor job using condorPhiFiles/condor.blank.egtmix.sh ."
#if [ ! -f condorEGTMixFiles/condor.blank.egtmix.sh ]
#then
#	echo "WARNING! condorPhiFiles/condor.blank.egtmix.sh does not exist!"
#fi
echo
echo "use: $0 list"
echo "to list all available game executables."
echo
echo "Example:"
echo "$0 0 1 1 1 0 1 1 1 0 game.exe mytables 10000 100"
echo "This will test using game.exe for 10000 generations"
echo "   100 iterations, and place them in the directory 'mytables'."
echo
echo "windowsEXE: The win32 compiled executable."
echo "NewOutputFolderName: New folder to make, in which to place output."
echo "Generations: Number of generations to simulate."
echo "Replicates: How many iterations to play the whole game."
echo "Period: optionally, to use a dynamic fitness landscape."
echo "   period specifies how many generations it takes to"
echo "   transition from one table to the other."
echo
list
exit
}



if [ -z $PROGRAM ]
then
	help
	exit
fi

if [ $1 == "list" ]
then
	list
fi

if [ -z $RUN_DIR ]
then
    help
	exit
fi

if [ -z $PERIOD ]
then
	echo > /dev/null
else
	if [ "$PERIOD" -ne "$PERIOD" ]
	then
		echo "Argument error: period '$PERIOD' not a number?"
		echo
		help
		exit
	fi
fi

if [ -e bin/$PROGRAM ]
then
	echo > /dev/null
else
	echo "Argument error: program 'bin/$PROGRAM' not found."
	echo
	help
fi

if [ -z "$GENERATIONS" ]
then
	echo
	echo "Argument error: expected Generations to test."
	echo
	help
fi

if [ -z "$REPLICATES" ]
then
	echo
	echo "Argument error: expected Replicates to test."
	echo
	help
fi

if [ "$GENERATIONS" -ne "$GENERATIONS" ]
then
	echo
	echo "Argument error: generations not a number."
	echo
	help
fi

if [ "$REPLICATES" -ne "$REPLICATES" ]
then
	echo
	echo "Argument error: replicates not a number."
	echo
	help
fi


#if [ -e condorEGTMixFiles ]
#then
#	echo > /dev/null
#else
#	echo "Runtime error: Required folder 'condorEGTMixFiles' not found."
#	help
#fi
#
if [ ! -f condor.blank.egtmix.sh ]
then
	echo "WARNING! condor.blank.egtmix.sh does not exist!"
	help
fi

echo "Copying program to $RUN_DIR"

mkdir -p $RUN_DIR
cp bin/$PROGRAM $RUN_DIR

module load condor

echo -ne Submitting Batch:
sed -e s#XRUNDIRX#$RUN_DIR#g condor.blank.egtmix.sh | sed -e s#XPMX#"$PM"#g | sed -e s#XPROGRAMX#$PROGRAM#g | sed -e s#XPERIODX#$PERIOD#g | sed -e s#XRUNSX#$REPLICATES#g | sed -e s#XOUTPUTNAMEX#replicate#g | sed -e s#XGENERATIONSX#$GENERATIONS#g | sed -e s#XLOCALMUX#$LOCALMU#g | sed -e s#XDELTAMUX#$DELTAMU#g > $RUN_DIR/condorEGTMix.sh
#pushd $RUN_DIR
condor_submit $RUN_DIR/condorEGTMix.sh > /dev/null
#popd
echo "Done!"

