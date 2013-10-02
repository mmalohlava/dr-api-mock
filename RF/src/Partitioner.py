##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# random forest algorithm.                                                   #
##############################################################################
##############################################################################
# This class will take a dataset, read it from disk and create chunks of     #
# data which can be partitioned in various ways.                             #
# Current partitioning schemes: round robin, random shuffle.                 #
##############################################################################

import random

class Partitioner:
    # parameters:
    # fname: the name of the data file
    # numChunks: the number of chunk files to produce
    # ptype: the type of partitioning to use
    def __init__(self, fname, numChunks=2, ptype=None):
        self.fname = fname
        self.numChunks = numChunks;
        self.ptype = ptype

    # this is the main method, call this to create the partitions
    def partition(self):
        if self.ptype == None or self.ptype == 'rand':
            self. __part()
        elif self.ptype == 'even_c':
            self.__part_even_c()
        
    # this is a standard partitioning scheme. chunk the data into partitions as
    # evenly distributed as possible. round robin style.
    def part(self):
        # list of file descriptors. one for each chunk
        fds = [ open('chunk%d.csv' % i,'a') for i in xrange(self.numChunks) ]
        
        if self.ptype == 'rand': choices_m = range(self.numChunks)

        # opens the file and creates chunk using round robin distribution
        with open(self.fname,'r') as f:
            # REMOVES THE FEATURE LABELS
            f.readline()
            line = f.readline()
            while line != '':
                if self.ptype == 'rand':
                    # if this isn't random enough let's try random.choice on
                    # choices_s
                    choices_s = choices_m[:]
                    random.shuffle(choices_s)

                # put the entry into the correct chunk
                for j in xrange(self.numChunks):
                    if line != '':             # make sure we aren't at the EOF
                        if self.ptype == 'rand':
                            fds[choices_s.pop()].write('%s' % line)
                        else:
                            fds[j].write('%s' % line)
                        line = f.readline()
                    else: break

    # here we try to partition the data such that each class is represented
    # evenly among all nodes. this doesn't mean that class1 will have the same
    # number of instances as class2 on each node but rather that all instances
    # of class1 will be 'evenly' distributed' across all nodes.
    def part_even_c(self):
        # list of file descriptors. one for each chunk
        fds = [ open('chunk%d.csv' % i,'a') for i in xrange(self.numChunks) ]
        class_dict = {}
        
        # opens the file and creates chunk using round robin distribution
        with open(self.fname,'r') as f:
            # REMOVES THE FEATURE LABELS
            f.readline()
            line = f.readline()
            while line != '':
                # get the class of this line
                cls = line.split(',')[-1].strip('\r\n')

                #we've seen this class before, or not
                if cls in class_dict: dist = class_dict[cls]
                else:
                    dist = [0]*self.numChunks
                    class_dict[cls] = dist[:]

                # which chunk has the least amount of this class?
                loc = dist.index(min(dist))
                fds[loc].write('%s' % line)
                class_dict[cls][loc]+=1

                line = f.readline()
        
        for k in class_dict:
            print k,class_dict[k]
        
    __part = part
    __part_even_c = part_even_c
