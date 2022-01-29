#!/bin/bash
###
#
# Product: pipe.pl
# Purpose: test -M functionality.
#
# Copyright (c) Andrew Nisbet 2022.
# All code covered by the project's license.
#
###

### Global variables
# Set this false if you want to keep the scratch files.
KEEP_TEMP_FILES=false
FLAG_TESTED='-M'
LOG_FILE="./pipe-tests.log"
TMPDIR=/tmp
TEST_FILE="pipe-test${FLAG_TESTED}.XXXXXXXXXX"
VERSION="1.0"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $0 [flags]
Test file template for pipe.pl.

Flags:

-h, -help, --help: This help message.
-l, -log_file, --log_file{/foo/bar.log}: Changes the log file for the tests in this script.
-p, -preserve_temp_files, --preserve_temp_files: Temp files are preserved. By default
   tmp files are removed. Logs are never touched.
-v, -version, --version: Print watcher.sh version and exits.

 Example:
    ${0} --tmp_dir=/home/user/dir/*.txt --log_file=/home/user/foo.log
EOFU!
}

# Logs messages to STDERR and $LOG file.
# param:  Log file name. The file is expected to be a fully qualified path or the output
#         will be directed to a file in the directory the script's running directory.
# param:  Message to put in the file.
# param:  (Optional) name of a operation that called this function.
logit()
{
    local message="$1"
    local time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$time] $message"
    echo -e "[$time] $message" >>$LOG_FILE
}

# Start up code (if required)
init()
{
    logit "== Testing $FLAG_TESTED"
}

# Cleanup code to remove scratch files.
clean_up()
{
    
    if [ "$KEEP_TEMP_FILES" == false ]; then 
        rm -rf $OUT || exit 0;
    fi
}


### Parameter handling
### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "help,log_file:,preserve_temp_files,version" -o "hl:pv" -a -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
    case $1 in
    -h|--help)
        usage
        exit 0
        ;;
    -l|--log_file)
        # Set a unique log file.
        shift
        export LOG_FILE="$1"
        ;;
    -p|--preserve_temp_files)
        # Set true to keep scratch files.
        export KEEP_TEMP_FILES=true
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
OUT=$(mktemp $OUT) || { echo "Failed to create $OUT"; exit 1; }


### Main tests run here. ###
logit "== Testing '$FLAG_TESTED' flag =="
logit "$0, version $VERSION, \$LOG_FILE=$LOG_FILE, \$OUT=$OUT, \$KEEP_TEMP_FILES=$KEEP_TEMP_FILES"



# Clean up scratch files if $KEEP_TEMP_FILES is set true. See -p.
clean_up
logit "== Test complete =="
# EOF
