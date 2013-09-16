#!/bin/bash -login
#PBS -l nodes=1:ppn=1:gfx10
#PBS -l mem=2GB
#PBS -l walltime=00:10:00
#PBS -l feature=gpgpu
#PBS -l gres=gpu:2
#PBS -j oe
cd ~/experiments/cudaegt
#"$outname"
./game outfile 2 0.02 1000000
