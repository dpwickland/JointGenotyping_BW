#!/bin/bash

##USAGE
#bash CombineGVCFs_BW.sh <reference assembly to use: hg19 or hg38> <subsample directory containing samples_list directory generated by Generate_Subsamples_BW.sh; this will also be the output directory for this script>
#bash CombineGVCFs_BW.sh hg38 /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg38/BWA-GATK_HC_defaults/Randomized_Subsamplings/BatchSize50/Subsample1_BWA

###SET PATHS AND ASSIGN VARIABLES
JAVADIR=/opt/java/jdk1.8.0_51/bin
GATK_PATH=/projects/sciteam/baib/builds/gatk-3.7.0

if [ $1 == "hg19" ];
	then REF=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/human_g1k_v37_decoy.SimpleChromosomeNaming.fasta
elif [ $1 == "hg38" ];
	then REF=/projects/sciteam/baib/GATKbundle/Dec3_2017/Homo_sapiens_assembly38.fasta
fi

OUT_DIR=$2
mkdir $OUT_DIR/tmp
mkdir $OUT_DIR/logs
mkdir $OUT_DIR/commands
mkdir $OUT_DIR/commands/CombineGVCFs
mkdir $OUT_DIR/aprun_joblists
mkdir $OUT_DIR/combined_GVCFs

################ COMBINE VCFS SECTION ################

###CREATE COMMANDS FOR COMBINE GVCFs####
 for sample_list in $OUT_DIR/samples_lists/*.list;
	do
		echo "${JAVADIR}/java -Xmx15g -Djava.io.tmpdir=${OUT_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T CombineGVCFs -R ${REF} -V $sample_list -o ${OUT_DIR}/combined_GVCFs/CombineGVCFs_`basename $sample_list .list`.g.vcf  --disable_auto_index_creation_and_locking_when_reading_rods" > ${OUT_DIR}/commands/CombineGVCFs/CombineGVCFs_`basename $sample_list .list`.sh 
	done	

###CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER  
CombineGVCFs_commands=0
for file in $OUT_DIR/commands/CombineGVCFs/*.sh; do  CombineGVCFs_commands=$((${CombineGVCFs_commands} + 1)); echo $OUT_DIR/commands/CombineGVCFs/ `basename ${file}` >> $OUT_DIR/aprun_joblists/CombineGVCFs_joblist_for_aprun;done;

CMNDS_PER_NODE=4
NODES=$(((${CombineGVCFs_commands} + ${CMNDS_PER_NODE})/${CMNDS_PER_NODE})) 
n_for_aprun=$((${CombineGVCFs_commands} + 1))

###CREATE APRUN SCRIPT FOR BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=${NODES}:ppn=32:xe
#PBS -l walltime=7:00:00
#PBS -N CombineGVCFs_${1}_`basename $(dirname ${OUT_DIR})`_`basename ${OUT_DIR}`
#PBS -o ${OUT_DIR}/logs/CombineGVCFs.stdout
#PBS -e ${OUT_DIR}/logs/CombineGVCFs.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n $n_for_aprun -N ${CMNDS_PER_NODE} -d $((32/${CMNDS_PER_NODE})) /projects/sciteam/baib/builds/Scheduler/scheduler.x ${OUT_DIR}/aprun_joblists/CombineGVCFs_joblist_for_aprun /bin/bash > ${OUT_DIR}/logs/CombineGVCFs_log_aprun.txt" > ${OUT_DIR}/run_aprun_CombineGVCFs

################ BEGIN! ################

qsub ${OUT_DIR}/run_aprun_CombineGVCFs
