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
VERSION="1.0"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $0 [flags]
Create a test template script for an arbitrary but specific pipe.pl flag.

Flags:

-f, -flag, --flag{flag}: Set the pipe.pl flag to be tested. Required.
-h, -help, --help: This help message.
-m, -make, --make{true|false}: Add script to Makefile or not. Default true.
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
options=$(getopt -l "flag:,help,make:,version" -o "f:hm:v" -a -- "$@")
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
cat <<TEST_SCRIPT_CODE! > $TEST_FILE
#!/bin/bash
###
#
# Product: pipe.pl
# Purpose: test functionality of '$TEST_FLAG'.
#
# Copyright (c) Andrew Nisbet 2022.
# All code covered by the project's license.
#
###

### Global variables
# Set this false if you want to keep the scratch files.
KEEP_TEMP_FILES=false
FLAG_TESTED='$TEST_FLAG'
# Set this to the pipe.pl version you want to test.
PIPE="../pipe.pl"
LOG_FILE="./pipe-tests.log"
TMP_DIR=/tmp/pipe-test-scratch
DATA_FILE="\$TMP_DIR/data-input-\${FLAG_TESTED}.txt"
VERSION="1.0"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: \$0 [flags]
Test file template for pipe.pl.

Flags:

-h, -help, --help: This help message.
-l, -log_file, --log_file{/foo/bar.log}: Changes the log file for the tests in this script.
-p, -preserve_temp_files, --preserve_temp_files: Temp files are preserved. By default
   tmp files are removed. Logs are never touched.
-v, -version, --version: Print application version and exits.

 Example:
    \${0} --tmp_dir=/home/user/dir/*.txt --log_file=/home/user/foo.log
EOFU!
}

# Logs messages to STDERR and \$LOG file.
# param:  Log file name. The file is expected to be a fully qualified path or the output
#         will be directed to a file in the directory the script's running directory.
# param:  Message to put in the file.
# param:  (Optional) name of a operation that called this function.
logit()
{
    local message="\$1"
    local time=\$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[\$time] \$message"
    echo -e "[\$time] \$message" >>\$LOG_FILE
}

# Start up. Creates a temp directory for any input and output files.
init()
{
    if [ -d "\$TMP_DIR" ]; then 
        logit "* warning, \$TMP_DIR already exits and will be removed."
        rm -rf \$TMP_DIR
    fi
    \$(mkdir \$TMP_DIR) || { echo "Failed to create \$TMP_DIR"; exit 1; }
    ## Create some data to pipe into \$PIPE 
    cat <<EOF_TEST_DATA! >\$DATA_FILE
1|A
2|B
EOF_TEST_DATA!
}

# Cleanup code to remove scratch files.
clean_up()
{
    if [ "\$KEEP_TEMP_FILES" == true ]; then
        logit "preserving files in \$TMP_DIR. They will be removed when test re-run."
    else
        rm -rf \$TMP_DIR
    fi
}

### Parameter handling
### Check input parameters.
# \$@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=\$(getopt -l "help,log_file:,preserve_temp_files,version" -o "hl:pv" -a -- "\$@")
if [ \$? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "\$options"

while true
do
    case \$1 in
    -h|--help)
        usage
        exit 0
        ;;
    -l|--log_file)
        # Set a unique log file.
        shift
        export LOG_FILE="\$1"
        ;;
    -p|--preserve_temp_files)
        # Set true to keep scratch files.
        export KEEP_TEMP_FILES=true
        ;;
    -v|--version)
        echo "\$0 version: \$VERSION"
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
# param: string name of the test.
# param: string list of parameters to pass to pipe.pl to operate on.
# param: expected output.
test()
{
    [ -z "\$1" ] || [ -z "\$2" ] && { logit "**error malformed test."; exit 1; }
    local test_name="\$1"
    local params="\$2"
    local expected="\$3"
    local err_file=\$TMP_DIR/err.txt
    local results=\$TMP_DIR/out.txt
    cat \$DATA_FILE | \$PIPE \${params} >\$results 2>\$err_file
    if [ -s "\$err_file" ]; then
        logit "*warning '\$test_name' output an error"
        head -n 3 \$err_file
        # remove it or the next test will report an error
        rm \$err_file
    fi
    if diff "\$results" "\$expected" 2>&1 >\$TMP_DIR/diff.\$test_name; then
        logit "\$test_name: PASS"
    else
        logit "diff reports: <results compared to >expected"
        cat \$TMP_DIR/diff.\$test_name | tee -a \$LOG_FILE
    fi
}


### Main tests run here. ###
logit "== Testing '\$FLAG_TESTED' flag =="
logit "\$0, version \$VERSION, LOG_FILE=\$LOG_FILE, DATA_FILE=\$DATA_FILE, KEEP_TEMP_FILES=\$KEEP_TEMP_FILES"

# Set up the test input file.
init
cat <<EXPECTED_OUTPUT > \$TMP_DIR/expected_0.txt
1|A
2|B
EXPECTED_OUTPUT
test "test_no_second_file" "-$TEST_FLAG'{col_values}'" "\$TMP_DIR/expected_0.txt"

# Clean up scratch files if \$KEEP_TEMP_FILES is set true. See -p.
clean_up
logit "== Test complete =="
# EOF
TEST_SCRIPT_CODE!

chmod 700 $TEST_FILE
if [ "$ADD_TO_MAKE" == true ]; then
    echo -e "\t./$TEST_FILE" >>$MAKE_FILE
fi
# EOF
