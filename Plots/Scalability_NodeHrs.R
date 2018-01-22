library(scales)
library(RColorBrewer)
png(filename="~/Dropbox/GitHub/JointGenotyping_BW/Plots/Scalability_NodeHrs.png", 
    units="in", 
    width=10, 
    height=8, res=500)
colours = brewer.pal(n=6, name="Paired")

Batch_sizes <- c(50,100,200,500,1000,2000,5000,10000)

CombineGVCFs <- c(1.87,3.92,4.42,8.84,14.49,28.98,62.79,125.58)
GenotypeGVCFs <- c(1.19,1.87,3.4,7.82,15.64,34,104.89,257.89)

par(mar=c(5,5,3,5), xpd=TRUE,lwd=0.5,lend=1)

plot(Batch_sizes,CombineGVCFs ,type='o', col=colours[2], ylab="Node hours",
     xlab="Batch size", cex.lab=1.5, cex.axis=1.5,lwd=2, ylim=c(0,250), xlim=c(0,10000), 
     main="Node hours used for 1 subsampling of each batch size", cex.main=1.5)
lines(Batch_sizes,GenotypeGVCFs ,type='o', col=colours[4], lwd=2)

legend(x=000, y=225,  legend=c('CombineGVCFs_BW.sh','GenotypeGVCFs_CatVariants_BW.sh'),col=colours[c(2,4,6)], y.intersp=1.0, x.intersp=0.75, 
       horiz=FALSE, xpd=TRUE, cex=1.25,  lwd=14.5, box.lwd=2, seg.len=1.0)

dev.off()