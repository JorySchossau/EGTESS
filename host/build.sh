#!/bin/bash

mkdir -p bin

EXENAME=
DEFAULT_NAME="gameRPS"
EXTENSION=""
COMPILER="g++"

help() {
	echo
	echo Usage: "./$(basename $0) [win32] [binaryName]"
	echo
}

if [ "$1" == "--help" ]; then
	help
	exit
fi

if [ -z $1 ]; then
	EXENAME="$DEFAULT_NAME"
else
	if [ "$1" == "win32" ]; then
		COMPILER="i386-mingw32-g++"
		EXTENSION=".exe"
		if [ -z $2 ]; then
			EXENAME="$DEFAULT_NAME"
		else
			EXENAME="$DEFAULT_NAME.$2"
		fi
	else
		EXENAME="$DEFAULT_NAME.$1"
	fi
fi

$COMPILER -O3 -o bin/$EXENAME$EXTENSION src/main.cpp;
