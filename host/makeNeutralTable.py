import sys

if (len(sys.argv) < 2):
	print
	print "Expect one argument: percentOfBiasAsFloat"
	print "Example: ./makeNeutralTable.py 0.3"
	print "Outputs a 3 player payoff matrix where"
	print "player 3 is the mixed strategy with equal"
	print "payoff to the other players."
	print
	exit()
percent = float(sys.argv[1])
a=1.
b=percent
m=(a*b)/(a+b)
print('%f %f %f %f %f %f %f %f %f' % (0.,a,0.,b,0.,0.,m,m,0.))

