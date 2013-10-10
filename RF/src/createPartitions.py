import Partitioner,sys

def main():
    # fname='../data/covtype/train.csv'
    fname='../data/small/train.csv'
    tset='../data/covtype/test.csv'

    dtype = 'small'
    # create round robin partitions
    createPartitions(fname, dtype, tset, 'rr')

    # create shuffled partitions
    createPartitions(fname, dtype, tset, 'shuf')

    # create even class distribution partitions
    createPartitions(fname, dtype, tset, 'even_c')

    # create unbalanced class distribution partitions
    # here we will just say that node 0 doesnt get class 2
    createPartitions(fname, dtype, tset, 'uneven_c', [0], [0])


def createPartitions(fname, dname, tset, ptype, ignored_p=[], ignored_c=[]):
    for i in [5,10,50,100]:
        numChunks = i
        print 'Creating %d chunks partitioned with: %s' % (numChunks,ptype)
        partitioner = Partitioner.Partitioner(fname, dname, tset, numChunks,
                                              ptype, ignored_p, ignored_c)
        partitioner.partition()



if __name__ == '__main__':
    main()
