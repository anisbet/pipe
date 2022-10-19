#!/bin/bash
#################################################################################
#
# Product: test-pipeline.sh
# Purpose: Can do serveral jobs related to testing a command line scripts and 
#          and other API.
#          1) Given spec-*.test files, can generate executeable test-*.sh files.
#          2) Given a markdown file, can generate spec-*.test files.
#          3) Can run all tests and log results.
#
# Copyright (c) Andrew Nisbet 2022.
# All code covered by the project's license.
#
################################################################################

### Global variables
TEST_API=
CLOBBER_EXISTING_FILES=false
GENERATE_MAKEFILE=false
GENERATE_TESTS=false
WORKING_DIR=.
TEST_MARKDOWN=''
GEN_SPEC=$WORKING_DIR/gen_spec.sh
GEN_TEST=$WORKING_DIR/gen_test.sh
MAKE_FILE=$WORKING_DIR/Makefile
VERSION="1.0.01"

### Functions
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $0 [flags]
Can do serveral jobs related to testing a command line scripts and other API.
  1) Given spec-*.test files, can generate executeable test-*.sh files.
  2) Given a markdown file, can generate spec-*.test files.
  3) Can run all tests and log results.

Flags:

-f, -force, --force: Over write any existing specs or test scripts.
-h, -help, --help: This help message.
-m, -make, --make: Create a Makefile for testing.
-s, -spec_markdown, --spec_markdown={/foo/bar/readme.md}: Specifies the markdown
  file used to generate spec-*.test files, and generates the spec-*.test files.
  in the working directory. (See -w to set working directory).
-t, -test, --test: Generate test scripts. Searches for given spec-*.test 
  files and converts them into executable test-*.sh scripts.
-v, -version, --version: Print application version and exits.
-w, -working_dir, --working_dir{/foo/bar}: Sets the working directory for
  searching and writing any files. Default the current directory.
  Note that pipeline.sh will look for helper awk files in the working directory.

 Example:
    ${0} --flag=t
EOFU!
}

# Parses markdown into master specification file.
# Markdown file must exist.
genSpecs()
{
    [[ -x "$GEN_SPEC" ]] || { echo "**error required helper '$GEN_SPEC' not executable, exiting."; exit 1; }
    if [ "$CLOBBER_EXISTING_FILES" == true ]; then
        $GEN_SPEC --force --markdown="$TEST_MARKDOWN"
    else
        $GEN_SPEC --markdown="$TEST_MARKDOWN"
    fi
}

# Generates test scripts from any spec-*.test files.
genTests()
{
    local tmp=/tmp/$(basename -s .sh $0).tmp
    if find . -name spec-\*.test >$tmp; then
        while IFS= read -r line
        do
            # echo "DEBUG: $GEN_TEST --force --spec-file='$line'"
            if [ "$CLOBBER_EXISTING_FILES" == true ]; then
                $GEN_TEST --force --spec-file="$line"
            else
                $GEN_TEST --spec-file="$line"
            fi
        done <$tmp
        rm $tmp
        echo "done"
    else
        echo "no spec files to compile."
    fi
}

# Generate Makefile of tests.
genMakefile()
{
    local markdown="$1"
    cat >$MAKE_FILE <<EOMAKE!
# Makefile automatically generated by $(basename -s .sh $0).
# Copyright (c) Andrew Nisbet 2022.
# 
.PHONY: test clean pristine

test: clean
$(find . -name test-\*.sh | awk '{gsub(/\?/,"\\?",$0);printf "\t-%s\n",$0}')

clean:
	-rm ./*.log

build:
	./pipeline.sh -s $markdown --force --test

pristine: clean
	-rm ./spec-*
	-rm ./test-*

# EOF
EOMAKE!
    echo "make file created."
}


### Parameter handling
### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "force,help,make,spec_markdown:,test,version,working_dir" -o "fhms:tvw:" -a -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
    case $1 in
    -f|--force)
        # Force the existing test-*.sh to be over-written.
        CLOBBER_EXISTING_FILES=true
        ;;
    
    -h|--help)
        usage
        exit 0
        ;;
    
    -m|--make)
        # Generate a Makefile in working_dir
        GENERATE_MAKEFILE=true
        ;;

    -s|--spec_markdown)
        # /foo/bar/readme.md or similar.
        shift
        TEST_MARKDOWN="$1"
        ;;

    -t|--test)
        # Generate test files from any spec-*.test files.
        GENERATE_TESTS=true
        ;;

    -v|--version)
        echo "$0 version: $VERSION"
        exit 0
        ;;

    -w|--working_dir)
        # /foo/bar/readme.md or similar.
        shift
        export WORKING_DIR="$1"
        ;;

    --)
        shift
        break
        ;;
    esac
    shift
done
# Test for required -a api to test.
# : ${TEST_API:?Missing -a,--api}
# [[ -x "$TEST_API" ]] || { echo "**error, '$TEST_API' is not executable, exiting."; exit 1; }
[[ -d "$WORKING_DIR" ]] || { echo "**error, invalid working directory: '$WORKING_DIR', exiting."; exit 1; }
cd $WORKING_DIR
[[ -z "$TEST_MARKDOWN" ]] || genSpecs
[[ "$GENERATE_TESTS" == true ]] && genTests
[[ "$GENERATE_MAKEFILE" == true ]] && genMakefile $TEST_MARKDOWN
exit 0
# EOF
