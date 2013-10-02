import Partitioner

def main():
    partitioner = Partitioner.Partitioner('../covtype/test.csv')
    # partitioner = Partitioner.Partitioner('testSmall.csv', numChunks=3, ptype='even_c')
    partitioner.partition()

if __name__ == '__main__':
    main()
