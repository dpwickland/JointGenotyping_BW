#!/bin/bash

##USAGE
#bash Generate_Subsamples_BW.sh <number of samples to use> <subsample and aligner (e.g. Subsample1_BWA)> <path to directory for output> <paths to GVCFs>

##EXAMPLE COMMAND FOR NOVOALIGN-GATK_HC GVCFS, hg19
#bash Generate_Subsamples_BW.sh 350 Subsample1_Novoalign /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg38/Novoalign-GATK_HC_defaults/Randomized_Subsamplings /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch1.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch2.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch3.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch4.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch5.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch6.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch7.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch8.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch9.Novoalign_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/Novoalign/GATK_HC/ADSP_Batch10.Novoalign_GATK_defaults

##EXAMPLE COMMAND FOR BWA-GATK_HC GVCFS, hg38
#bash Generate_Subsamples_DW_1-16.sh 4 Subsample4_BWA /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_JointGenotyping/hg38/BWA-GATK_HC_defaults/Randomized_Subsamplings /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch1.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch2.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch3.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch4.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch5.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch6.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch7.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch8.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch9.BWA_GATK_defaults /scratch/sciteam/jacobrh/purge_exempt/ADSP_VarCallResults/ADSP_SingleSampleVC/hg38/BWA/GATK_HC/ADSP_Batch10.BWA_GATK_defaults

###ASSIGN VARIABLES
i=1
for argument in "$@";
        do
                if [ "$i" == 1 ];
                        then BATCH_SIZE=$argument
                elif [ "$i" == 2 ];
                        then SUBSAMPLE_ALIGNER=$argument
		elif [ "$i" == 3 ];
                        then OUT_DIR_ROOT=$argument
                elif [ "$i" -ge 4 ];
                        #CONSTRUCT ARRAY LISTING ALL VCFS IN $BATCH_SIZE NUMBER OF DIRECTORY/DIRECTORIES
                        then POOLED_VCFs=(${POOLED_VCFs[@]} $argument/*delivery/SRR*/*g.vcf)
                fi
        i=$((i+1))
        done;

###CREATE DIRECTORIES
if [ ! -d $OUT_DIR_ROOT/BatchSize${BATCH_SIZE} ]; 
	then mkdir $OUT_DIR_ROOT/BatchSize${BATCH_SIZE} 
fi

OUT_DIR=$OUT_DIR_ROOT/BatchSize${BATCH_SIZE}/${SUBSAMPLE_ALIGNER} 
mkdir $OUT_DIR
mkdir $OUT_DIR/samples_lists

###SHUFFLE ARRAY LISTING ALL VCFs
for vcf in `seq 0 ${#POOLED_VCFs[*]} | shuf` #length of POOLED_VCFs array
do
        POOLED_VCFs_SHUFFLED+=(${POOLED_VCFs[$vcf]})
done

###CREATE ARRAY CONTAINING BATCH_SIZE NUMBER OF SAMPLES
POOLED_VCFs_SHUFFLED_BATCH_SIZE=(${POOLED_VCFs_SHUFFLED[@]:0:$BATCH_SIZE}) 

###DIVIDE ARRAY INTO BATCHES OF 100 (OR JUST 1 BATCH IF SAMPLE SIZE <100)####
if [[ $BATCH_SIZE -lt 100 ]];then 
	BATCH_MIN=0
	BATCH_MAX=${BATCH_SIZE}
	for ((j=$BATCH_MIN;j<${BATCH_MAX};j++))
  		do
                	echo ${POOLED_VCFs_SHUFFLED_BATCH_SIZE[$j]} >> $OUT_DIR/samples_lists/BatchSize${BATCH_SIZE}_${SUBSAMPLE_ALIGNER}_${BATCH_MIN}_to_${BATCH_MAX}.list
               	done
		
elif [[ $BATCH_SIZE -ge 100 ]]; then 
	for ((i=1;i<=${BATCH_SIZE}/100;i++))
 		do 
			BATCH_MIN=( $(($i - 1))"00" )
			BATCH_MAX=( $i"00" )
			for ((j=$BATCH_MIN;j<${BATCH_MAX};j++))
				do 
					echo ${POOLED_VCFs_SHUFFLED_BATCH_SIZE[$j]} >> ${OUT_DIR}/samples_lists/BatchSize${BATCH_SIZE}_${SUBSAMPLE_ALIGNER}_${BATCH_MIN}_to_${BATCH_MAX}.list
				done					
				
		if [[ $i -eq ${BATCH_SIZE}/100 ]];then
			BATCH_MIN=( $((${BATCH_SIZE}/100*100)) )
			BATCH_MAX=( $((${BATCH_SIZE}%100 + ${BATCH_SIZE}/100*100)) )	
			for ((j=$BATCH_MIN;j<${BATCH_MAX};j++))
                do
                    echo ${POOLED_VCFs_SHUFFLED_BATCH_SIZE[$j]} >> ${OUT_DIR}/samples_lists/BatchSize${BATCH_SIZE}_${SUBSAMPLE_ALIGNER}_${BATCH_MIN}_to_${BATCH_MAX}.list       
                done	 
		fi
		done
fi
