#!/bin/bash
#
# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of tool chain https://github.com/igorpecovnik/lib
#
#--------------------------------------------------------------------------------------------------------------------------------

# DO NOT EDIT THIS FILE
#
# Please use config-default.conf to set a default configuration
# and create other config files, i.e. config-myoptions.conf
# that can be used with ./compile.sh myoptions
#
# this file (compile.sh) and config-example.conf will be updated with other build scripts

if [[ $EUID != 0 ]]; then
	echo -e "[\e[0;35m warn \x1B[0m] This script requires root privileges, trying to use sudo"
	sudo "$0" "$@"
	exit $?
fi

# source is where compile.sh is located
SRC=$(realpath ${BASH_SOURCE%/*})
# fallback for Trusty
[[ -z $SRC ]] && SRC=$(pwd)
cd $SRC
#--------------------------------------------------------------------------------------------------------------------------------
# Get updates of the main build libraries
#--------------------------------------------------------------------------------------------------------------------------------
[[ $(dpkg-query -W -f='${db:Status-Abbrev}\n' git 2>/dev/null) != *ii* ]] && \
	apt-get -qq -y --no-install-recommends install git

if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true && \
				$(git rev-parse --show-toplevel) == $(SRC) ]]; then
	# already set up, try to update
	if [[ ! -f $SRC/.ignore_changes ]]; then
		echo -e "[\e[0;32m o.k. \x1B[0m] This script will try to update"
		git pull
		CHANGED_FILES=$(git diff --name-only)
		if [[ -n $CHANGED_FILES ]]; then
			echo -e "[\e[0;35m warn \x1B[0m] Can't update since you made changes to: \e[0;32m\n${CHANGED_FILES}\x1B[0m"
			echo -e "Press \e[0;33m<Ctrl-C>\x1B[0m to abort compilation, \e[0;33m<Enter>\x1B[0m to ignore and continue"
			read
		else
			git checkout ${LIB_TAG:- master}
		fi
	fi
else
	echo "Please pull the repository manually"
fi

if [[ ! -f $SRC/config-default.conf ]]; then
	cp $SRC/config-example.conf $SRC/config-default.conf
fi

# source additional configuration file
if [[ -n $1 && -f $SRC/config-$1.conf ]]; then
	echo "using config-$1.conf"
	source $SRC/config-$1.conf
else
	echo "using config-default.conf"
	source $SRC/config-default.conf
fi

# daily beta build contains date in subrevision
if [[ $BETA == yes ]]; then SUBREVISION="."$(date --date="tomorrow" +"%y%m%d"); fi

if [[ $BUILD_ALL == yes || $BUILD_ALL == demo ]]; then
	source $SRC/lib/build-all.sh
else
	source $SRC/lib/main.sh
fi

# hook for function to run after build, i.e. to change owner of $SRC
# NOTE: this will run only if there were no errors during build process
[[ $(type -t run_after_build) == function ]] && run_after_build || true

# If you are committing new version of this file, increment VERSION
# Only integers are supported
# VERSION=26
