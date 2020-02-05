#!/bin/bash

##########
## VARS ##
##########

#jobDir="/tmp/Estimating/Quotes/2020-Quotes/20202002_ThompsonFrontPatio/"
jobDir="$1/"
origBidDocDir="12.OriginalBidDocuments"
origBidDirFQP=$jobDir$origBidDocDir
currYear=$(date | awk '{print $6}')
awardedSalesDir="/tmp/AwardedSalesContracts/"
awardedSalesDirFQP=$awardedSalesDir$currYear

###########
## FUNCS ##
###########

shiftOrig()
{
	if [ -d "$awardedSalesDir" ]; then

		if [ -d $jobDir ]; then

			mv $jobDir $awardedSalesDirFQP

		fi

	fi

}

##########
## MAIN ##
##########

shiftOrig
