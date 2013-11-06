##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# distributed random forest algorithm.                                       #
##############################################################################
##############################################################################
#
##############################################################################

import os

class dStorage ():
    # parameters:
    def __init__(self, dtype, sort, numNodes=5, chunkSize=0, maxMsg=0):
        self.dtype = dtype
        self.sort = sort
        self.numNodes = int(numNodes)
        self.chunkSize = int(chunkSize)
        if maxMsg < self.numNodes:
            self.maxMsg = self.numNodes
        else:
            self.maxMsg = int(maxMsg)
        self.messages = [0]*self.numNodes
        
    def run(self):
        self.__makedirs()

        fds = [ open('../data/%s/compute/%s_%s/%s/chunk%d.csv' %
                     (self.dtype,self.sort,self.chunkSize,self.numNodes,i),'w')
                for i in xrange(self.numNodes) ]


        start = 1
        done = False

        for i in range(self.numNodes):
            with open('../data/%s/storage/%s_%d/%d/chunk%d.csv' %
                      (self.dtype,self.sort,self.chunkSize,self.numNodes,
                       i)) as f:
                lines = f.readlines()
            header = lines.pop(0)
            if i==0:
                [ f.write(header) for f in fds ]

            if len(lines)-1 / self.maxMsg < self.chunkSize:
                self.chunkSize = (len(lines)-1) / self.maxMsg


            start = 0
            done = False
            j = i
            while not done:
                end = start + self.chunkSize
                if end >= len(lines)-1:
                    end = len(lines)
                    done = True

                fds[j%self.numNodes].write(''.join(lines[start:end]))

                self.messages[i] += 1
                start += self.chunkSize
                j += 1
                if done: break

        [ x.close for x in fds ]
        return self.messages

    def mkdirs(self):
        try:
            os.makedirs('../data/%s/compute/%s_%s/%s' %
                        (self.dtype,self.sort,self.chunkSize,self.numNodes))
        except:
            print '../data/%s/compute/%s_%s/%s' % \
                (self.dtype,self.sort,self.chunkSize,self.numNodes)
            pass
        
    __makedirs = mkdirs
