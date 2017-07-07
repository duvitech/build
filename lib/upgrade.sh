#!/bin/bash

if [[ $(basename $0) == main.sh ]]; then
	echo "Please use compile.sh to start the build process"
	exit -1
fi

if [[ $(basename $0) == compile.sh ]]; then
	dialog
fi