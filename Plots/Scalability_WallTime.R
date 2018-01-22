library(scales)
library(RColorBrewer)
png(filename="~/Dropbox/GitHub/JointGenotyping_BW/Plots/Scalability_WallTime.png", 
    units="in", 
    width=10, 
    height=8, res=500)
colours = brewer.pal(n=6, name="Paired")

Batch_sizes <- c(50,100,200,500,1000,2000,5000,10000)

CombineGVCFs <- c(1.87,3.92,4.42,4.42,4.83,4.83,4.83,4.83)
GenotypeGVCFs <- c(0.08,0.12,0.22,0.50,0.99,2.17,6.82,16.17)

par(mar=c(5,5,3,5), xpd=TRUE,lwd=0.5,lend=1)

plot(Batch_sizes,CombineGVCFs ,type='o', col=colours[2], ylab="Walltime (hrs)",
     xlab="Batch size", cex.lab=1.5, cex.axis=1.5,lwd=2, ylim=c(0,20), xlim=c(0,10000), 
     main="Walltime used for 1 subsampling of each batch size", cex.main=1.5)
lines(Batch_sizes,GenotypeGVCFs ,type='o', col=colours[4], lwd=2)

legend(x=000, y=18,  legend=c('CombineGVCFs_BW.sh','GenotypeGVCFs_CatVariants_BW.sh'),col=colours[c(2,4,6)], y.intersp=1.0, x.intersp=0.75, 
       horiz=FALSE, xpd=TRUE, cex=1.25,  lwd=14.5, box.lwd=2, seg.len=1.0)

dev.off()