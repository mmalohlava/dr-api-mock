import RFSampler


x = [[2,2,2,2,2,2,2,2,2,2]]
class_dist = [0.5,0.48,0.01,0.001,0.001]
samp = RFSampler.RFSampler(x,class_dist=class_dist)

path = '/Volumes/Stuff/Dropbox/MockRF/RFSampler/Data/Imbalanced/ClassOnly/'

samp.get_sample(2*1e5,path + 'train.csv')
samp.get_sample(5*1e4,path + 'test.csv')
