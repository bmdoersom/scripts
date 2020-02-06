#!/bin/bash

##########
## VARS ##
##########

jobDir="$1/"
origBidDocDir="12.OriginalBidDocuments"
origBidDirFQP=$jobDir$origBidDocDir
currYear=$(date | awk '{print $6}')
awardedSalesDir="AwardedSalesContracts/$currYear"

###########
## FUNCS ##
###########

compileOrigBidDir() 
{

	if [ -d $origBidDirFQP ]; then

		for i in $(ls $jobDir); do
			
			if [[ $i != "12.OriginalBidDocuments" ]]; then

				myDir=$jobDir$i
				mv $myDir $origBidDirFQP

			fi

		done

	fi

}

##########
## MAIN ##
##########

compileOrigBidDir
