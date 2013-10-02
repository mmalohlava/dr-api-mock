import Partitioner

def main():
    partitioner = Partitioner.Partitioner('../data/covtype/test.csv', ptype='uneven_c', ignored_p=[0,0], ignored_c=[0,1])
    # partitioner = Partitioner.Partitioner('testSmall.csv', numChunks=3, ptype='even_c')
    partitioner.partition()

if __name__ == '__main__':
    main()
