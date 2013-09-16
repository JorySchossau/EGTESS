#!/bin/bash

mkdir -p bin

EXENAME=

if [ -z $1 ]; then
	EXENAME="gameRPS"
else
	EXENAME=$1
fi

g++ -O3 -o bin/$EXENAME src/main.cpp
