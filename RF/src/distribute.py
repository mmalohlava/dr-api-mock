##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# distributed random forest algorithm.                                       #
##############################################################################
##############################################################################
#
##############################################################################

import dStorage

def main():
    numNodes = [5,10,50,100]
    for nodes in numNodes:
        d = dStorage.dStorage('covtype', 'A55', nodes, 500, 10000)
        messages = d.run()
        print messages

if __name__ == '__main__':
    main()
