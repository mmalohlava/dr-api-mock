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
distTrain <- function(ptype, dtype, nodes, rows=-1) {
    err = double()

    ## iterate over the process 5 times
    for (m in 1:5) {
        print(paste("Run number:",m,"nodes:",nodes,"type:",ptype))
        fnames <- character()
        
        ## read all the chunks into a list (fnames)
        print(paste("Reading files..."))
        for (i in 0:(nodes-1)) {
            name <- paste("file",i,sep="")
            assign(name, read.csv(
                paste("../data/",dtype,"/",ptype,"/",nodes,"/chunk",i,".csv",
                      sep=""),
                header=TRUE, nrows=rows))
            fnames <- c(fnames, name)
        }

        ## read in the test data
        test <- read.csv(paste("../data/",dtype,"/test.csv",sep=""),
                         header=TRUE)
        ## create a list of the correct answers to the test data. used later
        ## for error evaluation
        correct = strsplit(toString(test[,"A55"]),",")
        correct = lapply(correct, function(x) gsub(" ","",x))

        ## create a list of random forests built on the previously read chunks
        rflist = character()
        print(paste("Bulding forests..."))
        for (i in 1:nodes) {
            rfname <- paste("rf",i,sep="")
            assign(rfname,randomForest(A55~.,data=get(fnames[i]),ntree=nodes,
                                       norm.votes=FALSE))
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
        allnames <- sort(unique(unlist(prenames)))

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

        ## compute the total error
        incorrect = 0
        for (i in 1:nrow(combined_pre)) {
            predClass = which.max(combined_pre[i,])
            ## incorrect prediction
            if (allnames[predClass] != correct[[1]][i])
                incorrect = incorrect + 1
        }
        err <- c(err, incorrect/nrow(combined_pre))
    }
    err
}

# create a forest on the whole data set, and predict with that.
# parameters -- dtype: name of the dataset
#               nodes: numbers of trees to use in the forest
#               rows: number of rows to read from file. used for debugging
singleTrain <- function(dtype, nodes, rows=-1) {
    err = double()
    ## do the process more than once
    for (i in 1:5) {
        ## read in training file
        print(paste("Run number:",i,"nodes:",nodes,"type: single"))
        print("Reading files...")
        d0 <- read.csv(paste('../data/',dtype,'/train.csv',sep=''),
                       header=TRUE, nrows=rows)

        ## read in test file
        test = read.csv(paste('../data/',dtype,'/test.csv',sep=''),
            header=TRUE, nrows=rows)
        correct = strsplit(toString(test[,"A55"]),",")
        correct = lapply(correct, function(x) gsub(" ","",x))

        ## build the tree
        print("Building tree...")
        rf <- randomForest(A55~.,data=d0, ntree=nodes, norm.votes=FALSE)

        ## predict
        pre = predict(rf, test, type='vote', norm.votes=FALSE)
        allnames <- sort(unique(unlist(colnames(pre))))

        ## compute the error in the predictions        
        incorrect = 0
        for (i in 1:nrow(pre)) {
            predClass = which.max(pre[i,])
            ## incorrect prediction
            if (allnames[predClass] != correct[[1]][i])
                incorrect = incorrect + 1
        }
        err <- c(err, incorrect/nrow(pre))
    }
    err
}

# debugging
rows = -1
## name of data to test
type = "covtype"
## list of number of nodes to test
nList = c(5,10,50,100)
## partition types
pNames = c("Standard", "Round Robin", "Shuffle", "Even Class", "Uneven Class")
## matrix of averages of results
means = matrix(0, nrow = length(nList), ncol = length(pNames))
## matrix of standard deviations of results
sds = matrix(0, nrow = length(nList), ncol = length(pNames))

for (nodes in nList) {
    ## train on the single RF
    s = singleTrain(type, nodes, rows)
    print(mean(s))
    print(sd(s))
    means[which(nList == nodes),1] = mean(s)
    sds[which(nList == nodes),1] = sd(s)

    ## train round robin on the distributed forest
    rr = distTrain("rr", type, nodes, rows=rows)
    print(mean(rr))
    print(sd(rr))
    means[which(nList == nodes),2] = mean(rr)
    sds[which(nList == nodes),2] = sd(rr)

    ## train shuffled on the distributed forest
    shuf = distTrain("shuf", type, nodes, rows=rows)
    print(mean(shuf))
    print(sd(shuf))
    means[which(nList == nodes),3] = mean(shuf)
    sds[which(nList == nodes),3] = sd(shuf)

    ## train even class distribution on the distributed forest
    even_c= distTrain("even_c", type, nodes, rows=rows)
    print(mean(even_c))
    print(sd(even_c))
    means[which(nList == nodes),4] = mean(even_c)
    sds[which(nList == nodes),4] = sd(even_c)

    ## train uneven class distribution on the distributed forest
    uneven_c= distTrain("uneven_c", type, nodes, rows=rows)
    print(mean(uneven_c))
    print(sd(uneven_c))
    means[which(nList == nodes),5] = mean(uneven_c)
    sds[which(nList == nodes),5] = sd(uneven_c)

    meanRun = c(mean(s),mean(rr),mean(shuf),mean(even_c),mean(uneven_c))
    sdRun = c(sd(s),sd(rr),sd(shuf),sd(even_c),sd(uneven_c))
    plotname = paste(nodes,".png",sep="")
    png(plotname, width=1200, height = 600)

    ## create barplot for this amount of nodes (partition type vs. error)
    bp <- barplot(meanRun,
            main=paste("Error rates vs Partition scheme\nFor",nodes,"nodes"),
            xlab="Partitioning scheme",, ylab="Error rate",
            names.arg=pNames, ylim=c(0,1),
            cex.names=1.2, cex.axis=1.2, cex.lab=1.75, cex.main=2.25)
    
    arrows(bp, meanRun+sdRun, bp, meanRun-sdRun, angle=90, code=3, length=0.1)
    dev.off()
}
print(means)
print(sds)
## create line graph for nodes vs. error
plotname = "nodesVSerr.png"
png(plotname, width=1000, height = 600)

xrange = 1:length(nList)
print(xrange)
co = c("black","blue","red","green","purple")

p <- plot(xrange, means[,1], ylim=c(0,1), type='b', xaxt="n",
          xlab="Number of random forests", ylab="Error rate", pch=16)

legend(tail(xrange,1)-0.4, 1.0, legend=pNames, lty=c(1,1), lwd=c(2.5,2.5),
       col=co)
for (i in 2:length(means[1,]))
    points(xrange, means[,i], col=co[i], type='b')

for (col in 1:ncol(means))
    for (row in xrange) 
        if (sds[row,col] > 0.00001) 
            arrows(row,means[row,col]+sds[row,col],row,
                   means[row,col]-sds[row,col],
                   angle=90, code=3, length=0.05)

axis(1, at=xrange, label=nList)
dev.off()
