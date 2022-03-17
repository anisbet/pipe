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

# Usage: pipeline
Pipeline has the following switch options.
```console
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
```

The pipeline for conversion of a Markdown Readme is as follows.
Markdown => specifications => test scripts + Makefile

## Running pipeline
In the ```tests\``` directory you will find ```pipeline.sh``` and its associated awk files. Once in that directory you can generate all tests from ```pipe.pl```'s Readme.md file with the following.
```./pipeline.sh --spec_markdown=../Readme.md --make --force --test```

Once all the spec files are generated and converted to shell scripts you will be able to run any test manually with ```./test-{flag}.sh``` or use the ```./test-{flag}.sh --help``` for more options.

All tests can be run by typing ```make```. Then ```grep``` the logs for any failures with ```grep FAIL pipe-tests.log```.

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
* To be parsed correctly into a ```spec-*.test``` file the markdown documentation must be organized as noted starting in the [Flag section below](#flag).
* Document parsing starts when the [API Reference section](#api-reference). Any line that starts with triple-back ticks will be interpreted as either input, output, or error examples. If that is not your intention add a leading space.
* Key words (below) must not be preceded by any spaces, but may be preceded by Markdown title characters ```# ```.
* When quoting strings in ```Use case:``` sections use double-quotes.
* When quoting parameters in ```Parameters:``` sections use double-quotes.
* Named files allow multiple files to be used in tests. See [Input:](#input-data) for more details.

### API Reference
This is a required section, may include other information or not, but if this section includes code make sure to add a white space character before any line that starts with triple-back ticks.

### Flag:
Indicates the flag to be tested. Each <pre># Flag:</pre> will be parsed into a separate test script file named ```test-{flag}.sh```. 

The dash '-' or '--' are not required but can be included to improve readability.

### Use case:
Describes a feature of the 'flag' and how it is used. Later this appears in the log output as the name of the test.

### Parameters:
Additional parameters used by the flag. Specifying the flag itself is optional and doing so can improve clarity of the documentation. The dash '-' or '--' are are also optional. Make sure the flag you are testing is listed first in the parameters string.

### Input: (data)
Input data is always written to file during testing. By default pipeline will create file names for you in a scratch directory. You can also use
named files (```Input: file1```), but they must be defined before any standard ```Input:``` directive. The file may be a relative or absolute path.

### Output:
The expected output produced by using the 'flag' and its parameters. The output data is expected to start on the next that starts with triple-back ticks (code markdown). Since output files are ```heredoc```s, and all ```heredoc```s end with a newline, if that is not your intension use the phrase ```Ignore last newline``` and the last new line will be removed from the expected-output file. For example:
<pre>
Output: Ignore last newline
```
data
```
</pre>


### Error:
Optional, includes the text output during an error condition. May be omitted for readability, and if so, a ERROR section is added to the specification file automatically. If included, the error data is expected to start on the next that starts with triple-back ticks (code markdown).

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