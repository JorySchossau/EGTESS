#!/bin/bash

./game.sh $(python makeNeutralTable.py 0.5) game.w32.m0.exe gb0.5m0 100000 100
./game.sh $(python makeNeutralTable.py 0.5) game.w32.m1.exe gb0.5m1 100000 100
./game.sh $(python makeNeutralTable.py 0.5) game.w32.m2.exe gb0.5m2 100000 100
./game.sh $(python makeNeutralTable.py 0.5) game.w32.m3.exe gb0.5m3 100000 100
./game.sh $(python makeNeutralTable.py 0.5) game.w32.m4.exe gb0.5m4 100000 100
./game.sh $(python makeNeutralTable.py 0.5) game.w32.m5.exe gb0.5m5 100000 100
