import RFSampler


x = [[2,2,2,2,2,2,2,2,2,2]]
samp = RFSampler.RFSampler(x)
path = 'Data/Balanced/Binary/Deterministic/'

samp.get_sample(2*1e5,path + 'train.csv')
#samp.get_sample(5*1e4,path + 'test.csv')