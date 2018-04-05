#!/bin/bash

##USAGE
#bash VQSR_BW.sh <reference assembly: hg19 or hg38> <desired sensitivty threshold value> <GenotypeGVCFs final VCF directory (MUST QUOTE IF WILDCARDS USED)> 
#bash VQSR_BW.sh hg19 99 "/scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg19/BWA-GATK_HC_defaults/Randomized_Subsamplings/BatchSize50/Subsample*_BWA/final_VCF/GenotypeGVCFs-defaults"


###SET PATHS AND ASSIGN VARIABLES
JAVADIR=/opt/java/jdk1.8.0_51/bin
GATK_PATH=/projects/sciteam/baib/builds/gatk-3.7.0

if [ $1 == "hg19" ];
	then REF=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/human_g1k_v37_decoy.SimpleChromosomeNaming.fasta
	HAPMAP=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/hapmap_3.3.b37.vcf
	OMNI=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/1000G_omni2.5.b37.vcf
	G1000=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/1000G_phase1.snps.high_confidence.b37.vcf
	DBSNP=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/dbsnp_138.b37.vcf
	MILLS=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/Mills_and_1000G_gold_standard.indels.b37.vcf

elif [ $1 == "hg38" ];
	then REF=/projects/sciteam/baib/GATKbundle/Dec3_2017/Homo_sapiens_assembly38.fasta
	HAPMAP=/projects/sciteam/baib/GATKbundle/Dec3_2017/hapmap_3.3.hg38.vcf.gz
	OMNI=/projects/sciteam/baib/GATKbundle/Dec3_2017/1000G_omni2.5.hg38.vcf.gz
	G1000=/projects/sciteam/baib/GATKbundle/Dec3_2017/1000G_phase1.snps.high_confidence.hg38.vcf.gz
	DBSNP=/projects/sciteam/baib/GATKbundle/Dec3_2017/dbsnp_138.hg38.vcf
	MILLS=/projects/sciteam/baib/GATKbundle/Dec3_2017/Mills_and_1000G_gold_standard.indels.hg38.vcf
fi

SENSITIVITY=$2
VCF_PATH=$3

################ VQSR SECTION ################

###CREATE COMMANDS FOR VQSR####
VQSR_commands=0
for vcf in $VCF_PATH/*.vcf; do

	OUT_DIR=`dirname ${vcf}`
	SUBSAMPLE_DIR=$(dirname `dirname ${OUT_DIR}`)
	mkdir -p $SUBSAMPLE_DIR/commands/VQSR/VQSR_`basename ${OUT_DIR}`
	BATCH_DIR=`dirname ${SUBSAMPLE_DIR}`
	
	#desired truth sensitivty / threshold value for each tranche: 100,99.9,99,90

	###FOR SNPS###
	echo "${JAVADIR}/java -Xmx2g -Djava.io.tmpdir=${SUBSAMPLE_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T VariantRecalibrator -R ${REF} -input $vcf -nt 5 -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 -mode SNP -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff -resource:hapmap,VCF,known=false,training=true,truth=true,prior=15.0 ${HAPMAP} -resource:omni,known=false,training=true,truth=true,prior=12.0 ${OMNI} -resource:1000G,known=false,training=true,truth=false,prior=10.0 ${G1000} -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${DBSNP} -recalFile ${OUT_DIR}/`basename ${vcf} .vcf`_recalibrate_SNPs -tranchesFile ${OUT_DIR}/`basename ${vcf} .vcf`_tranches_SNPs -rscriptFile ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_only.plots.R --disable_auto_index_creation_and_locking_when_reading_rods
	
	${JAVADIR}/java -Xmx2g -Djava.io.tmpdir=${SUBSAMPLE_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T ApplyRecalibration -R ${REF} -input $vcf -o ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_only.vcf  -nt 5 -recalFile ${OUT_DIR}/`basename ${vcf} .vcf`_recalibrate_SNPs -tranchesFile ${OUT_DIR}/`basename ${vcf} .vcf`_tranches_SNPs --ts_filter_level ${SENSITIVITY} -mode SNP	

	###FOR INDELS###
	${JAVADIR}/java -Xmx2g -Djava.io.tmpdir=${SUBSAMPLE_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T VariantRecalibrator -R ${REF} -input ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_only.vcf --maxGaussians 4 -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 -mode INDEL -an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff -resource:mills,known=false,training=true,truth=true,prior=12.0 ${MILLS} -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${DBSNP} -recalFile ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_recalibrate_INDELs -tranchesFile ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_tranches_INDELs --disable_auto_index_creation_and_locking_when_reading_rods
	
	${JAVADIR}/java -Xmx2g -Djava.io.tmpdir=${SUBSAMPLE_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T ApplyRecalibration -R ${REF} -input ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_only.vcf -o ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR.vcf  -nt 5 -recalFile ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_recalibrate_INDELs -tranchesFile ${OUT_DIR}/`basename ${vcf} .vcf`_VQSR_SNPs_tranches_INDELs --ts_filter_level ${SENSITIVITY} -mode INDEL" > ${SUBSAMPLE_DIR}/commands/VQSR/VQSR_`basename ${OUT_DIR}`/`basename ${vcf} .vcf`.sh 

	#CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER
	echo "${SUBSAMPLE_DIR}/commands/VQSR/VQSR_`basename ${OUT_DIR}` `basename ${vcf} .vcf`.sh" >> ${BATCH_DIR}/VQSR_`basename ${OUT_DIR}`_joblist_for_aprun
	
	VQSR_commands=$((${VQSR_commands} + 1))
	
	
	done	

NODES=$(((${VQSR_commands} + 1)/2)) 
n_for_aprun=$((${VQSR_commands} + 1))

###CREATE APRUN SCRIPT FOR BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=${NODES}:ppn=32:xe
#PBS -l walltime=4:00:00
#PBS -N VQSR_${1}_`basename ${BATCH_DIR}`_`basename ${OUT_DIR}`
#PBS -o ${BATCH_DIR}/VQSR_`basename ${OUT_DIR}`.stdout
#PBS -e ${BATCH_DIR}/VQSR_`basename ${OUT_DIR}`.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n $n_for_aprun -N 2 -d 16 /projects/sciteam/baib/builds/Scheduler/scheduler.x ${BATCH_DIR}/VQSR_`basename ${OUT_DIR}`_joblist_for_aprun /bin/bash > ${BATCH_DIR}/VQSR_`basename ${OUT_DIR}`_log_aprun.txt" > ${BATCH_DIR}/run_aprun_VQSR_`basename ${OUT_DIR}`

################ BEGIN! ################

qsub ${BATCH_DIR}/run_aprun_VQSR_`basename ${OUT_DIR}`
