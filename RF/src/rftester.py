from sklearn.ensemble import RandomForestClassifier
from numpy import genfromtxt, savetxt

def main():
    print 'Reading in training set....'
    dataset = genfromtxt(open('covtype/train.csv','r'), delimiter=',')[1:]
    target = [x[-1] for x in dataset]
    train = [x[:-1] for x in dataset]

    print 'Reading in test set....'
    test = genfromtxt(open('covtype/test.csv'), delimiter=',')[1:]

    print 'Fitting ....'
    rf = RandomForestClassifier(n_jobs=-1)
    rf.fit(train, target)

    print 'Predicting ....'
    savetxt('covtype/results.csv', rf.predict(test), delimiter=',')

if __name__ == '__main__':
    main()
