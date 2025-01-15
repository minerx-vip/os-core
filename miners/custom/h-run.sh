#!/usr/bin/env bash

# echo "Exec: /os/miners/custom/h-run.sh"

## ps aux | grep /os/miners/custom/aleo_prover/h-run.sh | grep -v grep
ps aux | grep "$MINER_DIR/$CUSTOM_MINER/h-run.sh" | grep -v grep


[[ `ps aux | grep "$MINER_DIR/$CUSTOM_MINER/h-run.sh" | grep -v grep | wc -l` != 0 ]] &&
	echo -e "${RED}$MINER_NAME $CUSTOM_MINER miner is already running${NOCOLOR}" &&
	exit 1

## /os/miners/custom/aleo_prover
cd $MINER_DIR/$CUSTOM_MINER

## /os/miners/custom/aleo_prover/h-run.sh
[[ ! -f $MINER_DIR/$CUSTOM_MINER/h-run.sh ]] &&
	echo "${RED}$MINER_DIR/$CUSTOM_MINER/h-run.sh is not implemented${NOCOLOR}" &&
	exit 1


## /os/miners/custom/aleo_prover/h-run.sh
# echo "'$MINER_DIR/$CUSTOM_MINER/h-run.sh' = $MINER_DIR/$CUSTOM_MINER/h-run.sh"
$MINER_DIR/$CUSTOM_MINER/h-run.sh
