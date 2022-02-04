#!/bin/bash
###
#
# Product: pipe.pl
# Purpose: test -v functionality.
#
# Copyright (c) Andrew Nisbet 2022.
# All code covered by the project's license.
#
###

### Global variables
# Set this false if you want to keep the scratch files.
KEEP_TEMP_FILES=false
FLAG_TESTED='v'
# Set this to the pipe.pl version you want to test.
PIPE="../pipe.pl"
LOG_FILE="./pipe-tests.log"
TMP_DIR=/tmp/pipe-test-scratch
DATA_FILE_PREFIX="$TMP_DIR/data-input-${FLAG_TESTED}"
ACTUAL_STDOUT="$TMP_DIR/output-actual-${FLAG_TESTED}"
ACTUAL_STDERR="$TMP_DIR/error-actual-${FLAG_TESTED}"
EXPECTED_STDOUT="$TMP_DIR/output-expected-${FLAG_TESTED}"
EXPECTED_STDERR="$TMP_DIR/error-expected-${FLAG_TESTED}"
TEST_NUMBER=0
VERSION="1.1.01"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $0 [flags]
Test file for pipe.pl parameter '-v'.

Flags:

-h, -help, --help: This help message.
-l, -log_file, --log_file{/foo/bar.log}: Changes the log file for the tests in this script.
-p, -preserve_temp_files, --preserve_temp_files: Temp files are preserved. By default
   tmp files are removed. Logs are never touched.
-v, -version, --version: Print application version and exits.

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

# Start up. Creates a temp directory for any input and output files.
init()
{
    if [ -d "$TMP_DIR" ]; then 
        logit "* warning, $TMP_DIR already exits and will be removed."
        rm -rf $TMP_DIR
    fi
    $(mkdir $TMP_DIR) || { echo "Failed to create $TMP_DIR"; exit 1; }
}

