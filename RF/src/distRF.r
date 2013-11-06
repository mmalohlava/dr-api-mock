#!/usr/local/bin/Rscript
##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# distributed random forest algorithm as well as various types of data and   #
# how this will impact on error rates.                                       #
##############################################################################
##############################################################################
# This code will take a dataset, read already split into chunks, read each   #
# chunk into a list, create a random forest for each chunk, do a prediction  #
# on each forest, then combine the forest and estimate the error rate.       #
##############################################################################

library(randomForest)

# this will compute the error rates on the distributed forests.
# parameters -- ptype: the partitioning type
#               dtype: name of the data
#               nodes: number of nodes to create
#               rows: number of rows to read in. used for debugging
distTrain <- function(dtype, nodes, trees, size, sortC, chunkSize, rows=-1) {
    err = double()

    errorByClass = double(length = size)
    counts = double(length = size)
    ## iterate over the process 5 times
    for (m in 1:ITER) {
        print(paste("Run number:",m,"nodes:",nodes,"trees:",trees,
                    "trees/node:",trees/nodes, "type:","data:",dtype))
        fnames <- character()
        
        ## read all the chunks into a list (fnames)
        print(paste("Reading files..."))
        for (i in 0:(nodes-1)) {
            ## print(paste("../data/",dtype,"/",ptype,"/",nodes,"/chunk",i,".csv"
            ##             , sep=""))
            name <- paste("file",i,sep="")
            assign(name, read.csv(
                paste("../data/",dtype,"/compute/",sortC,"_",chunkSize,"/",
                      nodes,"/chunk",i,".csv",sep=""),
                header=TRUE, nrows=rows))
            fnames <- c(fnames, name)
        }

        ## read in the test data
        test <- read.csv(paste("../data/",dtype,"/test.csv",sep=""),
                         header=TRUE, nrows=rows)
        ## create a list of the correct answers to the test data. used later
        ## for error evaluation
        if (dtype != "covtype")
            correct <- strsplit(toString(test[,"A11"]),",")
        else
            correct <- strsplit(toString(test[,"A55"]),",")
        correct <- lapply(correct, function(x) gsub(" ","",x))

        ## create a list of random forests built on the previously read chunks
        rflist = character()
        print(paste("Bulding forests..."))
        for (i in 1:nodes) {
            rfname <- paste("rf",i,sep="")
            if (dtype != "covtype")
                assign(rfname,randomForest(A11~.,data=get(fnames[i]),
                                           ntree=trees/nodes, norm.votes=FALSE))
            else
                assign(rfname,randomForest(A55~.,data=get(fnames[i]),
                                           ntree=trees/nodes, norm.votes=FALSE))
            rflist <- c(rflist, rfname)
        }

        ## do a prediction using the test set on each forest
        prlist = character()
        print("Predicting...")
        for (i in 1:length(rflist)) {
            pname <- paste("pr",i,sep="")
            assign(pname, predict(get(rflist[i]), test, type='vote',
                                  norm.votes=FALSE))
            prlist <- c(prlist, pname)
        }

        ## create a list of the classes in each prediction result
        prenames = list()
        for (i in 1:length(prlist))
            prenames = c(prenames, list(colnames(get(prlist[i]))))
        allnames <- sort(unique(unlist(correct[[1]])))

        ## combine the predicition tables
        combined_pre <- matrix(0, nrow = nrow(get(prlist[1])),
                               ncol = length(allnames),
                               dimnames = list(seq(1,nrow(get(prlist[1])),1),
                               allnames))

        print("Combining predictions...")
        for (k in 1:length(prlist)) {
            j <- 1
            for (i in 1:length(prenames[[k]])) {
                while(prenames[[k]][i] != allnames[j] && j <= length(allnames))
                    j <- j + 1
                if (j > length(allnames)) break

                combined_pre[,j] = combined_pre[,j] + get(prlist[k])[,i]
                j <- j + 1
            }
        }

        ## print(combined_pre)
        ## print(correct[[1]])
        ## compute errors by class
        for (i in 1:nrow(combined_pre)) {
            max = max(combined_pre[i,])
            correctI = correct[[1]][i]
            cPos = which(allnames == correct[[1]][i])
            pos =  which(combined_pre[i,] == max(combined_pre[i,]))

            ## print(paste("correct:",correct[[1]][i],"sum:",sum(combined_pre[i,]),
            ##             "max:",max(combined_pre[i,]),"posistion:", pos,
            ##             "correct position:", cPos))
            if (!cPos %in% pos)
                errorByClass[cPos] = errorByClass[cPos] + 1

            counts[cPos] = counts[cPos] + 1
        }
        ## print(errorByClass)
        ## compute the total error
    ##     incorrect = 0
    ##     for (i in 1:nrow(combined_pre)) {
    ##         predClass = which.max(combined_pre[i,])
    ##         ## incorrect prediction
    ##         if (allnames[predClass] != correct[[1]][i])
    ##             incorrect = incorrect + 1
    ##     }
    ##     err <- c(err, incorrect/nrow(combined_pre))
    }
    ## err
    ## print(errorByClass)
    ## print(counts)
    for (n in 1:length(errorByClass)) 
        errorByClass[n] = errorByClass[n] / counts[n]
    errorByClass
}

