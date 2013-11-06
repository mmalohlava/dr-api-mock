#!/usr/local/bin/Rscript
##############################################################################
# Author: Josh Reese                                                         #
# Purdue Univerity Fall 2013                                                 #
# As part of a project to investigate the impact of data distribution in a   #
# distributed random forest algorithm as well as various types of data and   #
# how this will impact on error rates.                                       #
##############################################################################
##############################################################################
#  #
##############################################################################

files = list.files(path='../results/data', recursive=FALSE, full.names=TRUE)

for (f in files) {
    split = strsplit(f,"_")
    type = strsplit(split[[1]][1],"/")[[1]][4]
    size = split[[1]][2]
    sortC = strsplit(split[[1]][3],".",fixed=TRUE)[[1]][1]

    m = read.csv(file=f, header=TRUE, row.names=1)
    plotname = paste("../results/charts/",type,"_",size,"_",sortC,".png",
        sep="")
    png(plotname, width=1200, height = 600)
    
    barplot(as.matrix(m),
            main=paste("Error rates vs Nodes\nChunk Size:",size,"Data:",type),
            xlab="Number of nodes",
            ylab="Error rate", beside=TRUE, cex.names=1.2, cex.axis=1.2,
            cex.lab=1.75, cex.main=2.25, ,
            ylim=c(0,max(m)+0.05))
    dev.off()
}