# Cleanup code to remove scratch files.
clean_up()
{
    if [ "$KEEP_TEMP_FILES" == true ]; then
        logit "preserving files in $TMP_DIR. They will be removed when test re-run."
    else
        rm -rf $TMP_DIR
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

# Test if an error is issued.
# param 1: Required. String name of the input data file.
# param 2: Required. String name of the test.
# param 3: Required. String list of parameters to pass to pipe.pl to operate on.
# param 4: Required. Expected_stdout output.
# param 5: Optional. Expected_stderr output file name if the output of the test 
#        is expected on STDERR.
test()
{
    [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] && { logit "**error malformed test."; exit 1; }
    local input="$1"
    local test_name="$2"
    local params="$3"
    local expected_stdout="$4"
    local expected_stderr="$5"
    # Destination files for result output if required.
    local err_file=${ACTUAL_STDERR}.$TEST_NUMBER.txt
    local out_file=${ACTUAL_STDOUT}.$TEST_NUMBER.txt
    local diff_err=${ACTUAL_STDERR}.$TEST_NUMBER.diff
    cat $input | $PIPE ${params} >$out_file 2>$err_file
    # Some commands output to stderr by default, other tests pass if the expected 
    # result is a failed condition.
    if [ -s "$err_file" ]; then
        if [ ! -z "$expected_stderr" ] && [ -f "$expected_stderr" ]; then
            if diff "$err_file" "$expected_stderr" 2>&1 >$diff_err; then
                logit "PASS: test $TEST_NUMBER STDERR '$test_name'"
            else
                logit "**FAIL: test $TEST_NUMBER STDERR '$test_name'"
                logit "  < actual and > expected"
                cat $diff_err | tee -a $LOG_FILE
            fi
        else
            logit "*WARN: test $TEST_NUMBER STDERR '$test_name' output an unexpected error"
            head -n 3 $err_file
        fi
        # remove it or the next test will report an error
        rm $err_file
    fi
    ## Test the stdout produced by running the command.
    if diff "$out_file" "$expected_stdout" 2>&1 >$diff_err; then
        logit "PASS: test $TEST_NUMBER STDOUT '$test_name'"
    else
        logit "**FAIL: test $TEST_NUMBER STDOUT '$test_name'"
        logit "  < actual and > expected"
        cat $diff_err | tee -a $LOG_FILE
    fi
}


### Main tests run here. ###
logit "== Testing '$FLAG_TESTED' flag =="
logit "$0, version $VERSION, \$LOG_FILE=$LOG_FILE, data files=${DATA_FILE_PREFIX}*, \$KEEP_TEMP_FILES=$KEEP_TEMP_FILES"
# Set up the test infrastructure.
init

### Use case starts
INPUT_FILE=${DATA_FILE_PREFIX}.$TEST_NUMBER.txt
## Create input data $PIPE 
cat >$INPUT_FILE <<FILE_DATA!
100
200
79
23
81.5
FILE_DATA!
USE_CASE="Tests flag '-v' - average of non-empty, non-numeric data in arbitrary but specific columns."
PARAMETERS="-vc0"
EXPECTED_OUT=${EXPECTED_STDOUT}.$TEST_NUMBER.txt
# Expected: error message issued.
cat > $EXPECTED_OUT <<EXP_OUT!
100
200
79
23
81.5
EXP_OUT!
EXPECTED_ERR=${EXPECTED_STDERR}.$TEST_NUMBER.txt
cat > $EXPECTED_ERR <<EXP_ERR!
==   average
 c0:   96.70
EXP_ERR!
## input, "test name", "pipe.pl parameters", expected output (file name), expected error (file name)
test $INPUT_FILE "$USE_CASE" "$PARAMETERS" $EXPECTED_OUT $EXPECTED_ERR 
((TEST_NUMBER++))
### Use case ends

### Use case starts
INPUT_FILE=${DATA_FILE_PREFIX}.$TEST_NUMBER.txt
## Create input data $PIPE 
cat >$INPUT_FILE <<FILE_DATA!
100
200
79
23
Text data
81.5
FILE_DATA!

USE_CASE="Tests flag '-v' - average over column with text data."
PARAMETERS="-vc0"
EXPECTED_OUT=${EXPECTED_STDOUT}.$TEST_NUMBER.txt
# Expected: error message issued.
cat > $EXPECTED_OUT <<EXP_OUT!
100
200
79
23
Text data
81.5
EXP_OUT!
EXPECTED_ERR=${EXPECTED_STDERR}.$TEST_NUMBER.txt
cat > $EXPECTED_ERR <<EXP_ERR!
==   average
 c0:   96.70
EXP_ERR!
## input, "test name", "pipe.pl parameters", expected output (file name), expected error (file name)
test $INPUT_FILE "$USE_CASE" "$PARAMETERS" $EXPECTED_OUT $EXPECTED_ERR 
((TEST_NUMBER++))
### Use case ends

### Use case starts
INPUT_FILE=${DATA_FILE_PREFIX}.$TEST_NUMBER.txt
## Create input data $PIPE 
cat >$INPUT_FILE <<FILE_DATA!

100|
200


79
23

81.5
FILE_DATA!
USE_CASE="Tests flag '-v' - average over column with empty values."
PARAMETERS="-vc0"
EXPECTED_OUT=${EXPECTED_STDOUT}.$TEST_NUMBER.txt
# Expected: error message issued.
cat > $EXPECTED_OUT <<EXP_OUT!

100|
200


79
23

81.5
EXP_OUT!
EXPECTED_ERR=${EXPECTED_STDERR}.$TEST_NUMBER.txt
cat > $EXPECTED_ERR <<EXP_ERR!
==   average
 c0:   96.70
EXP_ERR!
## input, "test name", "pipe.pl parameters", expected output (file name), expected error (file name)
test $INPUT_FILE "$USE_CASE" "$PARAMETERS" $EXPECTED_OUT $EXPECTED_ERR 
((TEST_NUMBER++))
### Use case ends

### Use case starts
INPUT_FILE=${DATA_FILE_PREFIX}.$TEST_NUMBER.txt
## Create input data $PIPE 
cat >$INPUT_FILE <<FILE_DATA!
This
That
Another line of text.

FILE_DATA!
USE_CASE="Tests flag '-v' - average over columns that have no numeric data."
PARAMETERS="-vc0"
EXPECTED_OUT=${EXPECTED_STDOUT}.$TEST_NUMBER.txt
# Expected: error message issued.
cat > $EXPECTED_OUT <<EXP_OUT!
This
That
Another line of text.

EXP_OUT!
EXPECTED_ERR=${EXPECTED_STDERR}.$TEST_NUMBER.txt
cat > $EXPECTED_ERR <<EXP_ERR!
==   average
 c0:       0
EXP_ERR!
## input, "test name", "pipe.pl parameters", expected output (file name), expected error (file name)
test $INPUT_FILE "$USE_CASE" "$PARAMETERS" $EXPECTED_OUT $EXPECTED_ERR 
((TEST_NUMBER++))
### Use case ends

# Clean up scratch files if $KEEP_TEMP_FILES is set true. See -p.
clean_up
logit "== End test =="
# EOF
