##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# distributed random forest algorithm.                                       #
##############################################################################
##############################################################################
# This class will take a dataset, read it from disk and create chunks of     #
# data which can be partitioned in various ways.                             #
# Current partitioning schemes: round robin, random shuffle.                 #
##############################################################################

import random,os

class Partitioner:
    # parameters:
    # dname: the name of the data set
    # numChunks: the number of chunk files to produce
    # ptype: the type of partitioning to use
    def __init__(self, dname, numChunks=2, chunkSize=0, sort='none'):
        self.dname = dname
        self.numChunks = int(numChunks);
        self.chunkSize = int(chunkSize)
        self.sort = sort

    # this is the main method, call this to create the partitions
    def partition(self):
        self.__part()
        
    # this is a standard partitioning scheme. chunk the data into partitions as
    # evenly distributed as possible. round robin style.
    def part(self):
        # list of file descriptors. one for each chunk
        self.__makedirs()
        fds = [ open('../data/%s/storage/%s_%d/%d/chunk%d.csv' %
                     (self.dname,self.sort,self.chunkSize,self.numChunks,i),'w')
                for i in xrange(self.numChunks) ]

        with open('../data/%s/train.csv' % self.dname,'r') as f:
            lines = f.readlines()
        lines = map(lambda x: x.strip(' \n'), lines)
        if self.sort != 'none':
            lines = self.__sort_p(lines)

        header = lines.pop(0)
        for x in fds: x.write('%s\n' % header)

        length = len(lines)
        if self.chunkSize == 0:
            self.chunkSize = length / self.numChunks

        linenum=0
        while linenum < length:
            for i in range(self.numChunks):
                count = 0
                while count < self.chunkSize and linenum < length:
                    fds[i].write('%s\n' % lines[linenum])
                    count += 1
                    linenum += 1
        [ x.close for x in fds ]

    def sort_p(self, lines):
        newlines = []
        bad = False
        # opens the file and reads into list
        header = lines[0].strip('\n').split(',')
        if self.sort in header:
            index = header.index(self.sort)
        else:
            print 'No sort column being used.'
            bad = True
        length = len(lines[1:])
        for line in lines[1:]:
            line = line.split(',')
            newlines.append(line)

        if not bad:
            newlines.sort(cmp=lambda x,y: cmp(x[index],y[index]))
        newlines.insert(0, header)
        newlines = map(lambda x: ','.join(x), newlines)

        return newlines
        
    def mkdirs(self):
        try:
            os.makedirs('../data/%s/storage/%s_%d/%d' %
                        (self.dname,self.sort,self.chunkSize,self.numChunks))
        except:
            print 'fail'
            pass
                
        
    __makedirs = mkdirs
    __part = part
    __sort_p = sort_p
