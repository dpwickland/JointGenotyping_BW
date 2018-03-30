#!/bin/bash

##USAGE
#bash GenotypeGVCFs_BW.sh <which reference assembly to use: hg19 or hg38> <title to use for output directory; typically any special GenotypeGVCFs parameters used> <path to combined GVCFs> <path to Delivery directory for final VCF output>
#bash GenotypeGVCFs_CatVariants_BW.sh hg38 defaults /mnt/c/scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg38/BWA-GATK_HC_defaults/Randomized_Subsamplings/BatchSize50/Subsample1_BWA/combined_GVCFs /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg38/BWA-GATK_HC_defaults/GenotypeGVCFs_Delivery

###SET PATHS AND ASSIGN VARIABLES
JAVADIR=/opt/java/jdk1.8.0_51/bin
GATK_PATH=/projects/sciteam/baib/builds/gatk-3.7.0

if [ $1 == "hg19" ];
	then REF=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/human_g1k_v37_decoy.SimpleChromosomeNaming.fasta
		PATH_TO_BEDS=/projects/sciteam/baib/GATKbundle/July1_2017/exon_intervals_bed/
elif [ $1 == "hg38" ];
	then REF=/projects/sciteam/baib/GATKbundle/Dec3_2017/Homo_sapiens_assembly38.fasta
		PATH_TO_BEDS=/projects/sciteam/baib/GATKbundle/Dec3_2017/exon_intervals_bed/
fi

i=1
for argument in "$@";
        do         	
		if [ "$i" == 2 ];
                        then GENOTYPEGVCFS_SETTING=$argument
                elif [ "$i" == 3 ];
                        then PATH_TO_COMBINED_GVCFS=$argument
		elif [ "$i" == 4 ];
			then DELIVERY=$argument
                fi
        i=$((i+1))
        done;

OUT_DIR=`dirname ${PATH_TO_COMBINED_GVCFS}`
SUBSAMPLE=`basename ${OUT_DIR}`
BATCH_SIZE=`basename $(dirname ${OUT_DIR})`

###CREATE DIRECTORIES
if [ ! -d ${OUT_DIR}/commands/GenotypeGVCFs ]; 
	then mkdir ${OUT_DIR}/commands/GenotypeGVCFs 
fi

if [ ! -d ${OUT_DIR}/interval_VCFs ]; 
	then mkdir ${OUT_DIR}/interval_VCFs 
fi

if [ ! -d ${OUT_DIR}/commands/CatVariants ]; 
	then mkdir ${OUT_DIR}/commands/CatVariants 
fi

if [ ! -d ${OUT_DIR}/final_VCF ]; 
	then mkdir ${OUT_DIR}/final_VCF 
fi

if [ ! -d ${DELIVERY} ]; 
	then mkdir ${DELIVERY} 
fi

if [ ! -d ${DELIVERY}/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING} ]; 
	then mkdir ${DELIVERY}/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING} 
fi

mkdir ${OUT_DIR}/commands/GenotypeGVCFs/${GENOTYPEGVCFS_SETTING}
mkdir ${OUT_DIR}/interval_VCFs/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}
mkdir ${OUT_DIR}/final_VCF/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}

################ GENOTYPEGVCFS SECTION ################

