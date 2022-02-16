# Pipeline test framework
This set of scripts is used as a pipeline of tests for pipe.pl but can be applied to any command line tool.

## Project Organization
1) ```pipeline.sh``` - main script.
2) ```gen_spec.sh``` - Generates spec-*.test files from Markdown (Readme.md typically).
3) ```gen_test.sh``` - Generates test-*.sh scripts from spec-*.test files.
4) ```spec.awk``` - parser for converting spec-*.test files into shell script test-*.sh.
5) ```readme-parser.awk``` - Parser for Markdown documents. Converts Markdown into spec-*.test files.
6) ```template.sh``` - Template bash shell script used for producing test-*.sh files.
7) ```Makefile``` - Automates test runs.
8) ```pipe-test.log``` - Log of all the test results. Additional testing results are appended.

Pipeline has the following switch options.
```--spec_markdown{/foo/bar/Readme.md}``` will read the markdown and parse it into specification files, one for each flag automatically.
```--test``` will convert any specification files in the $WORKING_DIR to test script files.
```--make``` will generate a Makefile with all test scripts under a rule for test. A clean rule is also added to remove any previous log file.

Using all of these switches will run the pipeline in order.
Markdown => specifications => test scripts + Makefile

To run the tests type ```$ make test```.
To overwrite or update existing specifications or test scripts use the ```--force```.

# Specification files (spec-*.test)
Specification files are a set of tests related to a single option. They can be created by hand or from markdown, but all must follow the same pattern of organization.
```
# SPEC_FILE=spec-t.test
FLAG=t
USE_CASE=Trim leading / trailing white space from all columns.
PARAMS=any
BEGIN_INPUT
  1 |  2  |  3
END_INPUT

BEGIN_OUTPUT
1|2|3
END_OUTPUT

BEGIN_ERROR
END_ERROR
# Comments if desired.
```

## Specification Rules
1) ```# SPEC_FILE``` and ```FLAG``` can only occur once per specification file. 
2) Each use case tests a different feature of a given flag.
3) Many ```USE_CASE```s tests are permitted.
4) Each use case must have the same features in order.
    1) ```USE_CASE``` Description of the test being performed and why.
    2) ```PARAMS``` Additional parameters used by the flag.
    3) ```BEGIN_INPUT``` Start of input data.
    4) ```END_INPUT```   End of input data
    5) ```BEGIN_OUTPUT``` Start of expected output results.
    6) ```END_OUTPUT```   End of expected output.
    7) ```BEGIN_ERROR``` Start of any error message. Required but can be empty.
    8) ```END_ERROR```   End of error message.
5) Comments start with ```# ```.

# Using Markdown to create specifications
Pipeline can use the target application's markdown documentation to generate specification files and then compile those specs into test scripts. The following sections must be used in order, and all are required except where noted. All sections below may be repeated.

Other markdown syntax are ignored.

## Markdown rules
To be parsed correctly into a ```spec-*.test``` file the markdown documentation must be organized as follows.

Each section may start with optional title hash (```#```) marks optionally.

### Flag:
Indicates the flag to be tested. Each <pre># Flag:</pre> will be parsed into a separate test script file named ```test-{flag}.sh```. 

The dash '-' or '--' are not required but can be included to improve readability.

### Use case:
Describes a feature of the 'flag' and how it is used. Later this appears in the log output as the name of the test.

### Parameters:
Additional parameters used by the flag. Specifying the flag itself is optional and doing so can improve clarity of the documentation. The dash '-' or '--' are are also optional.

### Input: (data)
Input data is always written to file during testing. You can influence how the file is named by adding a string with no spaces after the colon ':'.
For example ```Input: file1```

### Output:
The expected output produced by using the 'flag' and its parameters.

### Error:
Optional, includes the text output during an error condition. May be omitted for readability, and if so, a ERROR section is added to the specification file automatically.

### Example Markdown
<pre>
# Flag: W
Use case: Test the 'W' flag.
Parameters: -W :

The following syntax will automatically create a BEGIN_INPUT and END_INPUT,
a BEGIN_OUTPUT and END_OUTPUT of data after ' => ', and add a BEGIN_ERROR and END_ERROR
section to keep the markdown tidy and readable.
Input:
```1:2 => 1|2```

This is a standard way to run a set of tests for the '-t' flag.
# Flag: t
Use case: Trim leading / trailing white space from all columns.
Parameters: -tany
Input:
```  1 |  2  |  3 => 1|2|3```

Use case: Trim leading / trailing white space from one columns.
Parameters: -tc1
Input:
```
1 |  2  |  3
```
Output:
```
1 |2|  3
```
</pre>