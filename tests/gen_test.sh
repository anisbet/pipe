#!/bin/bash
###
#
# Product: pipe.pl
# Purpose: Generates test cases for pipe.pl flags.
#
# Copyright (c) Andrew Nisbet 2022.
# All code covered by the project's license.
#
###

### Global variables
# Set this false if you want to keep the scratch files.
KEEP_TEMP_FILES=false
ADD_TO_MAKE=true
MAKE_FILE=./Makefile
TEMPLATE=test-template.sh
TEST_SPECIFICATION=''
VERSION="1.2.00"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $0 [flags]
Create a test script for an arbitrary but specific pipe.pl flag.

Flags:

-f, -flag, --flag{flag}: Set the pipe.pl flag to be tested. Required.
-h, -help, --help: This help message.
-m, -make, --make{true|false}: Add script to Makefile or not. Default true.
-s, -spec-file, --spec-file={/foo/bar}: Specification file which defines tests.
-v, -version, --version: Print application version and exits.

 Example:
    ${0} --flag=t
EOFU!
}


### Parameter handling
### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "flag:,help,make:,spec-file:,version" -o "f:hm:s:v" -a -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
    case $1 in
    -f|--flag)
        # Set a unique log file.
        shift
        export TEST_FLAG="$1"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -m|--make)
        # Add script to Makefile or not
        shift
        export ADD_TO_MAKE=$1
        ;;
    -s|--spec-file)
        # Add script to Makefile or not
        shift
        export TEST_SPECIFICATION="$1"
        if [ ! -f "$TEST_SPECIFICATION" ]; then echo "-s called, but no specification file found, exiting."; exit 1; fi
        ;;
    -v|--version)
        echo "$0 version: $VERSION"
        exit 0
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done
# Test for required -f flag.
: ${TEST_FLAG:?Missing -f,--flag}
export TEST_FILE="test-${TEST_FLAG}.sh"
if [ -f "$TEST_FILE" ]; then
    echo "**error, test $TEST_FILE already exists, exiting."
    exit 1
fi
if [ -s "$TEMPLATE" ]; then
    if [ -f "$TEST_SPECIFICATION" ]; then
        awk -f spec.awk test_spec.txt > $TEST_FILE.tmp
    else
        cp "$TEMPLATE" $TEST_FILE.tmp
    fi
    sed "s/FLAG_NAME_HERE/$TEST_FLAG/g" $TEST_FILE.tmp > $TEST_FILE
    rm $TEST_FILE.tmp
    chmod 700 $TEST_FILE
    if [ "$ADD_TO_MAKE" == true ]; then
        echo -e "\t./$TEST_FILE" >>$MAKE_FILE
    fi
else
    echo "**error, missing $TEMPLATE exiting."
    exit 1
fi
# EOF