###CREATE SCRIPTS TO RUN GENOTYPEGVCFS ON EACH COMBINED GVCF
for GVCF in ${PATH_TO_COMBINED_GVCFS}/*g.vcf
do
	GVCFS_LIST="${GVCFS_LIST} --variant ${GVCF}"   
done
	
for bed in ${PATH_TO_BEDS}/*.bed
	do
		INTERVAL=`basename $bed | sed 's/\.bed//g'`
		echo "${JAVADIR}/java -Xmx10g -Djava.io.tmpdir=${OUT_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T GenotypeGVCFs -R ${REF} ${GVCFS_LIST} -o ${OUT_DIR}/interval_VCFs/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}/GenotypeGVCFs_${INTERVAL}.vcf -L $bed --disable_auto_index_creation_and_locking_when_reading_rods"  >> ${OUT_DIR}/commands/GenotypeGVCFs/${GENOTYPEGVCFS_SETTING}/${INTERVAL}.sh
	done

###CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER 
GenotypeGVCFs_commands=0
for file in ${OUT_DIR}/commands/GenotypeGVCFs/${GENOTYPEGVCFS_SETTING}/interval*.sh; do GenotypeGVCFs_commands=$((${GenotypeGVCFs_commands} + 1)); echo ${OUT_DIR}/commands/GenotypeGVCFs/${GENOTYPEGVCFS_SETTING}/ `basename $file` >> ${OUT_DIR}/aprun_joblists/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_joblist_for_aprun;done;

###CREATE APRUN SCRIPT FOR BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=17:ppn=32:xe
#PBS -l walltime=7:00:00
#PBS -N GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_${1}_${BATCH_SIZE}_${SUBSAMPLE}
#PBS -o ${OUT_DIR}/logs/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.stdout
#PBS -e ${OUT_DIR}/logs/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n 102 -N 6 -d 5 /projects/sciteam/baib/builds/Scheduler/scheduler.x ${OUT_DIR}/aprun_joblists/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_joblist_for_aprun /bin/bash > ${OUT_DIR}/logs/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_log_aprun.txt

qsub ${OUT_DIR}/run_aprun_CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}" > ${OUT_DIR}/run_aprun_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}


################ CATVARIANTS SECTION ################

###COMBINE VCFS FROM GENOTYPEGVCFS (IN ORDER)
echo 'for VCF in `ls -v '${OUT_DIR}'/interval_VCFs/GenotypeGVCFs-'${GENOTYPEGVCFS_SETTING}'/*.vcf`
do
	VCFS_LIST="${VCFS_LIST} --variant ${VCF}"   
done

'${JAVADIR}'/java -Xmx32g -cp '${GATK_PATH}'/GenomeAnalysisTK.jar org.broadinstitute.gatk.tools.CatVariants -R '${REF}' ${VCFS_LIST} -out '${OUT_DIR}'/final_VCF/GenotypeGVCFs-'${GENOTYPEGVCFS_SETTING}'/'${BATCH_SIZE}'_'${SUBSAMPLE}'_GenotypeGVCFs-'${GENOTYPEGVCFS_SETTING}'_all_exome_intervals_'${1}'.vcf -assumeSorted

###SET PERMISSSIONS
chmod g+rx '$OUT_DIR'
chmod g+rx '${OUT_DIR}'/samples_lists' >> ${OUT_DIR}/commands/CatVariants/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.sh

###CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER 
echo "${OUT_DIR}/commands/CatVariants/ CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.sh" >> ${OUT_DIR}/aprun_joblists/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_joblist_for_aprun

###CREATE APRUN SCRIPT BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=1:ppn=32:xe
#PBS -l walltime=4:00:00
#PBS -N CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_${1}_${BATCH_SIZE}_${SUBSAMPLE}
#PBS -o ${OUT_DIR}/logs/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.stdout
#PBS -e ${OUT_DIR}/logs/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n 2 /projects/sciteam/baib/builds/Scheduler/scheduler.x ${OUT_DIR}/aprun_joblists/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_joblist_for_aprun /bin/bash > ${OUT_DIR}/logs/CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_log_aprun.txt

grep -v ^## ${OUT_DIR}/final_VCF/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}/${BATCH_SIZE}_${SUBSAMPLE}_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_all_exome_intervals_${1}.vcf | sed 's/chr//g' > ${DELIVERY}/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}/${BATCH_SIZE}_${SUBSAMPLE}_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_all_exome_intervals_${1}.vcf

chmod g+rx ${DELIVERY}/GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}/${BATCH_SIZE}_${SUBSAMPLE}_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}_all_exome_intervals_${1}.vcf" > ${OUT_DIR}/run_aprun_CatVariants_on_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}

################ BEGIN! ################

qsub ${OUT_DIR}/run_aprun_GenotypeGVCFs-${GENOTYPEGVCFS_SETTING}


