import Partitioner,sys

def main():
    fname='../data/covtype/train.csv'
    tset='../data/covtype/test.csv'

    # create round robin partitions
    createPartitions(fname, tset, 'rr')

    # create shuffled partitions
    createPartitions(fname, tset, 'rand')

    # create even class distribution partitions
    createPartitions(fname, tset, 'even_c')

    # create unbalanced class distribution partitions
    # here we will just say that node 0 doesnt get class 2
    createPartitions(fname, tset, 'uneven_c', [0], [0])


def createPartitions(fname, tset, ptype, ignored_p, ignored_c):
    for i in [5,10,50,100]:
        numChunks = i
        print 'Creating %d chunks partitioned with: %s' % (numChunks,ptype)
        partitioner = Partitioner.Partitioner(fname, tset, numChunks, ptype,
                                              ignored_p, ignored_c)
        partitioner.partition()



if __name__ == '__main__':
    main()
