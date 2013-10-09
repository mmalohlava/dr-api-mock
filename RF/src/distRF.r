#!/usr/local/bin/Rscript
library(randomForest)

distTrain <- function(ptype,nodes,rows=-1) {
    for (m in 1:5) {
        print(paste("Run number:",m,"nodes:",nodes,"type:",ptype))
        fnames <- character()
        print(paste("Reading files..."))
        for (i in 0:(nodes-1)) {
            name <- paste("file",i,sep="")
            assign(name, read.csv(
                paste("../data/",ptype,"/",nodes,"/chunk",i,".csv",sep=""),
                header=TRUE, nrows=rows))
            fnames <- c(fnames, name)
        }
        test <- read.csv("../data/covtype/test.csv",header=TRUE)
        correct = strsplit(toString(test[,"A55"]),",")
        correct = lapply(correct, function(x) gsub(" ","",x))
        err = double()

        rflist = character()
        print(paste("Bulding forests..."))
        for (i in 1:nodes) {
            rfname <- paste("rf",i,sep="")
            assign(rfname,randomForest(A55~.,data=get(fnames[i]),ntree=nodes,
                                       norm.votes=FALSE))
            rflist <- c(rflist, rfname)
        }

        prlist = character()
        print("Predicting...")
        for (i in 1:length(rflist)) {
            pname <- paste("pr",i,sep="")
            assign(pname, predict(get(rflist[i]), test, type='vote',
                                  norm.votes=FALSE))
            prlist <- c(prlist, pname)
        }

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
                while (prenames[[k]][i] != allnames[j] && j <= length(allnames))
                    j <- j + 1
                if (j > length(allnames)) break

                combined_pre[,j] = combined_pre[,j] + get(prlist[k])[,i]
                j <- j + 1
            }
        }

        sum = 0
        for (i in 1:length(correct[[1]])) 
            for (j in 1:ncol(combined_pre)) 
                if (correct[[1]][i] != allnames[j])
                    sum = sum + combined_pre[i,j]

        err <- c(err,sum/sum(combined_pre))
    }
    mean(err)
}

singleTrain <- function(rows=-1) {
    for (i in 1:5) {
        print(paste("Run number:",i,"nodes:",1,"type: single"))
        print("Reading files...")
        d0 <- read.csv('../data/covtype/train.csv', header=TRUE, nrows=rows)

        test = read.csv('../data/covtype/test.csv', header=TRUE, nrows=rows)
        correct = strsplit(toString(test[,"A55"]),",")
        correct = lapply(correct, function(x) gsub(" ","",x))

        print("Building tree...")
        rf <- randomForest(A55~.,data=d0, ntree=1, norm.votes=FALSE)

        pre = predict(rf, test, type='vote', norm.votes=FALSE)
        allnames <- sort(unique(unlist(colnames(pre))))

        err = double()

        sum = 0
        for (i in 1:length(correct[[1]])) 
            for (j in 1:ncol(pre)) 
                if (correct[[1]][i] != allnames[j])
                    sum = sum + pre[i,j]

        err <- c(err,sum/sum(pre))
    }
    mean(err)
}

rows = -1
s = singleTrain(rows)
print(s)

for (nodes in c(50,100)) {
    rr = distTrain("rr", nodes, rows=rows)
    print(rr)

    shuf = distTrain("shuf", nodes, rows=rows)
    print(shuf)

    even_c= distTrain("even_c", nodes, rows=rows)
    print(even_c)

    uneven_c= distTrain("uneven_c", nodes, rows=rows)
    print(uneven_c)

    plotname = paste(nodes,".jpeg",sep="")
    jpeg(plotname, width=1600, height = 700)


    pNames = c("Standard", "Round Robin", "Shuffle", "Even Class", "Uneven Class")
    barplot(c(s,rr,shuf,even_c,uneven_c), main="Error rates",
            xlab="Partitioning scheme", ylab="% error",
            names.arg=pNames, ylim=c(0,1))
    dev.off()
}