# create a forest on the whole data set, and predict with that.
# parameters -- dtype: name of the dataset
#               nodes: numbers of trees to use in the forest
#               rows: number of rows to read from file. used for debugging
singleTrain <- function(dtype, trees, size, rows=-1) {
    err = double()
    ## do the process more than once
    errorByClass = double(length = size)
    counts = double(length = size)
    for (i in 1:ITER) {
        ## read in training file
        print(paste("Run number:",i,"trees:",trees,"type: single data:",dtype))
        print("Reading files...")
        ## print(paste("../data/",dtype,"/train.csv",sep=""))
        d0 <- read.csv(paste('../data/',dtype,'/train.csv',sep=''),
                       header=TRUE, nrows=rows)

        ## read in test file
        test = read.csv(paste('../data/',dtype,'/test.csv',sep=''),
            header=TRUE, nrows=rows)
        correct = strsplit(toString(test[,length(test)]),",")
        correct = lapply(correct, function(x) gsub(" ","",x))

        ## build the tree
        print("Building tree...")
        if (dtype != "covtype")
            rf <- randomForest(A11~., data=d0, ntree=trees, norm.votes=FALSE)
        else
            rf <- randomForest(A55~., data=d0, ntree=trees, norm.votes=FALSE)

        ## predict
        print("Predicting...")
        pre = predict(rf, test, type='vote', norm.votes=FALSE)
        allnames <- sort(unique(unlist(colnames(pre))))

        ## print(pre)
        ## print(correct[[1]])
        for (i in 1:nrow(pre)) {
            max = max(pre[i,])
            correctI = correct[[1]][i]
            cPos = which(allnames == correct[[1]][i])
            pos =  which(pre[i,] == max(pre[i,]))

            if (!cPos %in% pos)
                errorByClass[cPos] = errorByClass[cPos] + 1

            counts[cPos] = counts[cPos] + 1
        }
        ## print(errorByClass)
        ## print(counts)
    }
    ## print(errorByClass)
    ## print(counts)
    ## err
    for (n in 1:length(errorByClass)) 
        errorByClass[n] = errorByClass[n] / counts[n]
    ## print(errorByClass)
    errorByClass
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4)
    stop("Usage: ./distRF num_trees chunk_size sort_column datatype_name(s)")
# debugging
rows = -1
## number of iterations for each test
ITER <- 5
## number of trees
trees = strtoi(args[1])
## size of the chunk (in lines)
chunkSize = args[2]
## column which the data is sorted on (or 'None')
sortC = args[3]
## name of data set(s) to test
types = args[-3:-1]
## list of number of nodes to test
nList = c(5,10,50,100)
## nList = c(5)
cNames = c("1",nList)
print(cNames)
## partition types
pNames = c("Standard", "Round Robin")

for (type in types) {
    test <- read.csv(paste("../data/",type,"/test.csv",sep=""),
                     header=TRUE, nrows=rows)
    if (type != "covtype")
        correct <- strsplit(toString(test[,"A11"]),",")
    else
        correct <- strsplit(toString(test[,"A55"]),",")
    remove(test)
    correct <- lapply(correct, function(x) gsub(" ","",x))
    allnames <- sort(unique(unlist(correct[[1]])))
    size = length(allnames)

    ## train on the single RF
    s = singleTrain(type, trees, size, rows)
    m <- cbind(s)
    print(m)
    write.csv(m, file="tmp.csv")
    for (nodes in nList) {

        ## train round robin on the distributed forest
        rr = distTrain(type, nodes, trees, size, sortC, chunkSize, rows=rows)
        print(rr)

        tmp = read.csv(file="tmp.csv", row.names=1)
        m <- cbind(tmp, rr)
        print(m)
        write.csv(m, file="tmp.csv")
    }
    tmp = read.csv(file="tmp.csv", row.names=1)
    colnames(tmp) <- cNames
    rownames(tmp) <- allnames
    print(tmp)
    write.csv(tmp, file=paste("../results/data/",type,"_",chunkSize,"_",sortC,
                           ".csv",sep=""))
    unlink("tmp.csv")
}
