#!/bin/bash

#############################
## Configuration variables ##
#############################

### Source tree directory ###
SRC_DIR=`pwd`

### Destination tree directory ###
DEST_DIR=../xsltwraplib-enc

### Encoder placement ###
# This should be the path to your zendenc binary.
ZEND_ENC=/usr/local/Zend/zendenc

# Options for packing source (insert commands for skipping extra files here)
TAR_OPTIONS="--exclude=OLD --exclude=*~ --exclude=CVS --exclude=.?* --exclude=np --exclude=.cvsignore --exclude=encode.sh --exclude=config.h"

# List of extensions of files to compile
PHP_EXTENSIONS="php inc php3 handler library element xmlrpchandler"

# Where to place error log
ERROR_LOG=/tmp/zend_encoder_errors.log

###############################################
## No user-serviceable parts beyond this point
###############################################

echo "Zend Encoder Conversion Utility v1.0.0"
echo ""

CLEAN=0
ALL=0

VERBOSE_TAR=""
VERBOSE_ENC="--silent"

WHERE=`pwd`

usage () {
(
	echo "USAGE:"
	echo 
	echo "To rebuild files/directories:"
	echo 
	echo "	$0 [-c] [-v] file1 file2 ..."
	echo
	echo "To rebuild current directory:"
	echo 
	echo "	$0 [-c] [-v]"
	echo 
	echo "To rebuild entire source tree:"
	echo 
	echo "	$0 [-c] [-v] -a"
	echo
	echo "-c	Clean (erase) existing files first"
	echo "-v[v]	Increase verbosity"
	echo "-h	Get help"
	echo "-s dir	Set source directory" 
	echo "-d dir	Set destination directory" 
	echo 
) >& 2
}


dodir() {

	if [ $CLEAN -eq 1 ]
	then
		echo "Cleaning up destination directory first ... "
		cd $dest
		rm -rf *
	fi

	echo "Copying source files ..."
	(cd $src ; tar $TAR_OPTIONS -cpf - .) | ( cd $dest ; tar xpf$VERBOSE_TAR -)

	echo "Compiling files ..."
	cd $dest

	find_command=""
	for ext in $PHP_EXTENSIONS; do
		find_command="$find_command ${find_command:+"-o"} -name \*.$ext"
	done

	find_command="find . $find_command"

	sh -c "$find_command" | xargs -n1 $ZEND_ENC $VERBOSE_ENC --delete-source 2>>$ERROR_LOG
}


dofile() {

	echo "Copying source file $src ..."
	cp -f $src $dest


	echo "Compiling destination file $dest ..."
	$ZEND_ENC $VERBOSE_ENC --delete-source $dest 2>>$ERROR_LOG

}




finished() {

	cd $WHERE
	touch $DEST_DIR/.encoded

	if [ -s $ERROR_LOG ]
	then
		echo
		echo "There were errors during compilation!"
		echo "Please see $ERROR_LOG for error messages."
	fi
	echo "Done!"
	exit 0

}




while getopts acvhs:d: flag
do
	case "$flag" in
	a)
		ALL=1;;
	c)
		CLEAN=1;;
	v)
		if [ "x$VERBOSE2" != 'x' ]; then
			VERBOSE_TAR="v"
			VERBOSE_ENC=""
		else
			VERBOSE2="yes"
			VERBOSE_TAR="v"
			VERBOSE_ENC="--quiet"
		fi
		;;
	s)
		SRC_DIR=$OPTARG
		;;
	d)
		DEST_DIR=$OPTARG
		;;
	?)	
		#echo "Flag unknown"
		echo
		usage
		exit 1;;
	esac
done

# Ensure that we have all the necessary information
UNCONFIGURED=0
if [ "$SRC_DIR" = "" ]; then
	echo "* Please set the Source Directory (SRC_DIR)," >&2
	echo "  e.g. - /home/johndoe/scripts" >&2
	UNCONFIGURED=1
fi

if [ "$DEST_DIR" = "" ]; then
	echo "* Please set the Destination Directory (DEST_DIR)," >&2
	echo "  e.g. - /home/httpd/html/scripts" >&2
	UNCONFIGURED=1
fi

if [ ! -f $ZEND_ENC ]; then
	echo "* Could not find the Zend Encoder in $ZEND_ENC" >&2
	echo "  Please set the path to the Zend Encoder binary (ZEND_ENC)" >&2
	UNCONFIGURED=1
fi

if [ $UNCONFIGURED -eq 1 ]; then
	exit 1
fi



# Strip trailing /

SRC_DIR=`echo $SRC_DIR | sed -e 's/\/$//g'`
DEST_DIR=`echo $DEST_DIR | sed -e 's/\/$//g'`

parts=$[`echo $SRC_DIR |  sed -e 's/ /_/g' -e 's/\// /g' | wc -w | sed -e 's/ //g'`+1]

shift `expr $OPTIND - 1`

# Check setup first

if [ ! -d $SRC_DIR ]
then
	echo "Base source directory $SRC_DIR does not exist." >&2
	exit 1
fi

if [ -f $DEST_DIR ]
then
	echo "Base destination $DEST_DIR exists and is a regular file." >&2
	exit 1
fi

# Error log
rm $ERROR_LOG
touch $ERROR_LOG

if [ ! -f $ERROR_LOG ]
then
	echo "Cannot create erro log: $ERROR_LOG." >&2
	exit 1
fi

if [ ! -d $DEST_DIR ]
then
	echo "Making base directory $DEST_DIR ..."
	mkdir $DEST_DIR
fi


if [ $ALL -eq 1 ]
then

	echo "Processing entire source directory ..."

	if [ $# -ne 0 ]
	then
		echo "Ignoring files given on command line" >&2
	fi

	src="$SRC_DIR/"
	dest="$DEST_DIR/"
	dodir
	finished

else

	test=`pwd | cut -d "/" -f-$parts`
	if [ "$test" != "$SRC_DIR" ]
	then
		echo "You aren't in the source tree ($SRC_DIR,$test)" >&2
		exit 1
	fi

	BASE=`pwd | cut -d "/" -f$[$parts+1]-`

	# Check if you are just doing entire current directory

	if [ $# -eq 0 ]
	then
		echo "Processing directory $BASE ..."
		src="$SRC_DIR/$BASE/"
		dest="$DEST_DIR/$BASE/"
		dodir
		finished
	fi

	# Otherwise you are doing one or more files/dirs

	while [ $# -gt 0 ]
	do

		if [ -f $1 ]
		then
			echo "Processing file $BASE/$1 ..."
			src="$SRC_DIR/$BASE/$1"
			dest="$DEST_DIR/$BASE/$1"
			dofile

		elif [ -d $1 ]
		then
			src="$SRC_DIR/$BASE/$1/"
			dest="$DEST_DIR/$BASE/$1/"
			echo "Processing directory $BASE/$1/ ..."
			dodir

		else
			echo "Skipping $BASE/$1 (not a file or directory) ..." >&2

		fi

		shift
	done
    	finished

fi

