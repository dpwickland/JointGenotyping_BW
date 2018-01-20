# JointGenotyping_BW

## Introduction
This workflow performs joint genotyping using GATK on very large numbers of whole-exome gVCFs on the Blue Waters supercomputer. It is designed to conduct joint genotyping on randomly selected subsamplings of various sizes from a larger set of gVCFs. It should be used following single-sample variant calling with GATK HaplotypeCaller.

## Step 1: Randomly select user-specified number of gVCFs from cohort
gVCFs must first be combined into groups because the joint genotyping step can handle no more than a few hundred to perhaps a few thousand files. **Generate_Subsamples_BW.sh** creates a master list of all gVCFs contained within the paths specified by the user. It then splits the master list into smaller files each listing 100 randomly selected gVCFs. The number of gVCFs to select randomly from the master list is determined by an input parameter to the script.

The syntax is *bash Generate_Subsamples_BW.sh \<number of gVCFs to select randomly from master list> <subsample number and aligner used> <path to directory for output> <paths to gVCFs>*

For example:

```
bash Generate_Subsamples_BW.sh 1000 Subsample1_BWA ./Randomized_Subsamplings ./GVCF_group1 ./GVCF_group2 ./GVCF_group3
```

## Step 2: Combine gVCF files (CombineGVCFs_BW.sh)
**CombineGVCFs_BW.sh** uses GATK's CombineGVCFs command to combine the randomly selected gVCFs from the previous step into files containing 100 gVCFs each. CombineGVCFs drastically reduces the number of individual files input to joint genotyping. On Blue Waters, 4 CombineGVCFs commands with a Java heap size of 15g are assigned to each node. Walltime is approximately 5 hours (see scalability analysis).

## Step 3: Jointly genotype samples (GenotypeGVCFs_CatVariants_BW.sh)
This script splits the exon coordinates (.bed) file into 99 sets of 2000 intervals each to facilitate parallel processing. The output is 1 VCF for each 2000-interval set. On Blue Waters, 6 GenotypeGVCFs commands (each covering one interval set) are assigned to each node, for a total of 17 nodes. Walltime increases linearly with batch size; 500 samples takes
30 minutes, whereas 5000 samples takes 6 hours (see scalability analysis).

Following the completion of all GenotypeGVCFs commands, GATK's CatVaraints command is used to combine VCFs from each interval into a single VCF containing variants from all intervals.

## Scalability analysis 
![alt tag](./Scalability_commands.png "Scalability analysis")
