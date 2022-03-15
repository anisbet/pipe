## Turns readme documentation into specs, for conversion into tests.
## Some rules:
## 1) Back-ticked 'console' text should be indented one space.
## 2) Keywords are '# Flag:', 'Parameters:', 'Use case:', 'Input:', and 'Output:'. Everything else is ignored.
## 3) The script outputs spec-*.test ready code.
BEGIN {
    RS = "\n";
    FS = ": ";
    readData = 0;
    output = "OUTPUT";
    input  = "INPUT";
    error  = "ERROR";
    outputFileType = input;
    lastFileType = "";
    # Marker for other processes to separate output into another script file.
    startOfScriptSentinal = "# SPEC_FILE";
    backTicksImportant = 0;
    EOF_NL = "IGNORE_LAST_NEWLINE";
}

# Triggers start and end of reading data.
/^```/ {
    # If this is a section where ```backticks``` can appear at the start of a line ignore.
    if (backTicksImportant == 0) {
        next;
    }
    # Special case of '```in-data => out-data```'
    gsub(/```/, "");
    pos = index($0," => ");
    my_input = substr($0, 0, pos -1);
    my_output= substr($0, pos + 4);
    if (my_input != ""){
        print "BEGIN_" input;
        printf "%s\n", my_input;
        print "END_" input;
        print "";
        print "BEGIN_" output;
        printf "%s\n", my_output;
        print "END_" output;
        print "";
        lastFileType = output;
    } else {  # Plain back-ticks, and the following data should be exported.
        if (readData == 1) {
            readData = 0;
            print "END_" outputFileType;
            print "";
            # Save file type state to auto-add error file output if not specified.
            # Error file definitions are required in tests but not in Readme.md's.
            lastFileType = outputFileType;
        } else {
            readData = 1;
            print "BEGIN_" outputFileType;
        }
        # Don't output the back-ticks itself.
        next
    }
}



/^(#+ )?Flag:/ {
    backTicksImportant = 0;
    # Chunk out each flag in the Readme.md as a separate spec file for testing.
    if ($2 ~ /^-/) {
        # Remove any and all dashes before the flag.
        gsub(/^(-)+/, "", $2);
    }
    # When Readme.md contains more than one flag we have to add a 
    # error output before starting the next Flag:.
    if (lastFileType == output) {
        print "BEGIN_" error;
        print "END_" error;
        print "";
        lastFileType = error;
    }
    printf "%s=spec-%s.test\n",startOfScriptSentinal,$2;
    printf "FLAG=%s\n", $2;
    lastFileType = "";
}

/^(#+ )?Use case:/ {
    if (lastFileType == output) {
        print "BEGIN_" error;
        print "END_" error;
        print "";
    }
    # Strip off any single quote and replace with a double quote.
    gsub(/'/, "\"", $2);
    print "USE_CASE=" $2;
}

# Flags including the flag being tested at the front
/^(#+ )?Parameters:/ {
    # Trim off the leading dash-FLAG if present. Spec.test files don't use them.
    if ($2 ~ /^-/) {
        gsub(/^(-)+./, "", $2);
    }
    print "PARAMS=" $2;
}

# Special case of one line input and output.
/^(#+ )?Input:/ {
    backTicksImportant = 1;
    outputFileType = input;
    # Output the name of the input file if mentioned.
    if ($2 != "") {
        printf "NAMED_FILE:%s\n",$2;
    }
}

/^(#+ )?Output:/ {
    backTicksImportant = 1;
    outputFileType = output;
    if ($2 ~ /Ignore last newline/) {
        # Add special instruction to trim off last newline in heredoc.
        printf "SPECIAL_INSTRUCTION:%s\n",EOF_NL;
    }
}

/^(#+ )?Error:/ {
    backTicksImportant = 1;
    outputFileType = error;
}

{
    if (readData == 1){
        printf "%s\n",$0;
    } else {
        next;
    }
}

END {
    if (lastFileType == output) {

        print "BEGIN_" error;
        print "END_" error;
        print "";
    }
}