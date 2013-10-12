import RFSampler


x = [[2,2,2,2,2,2,2,2,2,2]]
samp = RFSampler.RFSampler(x,p=0.2)
samp.get_sample(2*1e5,'Data/Balanced/Binary/Noisy/train.csv')