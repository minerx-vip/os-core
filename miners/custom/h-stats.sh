#!/usr/bin/env bash


if [[ -z $CUSTOM_MINER ]]; then
	echo -e "${RED}\$CUSTOM_MINER is not defined_linshi_3${NOCOLOR}"
else
	if [[ ! -f $MINER_DIR/$CUSTOM_MINER/h-stats.sh ]]; then
		echo "${RED}$MINER_DIR/$CUSTOM_MINER/h-stats.sh is not implemented${NOCOLOR}"
	else
		source $MINER_DIR/$CUSTOM_MINER/h-stats.sh
	fi
fi
