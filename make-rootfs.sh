#!/bin/bash

START_MINUTE=$(date "+%H*60+%M" | bc )


. 0-check-and-set.sh $1 $2
. 1-create-rootfs.sh
. 2-configure-rootfs.sh
. 3-archive-rootfs.sh


echo "Time elapsed: $(($(date "+%H*60+%M" | bc )-$START_MINUTE)) minutes"

