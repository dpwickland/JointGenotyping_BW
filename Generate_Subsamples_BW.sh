#!/bin/bash

##USAGE
#bash Generate_Subsamples_BW.sh <number of GVCFs to select randomly from master list> <subsample number followed by underscore and aligner used> <path to root directory for output>  <paths to GVCFs>

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
