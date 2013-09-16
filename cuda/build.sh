#!/bin/bash

NVCC_PATH=$(which nvcc)
NVCC_NAME=${m##*/}
EXENAME=

## Get user provided exe name (if exists)
if [ -z $1 ]; then
	EXENAME="gameRPScu"
else
	EXENAME=$1
fi

## Before compiling, check if the compiler is available
if [ "$NVCC_NAME" == "nvcc" ]; then
	nvcc -o bin/$EXENAME src/cudaEGT.cu
else
	echo "Error: Cuda compiler 'nvcc' not found."
fi
