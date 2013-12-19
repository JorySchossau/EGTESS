#!/bin/bash

./build.sh -g2
./game.sh $(python makeNeutralTable.py 0.1) game.g2 g2b0.1 1000000 1000
./game.sh $(python makeNeutralTable.py 0.3) game.g2 g2b0.3 1000000 1000
./game.sh $(python makeNeutralTable.py 0.5) game.g2 g2b0.5 1000000 1000
./game.sh $(python makeNeutralTable.py 0.7) game.g2 g2b0.7 1000000 1000
./game.sh $(python makeNeutralTable.py 0.9) game.g2 g2b0.9 1000000 1000

./build.sh -g2 -l
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l g2b0.8l0.1 1000000 1000 0.02 0.1
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l g2b0.8l0.3 1000000 1000 0.02 0.3
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l g2b0.8l0.5 1000000 1000 0.02 0.5
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l g2b0.8l0.7 1000000 1000 0.02 0.7
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l g2b0.8l0.9 1000000 1000 0.02 0.9
