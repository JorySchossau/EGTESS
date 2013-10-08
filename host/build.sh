#!/bin/bash

mkdir -p bin

DEFAULT_NAME="game"
EXENAME=$DEFAULT_NAME
EXTENSION=""
COMPILER="g++"

GENES=2
GENES_DEFINE="#define GENES"
GENES_DECLARATION="$GENES_DEFINE 2"

LOCALMU=false
LOCALMU_DEFINE="#define LOCALMU"
LOCALMU_DECLARATION="$LOCALMU_DEFINE false"

help() {
	echo
	echo Usage: "./$(basename $0) [-hwg]"
	echo "       -h help"
	echo "       -w build win32 using mingw32"
	echo "       -l build for local mu"
	echo "       -g<#genes> change default number of genes (only 2,3 are valid yet)"
	echo
}

while getopts "hg:lw" OPTIONS; do
	case $OPTIONS in
		h) help;;
		w)
			COMPILER="i386-mingw32-g++"
			EXTENSION=".exe"
			EXENAME=$EXENAME.w32
			;;
		g) 
			GENES=$OPTARG
			EXENAME=$EXENAME.g$GENES
			;;
		l)
			LOCALMU=true
			EXENAME=$EXENAME.l
			;;
		?)
			echo "Unknown option: $OPTARG"
			exit 1
			;;
	esac
done

#if [ -z $1 ]; then
#	EXENAME="$DEFAULT_NAME"
#else
#	if [ "$1" == "win32" ]; then
#		COMPILER="i386-mingw32-g++"
#		EXTENSION=".exe"
#		if [ -z $2 ]; then
#			EXENAME="$DEFAULT_NAME"
#		else
#			EXENAME="$DEFAULT_NAME.$2"
#		fi
#	else
#		EXENAME="$DEFAULT_NAME.$1"
#	fi
#fi

sed -ie "s/$GENES_DECLARATION/$GENES_DEFINE $GENES/" src/main.cpp
sed -ie "s/$LOCALMU_DECLARATION/$LOCALMU_DEFINE $LOCALMU/" src/main.cpp

$COMPILER -O3 -o bin/$EXENAME$EXTENSION src/main.cpp;

sed -ie "s/$LOCALMU_DEFINE $LOCALMU/$LOCALMU_DECLARATION/" src/main.cpp
sed -ie "s/$GENES_DEFINE $GENES/$GENES_DECLARATION/" src/main.cpp
