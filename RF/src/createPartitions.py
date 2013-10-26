import Partitioner,sys

def main():
    if len(sys.argv) < 2:
        print 'Usage: python createPartitions data_name [chunk_size] [sort_column]'
        exit()
    dname = sys.argv[1]
    if len(sys.argv) > 2: cSize = int(sys.argv[2])
    else: cSize = 0
    if len(sys.argv) > 3: sort = sys.argv[3]
    else: sort = 'none'

    fname='../data/%s/train.csv' % dname
    tset='../data/%s/test.csv'% dname

    # create round robin partitions
    for i in [5,10,50,100]:
        createPartitions(dname, nChunks = i, chunkSize = cSize, sort = sort)


def createPartitions(dname, nChunks, chunkSize, sort):
    print 'Creating %d chunks chunk size: %d for set: %s' % \
        (nChunks,chunkSize,dname)
    partitioner = Partitioner.Partitioner(dname, nChunks, chunkSize = chunkSize,
                                          sort = sort)
    partitioner.partition()


if __name__ == '__main__':
    main()
