#!/bin/bash

## permutations
#./build.sh -g2 -p0
#./build.sh -g2 -p1
#./build.sh -g2 -p2
#./build.sh -g2 -p3
#./build.sh -g2 -p4
#./build.sh -g2 -p5
./build.sh -g2
./game.sh $(python makeNeutralTable.py 0.1) game.g2 gb0.1 100000 1000
./game.sh $(python makeNeutralTable.py 0.3) game.g2 gb0.3 100000 1000
./game.sh $(python makeNeutralTable.py 0.5) game.g2 gb0.5 100000 1000
./game.sh $(python makeNeutralTable.py 0.7) game.g2 gb0.7 100000 1000
./game.sh $(python makeNeutralTable.py 0.9) game.g2 gb0.9 100000 1000

./build.sh -g2 -l
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l gb0.8l 100000 1000 0.02 0.1
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l gb0.8l 100000 1000 0.02 0.3
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l gb0.8l 100000 1000 0.02 0.5
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l gb0.8l 100000 1000 0.02 0.7
./game.sh $(python makeNeutralTable.py 0.8) game.g2.l gb0.8l 100000 1000 0.02 0.9
