BEGIN {
    RS = "\n";
    isInput = 0;
    isOutput= 0;
    isError = 0;
    # number of lines to read from the template. 
    # One less than the line '## ------ Template ends here -----'.
    templateHeadLength = 186;
    totalLines = 0;
    # Optional named file input
    namedFile = "";
    # Read the template file.
    while(( getline line < TEMPLATE_SCRIPT) > 0 ) {
        if (totalLines < templateHeadLength) {
            print line;
        }
        totalLines++;
    }
}

/^END_INPUT/ {
    isInput = 0;
    print "FILE_DATA!";
}

/^END_OUTPUT/ {
    isOutput = 0;
    print "EXP_OUT!";
}

/^END_ERROR/ {
    isError = 0;
    print "EXP_ERR!";
    print "## input, \"test name\", \"pipe.pl parameters\", expected output (file name), expected error (file name)";
    print "test $INPUT_FILE \"$USE_CASE\" \"$PARAMETERS\" $EXPECTED_OUT $EXPECTED_ERR ";
    print "((TEST_NUMBER++))";
    print "### Use case ends";
    print "";
}

{
    if (isInput == 1 \
    || isOutput == 1 \
    || isError == 1) {
        print $0;
    }
}

/^USE_CASE=/ {
    # start of 'USE_CASE=' is 8th character
    useCaseString = substr($0, 10);
    print "";
    print "### Use case starts";
    printf "USE_CASE='%s'\n", useCaseString;
}

/^PARAMS=/ {
    # start of 'PARAMS=' is 8th character
    paramString = substr($0, 8);
    # Use replacement of single quotes in a literal
    gsub(/'/, "'\"'\"'", paramString);
    printf "PARAMETERS='-FLAG_NAME_HERE%s'\n", paramString;
}

/^NAMED_FILE/ {
    gsub(/NAMED_FILE:/, "");
    namedFile = $0;
}

/^BEGIN_INPUT/ {
    isInput = 1;
    print "";
    if (namedFile == "") {
        print "INPUT_FILE=${DATA_FILE_PREFIX}.$TEST_NUMBER.txt";
    } else {
        # Can be a relative or absolute file path.
        printf "INPUT_FILE=\"%s\"\n", namedFile;
        printf "SCRATCH_FILES+=(\"%s\")\n", namedFile;
        # Reset named file for the next name choosen by the user.
        namedFile = "";
    }
    print "## Create input data";
    print "cat >$INPUT_FILE <<FILE_DATA!";
}

/^BEGIN_OUTPUT/ {
    isOutput = 1;
    print "EXPECTED_OUT=${EXPECTED_STDOUT}.$TEST_NUMBER.txt";
    print "# Expected: results issued.";
    print "cat > $EXPECTED_OUT <<EXP_OUT!";
}

/^BEGIN_ERROR/ {
    isError = 1;
    print "EXPECTED_ERR=${EXPECTED_STDERR}.$TEST_NUMBER.txt"
    print "cat > $EXPECTED_ERR <<EXP_ERR!"
}

END {
    # Add the clean up code.
    print "";
    print "# Clean up scratch files if $KEEP_TEMP_FILES is set true. See -p.";
    print "clean_up";
    print "logit '== End test =='";
    print "# EOF";
}