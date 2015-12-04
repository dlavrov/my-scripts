# first we might need to install a couple packages
if(! is.element("rgl", installed.packages()[,1]))
	install.packages("rgl")
if(! is.element("ca", installed.packages()[,1]))
	install.packages("ca")
library(ca)

# Get the Data
x = read.table("/research/projects/Sponges/Molecuclar_clock/2012_analysis/support_files/71taxa.txt",header=TRUE)
aa = c("A","C","D","E","F","G","H","I","K","L","M","N","P","Q","R","S","T","V","W","Y")
pdf("coa.pdf",width=10, height=10)						# open a pdf for printing plots

col_names = names(x)
N = x[,2:length(col_names)]			# get data without first column


# Correspondence analysis #

coa = ca(N)						# perform correspondence analysis
p = data.frame(coa$colcoord[,1:2])	# get unscaled principal coordinates
p$name = substr(summary(coa)$columns$name,0,2)	# add names to a column
#plot(coa,what=c("none","active"))	# default plot from CA package

# The default plot is okay, but we can do better
# make an empty plot so we can add our own pretty data points
plot(NULL,xlim=c(min(p$X1),max(p$X1)),
		ylim=c(min(p$X2),max(p$X2)),
		xlab="PC 1",ylab="PC 2",
		cex.lab=1.3,cex.axis=1.3)
chars = c(23,25,15,17,16,8,19,24,25,26,6,15,15,17,22,17,17,6,17,8,19)	# list of data point symbols
colors = c("black","black","orange","blue","red","green","violet")

up = unique(p$name)
for(i in 1:length(up)){
	d = subset(p,name==up[i])			# data subset for 1 organism
	points(x=d$X1,y=d$X2,pch=chars[i],cex=1.5, col=colors[i])	# add points 1 organism
}

legend("topright",cex=1.3,legend=up,pch=chars,col=colors)	# make a legend

# make a barplot of the inertia of each amino acid
# i.e. the contribution of each amino acid to the overall variance
barplot(-sort(-coa$rowinertia),
		names=aa[order(-coa$rowinertia)],
		ylab="Inertia",
		cex.names=1.4,cex.lab=1.5,cex.axis=1.3)
Nt = data.frame(t(N))					# transpose data
Nt$org = substr(rownames(Nt),0,2)		# get organism headers
orgs = unique(Nt$org)					# get unique organism names

par( mfrow = c( 2, 2 ) )


# AA composition boxplots

#ord = x$Cat[order(-coa$rowinertia)]		# sort amino acids by inertia
#for(i in 1:length(ord)){
	# boxplot for each amino acid
	#boxplot(Nt[,which(x$Cat==ord[i])]~Nt$org,main=ord[i])
#}

dev.off()
