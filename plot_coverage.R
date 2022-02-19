#!/usr/local/bin/Rscript
## plota.R
library(tidyverse)
x <- read.table("coverage_table")
x$coverage <- apply(x[,3:6],1,sum)
#jpeg('rplot.jpg')
ggplot(data = x) + geom_point(mapping = aes(x=V2, y=diversity)

plot(x$V2,x$coverage,type="l")
#dev.copy(png,'myplot.png')
#dev.off()
