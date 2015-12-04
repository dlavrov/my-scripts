#!/usr/bin/Rscript
library(ape)
options(warn=-1)
args <- commandArgs(trailingOnly = TRUE)

tree = read.tree(args[1])
x = read.table(args[2])
s = 30

height = function(node){
	h = 0;
	d = tree$edge[which(tree$edge[,1]==node),2]
	if(length(d) == 0){
		#return(0)
		return(node)
	}
	if(length(d[d<=length(tree$tip.label)])==2){
		return(mean(d))
	}else{
		#return(0)
		return(mean(sapply(d,height)))
	}
}

mrca = diag(mrca(tree)[as.vector(x$V1),as.vector(x$V2)])
heights = sapply(mrca,height)

tscale = max(dist.nodes(tree))
pdf(paste(args[2],".pdf",sep=""),width=8,height=7)
#plot(tree, no.margin = T, edge.width = 3, root.edge = T, label.offset = 20)
plot(tree, no.margin = T, edge.width = 3, root.edge = T, label.offset = tscale/40)
symbols(x=node.depth.edgelength(tree)[mrca],y=heights,circles=(tscale/s)*(x$V4/max(c(x$V4,x$V5))),bg="#0000ff55",fg="transparent",inches=F,add=T)
symbols(x=node.depth.edgelength(tree)[mrca],y=heights,circles=(tscale/s)*(x$V5/max(c(x$V4,x$V5))),bg="#0000ff33",fg="transparent",inches=F,add=T)


dev.off()

