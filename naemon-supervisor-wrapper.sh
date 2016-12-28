#!/usr/bin/env bash

if [[ "$1" = "status" ]]
then
	# We need to return 1 if naemon is not running
	status=$(supervisorctl status naemon)
	echo $status
	grep RUNNING > /dev/null <<< "$status"
else
	supervisorctl "$1" naemon
fi
