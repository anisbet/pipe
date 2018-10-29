
Usage notes for pipe.pl
-----------------------
This application is a accumulation of helpful scripts that performs common tasks on pipe-delimited files. 
The count function (-c), for example counts the number of non-empty values in the specified columns. 
Other functions work similarly. Stacked functions are operated on in alphabetical order by flag letter, 
that is, if you elect to order columns and trim columns, the columns are first ordered, then the columns 
are trimmed, because -o comes before -t. The exceptions to this rule are those commands that require 
the entire file to be read before operations can proceed (-d dedup, -r random, and -s sort). 
Those operations will be done first then just before output the remaining operations are performed.

Example:
cat file.lst | pipe.pl -c'c0'
pipe.pl only takes input on STDIN. All output is to STDOUT. Errors go to STDERR.
Things pipe.pl can do
---------------------
* Trim arbitrary fields.
* Order and suppress output of arbitrary fields.
* Randomize all, or a specific sample size of the records from input.
* De-duplicate records from input.
* Count non-empty fields from input records.
* Summation over non-empty numeric values of arbitrary fields.
* Sort input lines based on one or more arbitrary fields, numerically or lexical-ly.
* Mask output of specific characters, and range of characters, within arbitrary fields.
* Averages over columns.
* Output line numbers or counts of dedups.
* Force trailing pipe on output.
* Grep a specific column value with regular expressions.
* Compare columns for differences.
* Flexibly pad output fields.
* Report maximum and minimum width of column data.
* Output sub strings of values in columns by specific index or range of indices.
* Change case of fields.
* Flip character value conditionally.
* Output characters in different bases.
* Replace values in columns conditionally.
* Translate values within columns.
* Compute new column values based on values in other columns recursively.
* Sum values over groups.
* Merge columns.
* Increment values in columns.
* Add an auto-increment column.
* Output alternate lines.
* Show regional context of a match. See -g and -G.
* Take input from named file (see -0).
* Compute the delta between lines.
* Histogram values within columns.
* Math over columns.

A note on usage; because of the way this script works it is quite possible to produce mystifying results. For example, failing to remember that ordering comes before trimming may produce perplexing results. You can do multiple transformations, but if you are not sure you can pipe output from one process to another pipe process. If you order column so that column 1 is output then column 0, but column 0 needs to be trimmed you would have to write:
```
cat file | pipe.pl -o'c1,c0' -t'c1'
```
because -o will first order the row, so the value you want trimmed is now c1. If that is too radical to contemplate then:
```
cat file | pipe.pl -t'c0' | pipe.pl -o'c1,c0'
```

Complete list of flags
----------------------
```
 -?{opr}:{c0,c1,...,cn}: Use math operation on fields. Supported operators are 'add', 'sub',
                  'mul', and 'div'. The order of columns is important for subtraction and division 
                  since '1|2' -?div:c0,c1 => '0.5|1|2' and '1|2' -?div:c1,c0 => '2|1|2'.
                  The result always appears in column 0 (c0), see -o to re-order. See -y to 
                  change the precision of the result. -? supports math over multiple columns.
                  Divide by zero will result in a result of 'NaN'. If a column contains non-numeric
                  data it is ignored during the calculation, so '1|cat' -?div:c0,c1 => '1', but 
                  '1|0' -?div:c0,c1 => 'NaN'
 -0{file_name}  : Name of a text file to use as input as alternative to taking input on STDIN.
                  See -M for additional features relating data from STDIN and another file.
 -1{c0,c1,...cn}: Increment the value stored in given column(s). Works on both integers and
                  strings. Example: 1 -1c0 => 2, aaa -1c0 => aab, zzz -1c0 => aaaa.
                  You can optionally change the increment step by a given value.
                  '10' '-1c0:-1' => 9.
 -2{cn:[start,[end]]} : Adds a field to the data that auto increments starting at a given integer.
                  Example: a|b|c -2'c1:100' => a|100|b|c, a|101|b|c, a|102|b|c, etc. This
                  function occurs last in the order of operations. The auto-increment value
                  will be appended to the end of the line if the specified column index is
                  greater than, or equal to, the number of columns a given line. A value
                  can be entered as a reset value to start incrementing again.
                  Example: -2c0:0,1 would output 0, 1, 0, 1, 0, ...
 -3{c0[:n],c1,...cn}: Increment the value stored in given column(s) by a given step.
                  Like -1, but you can specify a given step value like -2.
                  '10' '-1c0:-2' => 8. An invalid increment value will fail silently unless
                  -D is used.
 -4{c0,c1,...cn}: Compute difference between value in previous column. If the values in the
                  line above are numerical the previous line is subtracted from the current line.
                  If the -R switch is used the current line is subtracted from the previous line.
 -5             : Modifier used with -[g|X|Y]'any:{regex}', outputs all the values that match the regular
                  expression to STDERR.
 -6{cn:[char]}  : Displays histogram of columns' numeric value. '5' '-6c0:*' => '*****'.
                  If the column doesn't contain a whole number pipe.pl will issue an error and exit.
 -7{nth-match}  : Return after 'n'th line match of a search is output. See -g, -G, -X, -Y, -C.
 -a{c0,c1,...cn}: Sum the non-empty values in given column(s).
 -A             : Modifier that outputs line numbers from input, or if -d is used, the number 
                  of records that match the column key selection that were de-duplicated.
                  The end result is output similar to 'sort | uniq -c'. In other match
                  functions like -g, -G, -X, or -Y the line numbers of successful matches
                  are reported.
 -b{c0,c1,...cn}: Compare fields and output if each is equal to one-another.
 -B{c0,c1,...cn}: Compare fields and output if columns differ.
 -c{c0,c1,...cn}: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -C{[any|num_cols{n-m}|cn]:(gt|ge|eq|le|lt|ne|rg{n-m}|width{n-m})|cc(gt|ge|eq|le|lt|ne)cm,...}:
                  Compare column values and output line if value in column is greater than (gt),
                  less than (lt), equal to (eq), greater than or equal to (ge), not equal to (ne),
                  or less than or equal to (le) the value that follows. The following value can be
                  numeric, but if it isn't the value's comparison is made lexically. All specified
                  columns must match to return true, that is -C is logically AND across columns.
                  This behaviour changes if the keyword 'any' is used, in that case test returns
                  true as soon as any column comparison matches successfully.
                  -C supports comparisons across columns. Using the modified syntax
                  -Cc1:ccgec0 where 'c1' refers to source of the comparison data,
                  'cc' is the keyword for column comparison, 'ge' - the comparison
                  operator, and 'c0' the column who's value is used for comparison.
                  "2|1" => -Cc0:ccgec1 means compare if the value in c1 is greater
                  than or equal to the value in c1, which is true, so the line is output.
                  A range can be specified with the 'rg' modifier. Once set only numeric
                  values that are greater or equal to the lower bound, and less than equal
                  to the upper bound will be output. The range is separated with a '+'
                  character, so outputting rows that have value within range between 
                  0 and 5 is specified with -Cany:rg0+5. To output rows with values
                  between -100 and -50 is specified with -Cany:rg-100+-50.
                  Further, -Cc0:rg-5+5 is the same as -Cc0:rg-5++5, or c0 must be 
                  between -5 and 5 inclusive to be output. See also -I and -N.
                  Row output can also be controlled with the 'width' modifier.
                  Like the 'rg' modifier, you can output rows with columns of a 
                  given width. "abc|1" => -Cc0:"width0+3", or output the rows if c0
                  is between 0 and 3 characters wide.
                  Also outputs lines that match a range of expected columns. For example
                  "2|1" => -Cnum_cols:'width2-10' prints output, because the number of 
                  columns falls between 2 and 10. 'num_cols' has presidence over 
                  other comparisons.
 -d{c0,c1,...cn}: Dedups file by creating a key from specified column values
                  which is then over written with lines that produce
                  the same key, thus keeping the most recent match. Respects (-r).
 -D             : Debug switch.
 -e{[cn|any]:[uc|lc|mc|us|spc|normal_[W|w,S|s,D|d,q|Q][,...]]}: Change the case of a value 
                  in a column to upper case (uc), lower case (lc), mixed case (mc), or
                  underscore (us). An extended set of commands is available starting in version
                  0.48.00. These include (spc) to replace multiple white spaces with a
                  single x20 character, and (normal_{char}) which allows the removal of 
                  classes of characters. For example 'NORMAL_d' removes all digits, 'NORMAL_D'
                  removes all non-digits from the input string. Different classes are
                  supported based on Perl's regex class qualifiers W,w word, D,d digit,
                  and S,s whitespace. Multiple qualifiers can be separated with a '|'
                  character. For example normalize removing digits and non-word characters.
                  "23)  Line with     lots of  #'s!" -ec0:"NORMAL_d|W" => "Linewithlotsofs"
                  NORMAL_q removes single quotes, NORMAL_Q removes double quotes in field.
 -E{cn:[r|?c.r[.e]],...}: Replace an entire field conditionally, if desired. Similar
                  to the -f flag but replaces the entire field instead of a specific
                  character position. r=replacement string, c=conditional string, the
                  value the field must have to be replaced by r, and optionally
                  e=replacement if the condition failed.
                  Example: '111|222|333' '-E'c1:nnn' => '111|nnn|333'
                  '111|222|333' '-E'c1:?222.444'     => '111|444|333'
                  '111|222|333' '-E'c1:?aaa.444.bbb' => '111|bbb|333'
 -f{c0:n[.p|?p.q[.r]],...}: Flips an arbitrary but specific character conditionally,
                  where 'n' is the 0-based index of the target character. A '?' means
                  test the character equals p before changing it to q, and optionally change
                  to r if the test fails. Works like an if statement.
                  Example: '0000' -f'c0:2.2' => '0020', '0100' -f'c0:1.A?1' => '0A00',
                  '0001' -f'c0:3.B?0.c' => '000c', finally
                  echo '0000000' | pipe.pl -f'c0:3?1.This.That' => 000That000.
 -F[c0:[b|c|d|h][.[b|c|d|h]],...}: Outputs the field in character (c), binary (b), decimal (d)
                  or hexidecimal (h). A single radix defines the desired output and assumes
                  decimal input. A second radix (delimited from the first with a '.') instructs
                  pipe.pl to convert from radix 'a' to radix 'b'. Example -Fc0:b.h specifies
                  the input as binary, and outputs hexidecimal: '1111' -Fc0:b.h => 'f'
 -g{[any|cn]:regex,...}: Searches the specified field for the Perl regular expression.
                  Example data: 1481241, -g"c0:241$" produces '1481241'. Use
                  escaped commas specify a ',' in a regular expression because comma
                  is the column definition delimiter. Selecting multiple fields acts
                  like an AND function, all fields must match their corresponding regex
                  for the line to be output. The behaviour of -g turns into OR if the
                  keyword 'any' is used. In that case all other column specifications
                  are ignored and any successful match will return true.
                  Comparisons across columns is also possible, by omitting the regex for a given column.
                  Columns with empty regular expressions will be compared to the first regex specified.
                  Example: "a|b|c|b|d" '-gc1:b,c3:' => "a|b|c|b|d" succeeds because c3 matches
                  c1 as specified in the first expression 'c1:b', while
                  "a|b|c|b|d" '-gc2:c,c3:' => nil because the value in c3 doesn't match 'c' of c2.
                  If the first column's regex is empty, the value of the first column is used
                  as the regex in subsequent columns' comparisons. "a|b|c|b|d" '-gc1:,c3:' => "a|b|c|b|d"
                  succeeds because the value in c1 matches the value in c3. Behaviour changes
                  if used in combination with -X and -Y. The -g outputs just the frame that is 
                  bounded by -X and -Y, but if -g matches, only the matching frame is output 
                  to STDERR, while only the -g that matches within the frame is output to STDOUT. 
 -G{[any|cn]:regex,...}: Inverse of -g, and can be used together to perform AND operation as
                  return true if match on column 1, and column 2 not match. If the keyword
                  'any' is used, all columns must fail the match to return true. Empty regular
                  expressions are permitted. See -g for more information.
 -h             : Change delimiter from the default '|'. Changes -P and -K behaviour, see -P, -K.
 -H             : Suppress new line on output.
 -i             : Turns on virtual matching for -b, -B, -C, -g, -G, -z and -Z. Normally fields are 
                  conditionally suppressed or output depending on the above conditional flags. '-i'  
                  allows further modifications on lines that match these conditions, while allowing 
                  all other lines to pass through, in order, unmodified.
 -I             : Ignore case on operations -b, -B, -C, -d, -E, -f, -g, -G, -l, -n and -s.
 -j             : Removes the last delimiter from the last processed line. See -P, -K, -h.
 -J{cn}         : Sums the numeric values in a given column during the dedup process (-d)
                  providing a sum over group-like functionality. Does not work if -A is selected
                  (see -A).
 -k{cn:expr,(...)}: Use perl scripting to manipulate a field. Syntax: -kcn:'(script)'
                  The existing value of the column is stored in an internal variable called '\$value'
                  and can be manipulated and output as per these examples.
                  "13|world"    => -kc0:'\$a=3; \$b=10; \$value = \$b + \$a;'
                  "hello|worle" => -kc1:'\$value++;'
                  Note use single quotes around your script.
                  If ALLOW_SCRIPTING is set to FALSE, pipe.pl will issue an error and exit.
 -K             : Use line breaks instead of the current delimiter between columns (default '|').
                  Turns all columns into rows.
 -l{[any|c0]:exp,... }: Translate a character sequence if present. Example: 'abcdefd' -l"c0:d.P".
                  produces 'abcPefP'. 3 white space characters are supported '\\s', '\\t',
                  and '\\n'. "Hello" -lc0:"e.\\t" => 'H       llo'
                  Can be made case insensitive with '-I'. Quote all expressions.
 -L{[[+|-]?n-?m?|skip n]}: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Multiple
                  requests can be comma separated like this -L'1,3,8,23-45,12,-100'.
                  The 'skip' keyword will output alternate lines. 'skip2' will output every other line.
                  'skip 3' every third line and so on. The skip keyword takes precedence over
                  over other line output selections in the -L flag.
 -m{cn:*[_|#]*} : Mask specified column with the mask defined after a ':', and where '_'
                  means suppress, '#' means output character, any other character at that
                  position will be inserted.
                  If the last character is either '_' or '#', then it will be repeated until
                  the input line is exhausted.
                  Characters '_', '#' and ',' can be output by escaping them with a back slash.
                  Example data: 1481241, -m"c0:__#" produces '81241'. -m"c0:__#_"
                  produces '8' and suppress the rest of the field.
                  Example data: E201501051855331663R,  -m"c0:_####/##/## ##:##:##_"
                  produces '2015/01/05 18:55:33'.
                  Example: 'ls *.txt | pipe.pl -m"c0:/foo/bar/#"' produces '/foo/bar/README.txt'.
                  Use '\' to escape either '_', ',' or '#'.
 -M             : Allows columns of values read from STDIN to be compared to any columns' values
                  from another file using -0. Thus for all rows, and any column from STDIN,
                  if a specific column from -0 matches, any columns from the -0 input line are
                  appended as the last column, and written to STDOUT.
                  Multiple columns from -0 input are delimited with '+'. 
                  If no lines from -0 input match, an optional literal is appended as the
                  last column. Use -V if you want zero (0) used as a literal.
                  Example: cat {file1} => -0{file2} -M"c1:c0?c1.'None'"
                  Compare file1, c1 to file2, c0, and if they match output file2, c1 else 'None'.
                  Both files must use the same column delimiter, and any use of -W will
                  apply to both. Matching behaviour can also be modified with -I and -N.
 -n{[any|cn],...}: Normalize the selected columns, that is, removes all non-word characters
                  (non-alphanumeric and '_' characters). The -I switch leaves the value's case
                  unchanged. However the default is to change the case to upper case. See -N,
                  -I switches for more information.
 -N             : Normalize keys before comparison when using (-d, -C, and -s) dedup and sort.
                  Normalization removes all non-word characters before comparison. Use the -I
                  switch to preserve keys' case during comparison. See -n, and -I.
                  Outputs absolute value of -a, -v, -1, -3, -4, results.
                  Causes summaries to be output with delimiter to STDERR on last line.
 -o{c0,c1,...,cn[,continue][,last][,remaining][,reverse][,exclude]}: Order the columns in a different order. 
                  Only the specified columns are output unless the keyword 'remaining', or 'continue'.  
                  The 'remaining' keyword outputs all columns that have not already been specified, 
                  in order. The 'continue' keyword outputs all the columns from the last specified 
                  column to the last column in the line. 'last' will output the last column in a row.
                  'reverse' reverses the column order. Exclude will output all columns except those mentioned.
                  The order of the columns cannot be altered with this keyword. Once a keyword is encountered 
                  (except 'exclude'), any additional column output request is ignored.
 -O{[any|cn],...}: Merge columns. The first column is the anchor column, any others are appended to it
                  ie: 'aaa|bbb|ccc' -Oc2,c0,c1 => 'aaa|bbb|cccaaabbb'. Use -o to remove extraneous columns.
                  Using the 'any' keyword causes all columns to be merged in the data in column 0.
 -p{c0:n.char,... }: Pad fields left or right with arbitrary 'N' characters. The expression is separated by a
                  '.' character. '123' -pc0:"-5", -pc0:"-5.\\s" both do the same thing: '123  '. Literal
                  digit(s) can be used as padding. '123' -pc0:"-5.0" => '12300'. Spaces are qualified 
                  with either '\\s', '\\t', '\\n', or '_DOT_' for a literal period.
 -P             : Ensures a tailing delimiter is output at the end of all lines.
                  The default delimiter of '|' can be changed with -h.
 -q{lines}      : Modifies '-H' behaviour to allow new lines for every n-th line of output.
                  This has the effect of joining n-number of lines into one line.
 -Q{lines}      : Output 'n' lines before and line after a -g, or -G match to STDERR. Used to
                  view the context around a match, that is, the line before the match and the line after.
                  The lines are written to STDERR, and are immutable. The line preceding a match
                  is denoted by '<=', the line after by '=>'. If the match occurs on the first line
                  the preceding match is '<=BOF', beginning of file, and if the match occurs on
                  the last line the trailing match is '=>EOF'. The arrows can be suppressed with -N.
 -r{percent}    : Output a random percentage of records, ie: -r100 output all lines in random
                  order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
 -R             : Reverse sort (-d, -4 and -s).
 -s{c0,c1,...cn}: Sort on the specified columns in the specified order.
 -S{c0:range}   : Sub string function. Like mask, but controlled by 0-based index in the columns' strings.
                  Use '.' to separate discontinuous indexes, and '-' to specify ranges.
                  Ie: '12345' -S'c0:0.2.4' => '135', -S'c0:0-2.4' => '1235', and -S'c0:2-' => '345'.
                  Note that you can reverse a string by reversing your selection like so:
                  '12345' -S'c0:4-0' => '54321', but -S'c0:0-4' => '1234'. Removal of characters
                  from the end of data can be specified with syntax (n - m), where 'n' is a literal
                  and represents the length of the data, and 'm' represents the number of characters
                  to be trimmed from the end of the line, ie '12345' => -S'c0:0-(n -1)' = '1234'.
 -t{[any|cn],...}: Trim the specified columns of white space front and back. If -y is
                   used, the string is trimmed of any leading, trailing whitespace, then
                   is truncated (from the back) to the length specified by -y.
 -T{HTML[:attributes]|WIKI[:attributes]|MD[:attributes]|CSV[:col1,col2,...,coln]}
                : Output as a Wiki table, Markdown, CSV or an HTML table, with attributes.
                  CSV:Name,Date,Address,Phone
                  HTML also allows for adding CSS or other HTML attributes to the <table> tag.
                  A bootstrap example is '1|2|3' -T'HTML:class="table table-hover"'.
 -u{[any|cn],...}: Encodes strings in specified columns into URL safe versions.
 -U             : Sort numerically. Multiple fields may be selected, but an warning is issued
                  if any of the columns used as a key, combined, produce a non-numeric value
                  during the comparison. With -C, non-numeric value tests always fail, that is
                  '12345a' -C'c0:ge12345' => '12345a' but '12345a' -C'c0:ge12345' -U fails.
 -v{c0,c1,...cn}: Average over non-empty values in specified columns.
 -V             : Validate that the output has the same number of columns as the input.
 -w{c0,c1,...cn}: Report min and max number of characters in specified columns, and reports
                  the minimum and maximum number of columns by line.
 -W{delimiter}  : Break on specified delimiter instead of '|' pipes, ie: "\^", and " ".
 -x             : This (help) message.
 -X{[any|cn]:regex,...}: Like the -g, but once a line matches all subsequent lines are also
                  output until a -Y match succeeds. See -Y and -g.
                  If the keyword 'any' is used the first column to match will return true.
                  Also allows comparisons across columns.
 -y{precision}  : Controls precision of computed floating point number output. Forces -t to
                  chop selected columns to specific lengths.
 -Y{[any|cn]:regex,...}: Turns off further line output after -X match succeeded. See -X and -g.
 -z{c0,c1,...cn}: Suppress line if the specified column(s) are empty, or don't exist. See -i.
 -Z{c0,c1,...cn}: Show line if the specified column(s) are empty, or don't exist. See -i.
```

**Note**: I recommend that you put your command line flags in alphabetical order as in the example below.
Order of operations
-------------------
The order of operations is as follows:
```
  -x - Usage message, then exits.
  -G - Inverse grep specified columns.
  -g - Grep values in specified columns.
  -C - Conditionally test column values.
  -b - Suppress line output if columns' values differ.
  -B - Only show lines where columns are different.
  -Z - Show line output if column(s) test empty.
  -z - Suppress line output if column(s) test empty.
  -y - Specify precision of floating computed variables, or trim string to length.
  -0 - Input from named file. (See also -M).
  -X - Grep values in specified columns, start output, or start searches for -Y values.
  -Y - Grep values in specified columns once greps with -X succeeds.
  -d - De-duplicate selected columns.
  -r - Randomize line output.
  -s - Sort columns.
  -v - Average numerical values in selected columns.
  -? - Perform math operations on columns.
  -1 - Increment value in specified columns.
  -3 - Increment value in specified columns by a specific step.
  -4 - Output difference between this and previous line.
  -k - Run perl script on column data.
  -L - Output only specified lines, or range of lines.
  -A - Displays line numbers or summary of duplicates if '-d' is selected.
  -J - Displays sum over group if '-d' is selected.
  -u - Encode specified columns into URL-safe strings.
  -e - Change case and normalize strings.
  -E - Replace string in column conditionally.
  -f - Modify character in string based on 0-based index.
  -F - Format column value into bin, hex, or dec.
  -7 - Stop search after n-th match.
  -i - Output all lines, but process only if -b, -B, -C, -g, -G, -z or -Z match.
  -5 - Output all -g 'any' keyword matchs to STDERR.
  -Q - Output 'n' lines before and after a '-g', or '-G' match to STDERR.
  -m - Mask specified column values.
  -S - Sub string column values.
  -l - Translate character sequence.
  -n - Remove non-word characters in specified columns.
  -t - Trim selected columns.
  -I - Ignore case on operations -b, -B, -C, -d, -E, -f, -g, -G, -l, -n and -s.
  -R - Reverse line order when -d, -4 or -s is used.
  -b - Suppress line output if columns' values differ.
  -B - Only show lines where columns are different.
  -w - Output minimum an maximum width of column data.
  -a - Sum of numeric values in specific columns.
  -c - Count numeric values in specified columns.
  -T - Output in table form.
  -V - Ensure output and input have same number of columns.
  -K - Output everything as a single column.
  -O - Merge selected columns.
  -o - Order selected columns.
  -2 - Add an auto-increment field to output.
  -6 - Histogram column(s) value.
  -P - Add additional delimiter if required.
  -H - Suppress new line on output.
  -q - Selectively allow new line output of '-H'.
  -h - Replace default delimiter.
  -j - Remove last delimiter on the last line of data output.
  -N - Normalize summaries, keys before comparisons, abs(result). Strips formatting.
```

== Simple math operations over columns ==
```
$ echo "1|2|0|10|1" | pipe.pl -?sub:c0,c1,c2,c3,c4
-12|1|2|0|10|1
$ echo "1|2|0|10|1" | pipe.pl -?add:c0,c1,c2,c3,c4
14|1|2|0|10|1
$ echo "1|2|0|10|1" | pipe.pl -?mul:c0,c1,c2,c3,c4
0|1|2|0|10|1
$ echo "1|2|0|10|1" | pipe.pl -?div:c0,c1,c2,c3,c4
0.05|1|2|0|10|1
```

== Matching values between files
Sometimes it's handy to be able to reference values in another file and append them to the output conditionally. An example is a list of catalog keys and titles in one file, while the data coming in from STDIN contains an item key. If we wanted to append the title to the data from STDIN referencing the titles from file from -0, we can do that with the -M switch and -0 switch.
```
$ head a b
==> a <==
1000048|6|15|
1000048|10|2|
1000048|10|4|
1000048|30|5|
1000048|30|6|
1000048|36|7|
1000048|61|1|
1000048|119|3|
1000048|128|1|
1000048|140|1|

==> b <==
1000048|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain|
$
$ cat a | pipe.pl -0b -Mc0:c0?c1
1000048|6|15|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|10|2|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|10|4|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|30|5|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|30|6|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|36|7|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|61|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|119|3|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|128|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|140|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|140|2|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|141|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|142|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|143|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
1000048|145|1|The Berenstain Bears and mama for mayor! / Jan & Mike Berenstain
```

More generally you can specify that matches should be normalized before comparison.
```
$ head M.lst zero.lst                             ==> M.lst <==
1|one
2|TWO
3|ThReE

==> zero.lst <==
one|1
two|2
4|four
threE|3
$ cat M.lst | pipe.pl -0zero.lst -Mc1:c0?c0."No match"
1|one|one
2|TWO|No match
3|ThReE|No match
$ cat M.lst | pipe.pl -0zero.lst -Mc1:c0?c0."No match" -N
1|one|one
2|TWO|two
3|ThReE|threE
```


Exit searches after 'n' matches
---
Works like '-m' in modern grep, stops searches after 'n'-th successful match. Works with '-g', '-G', '-X', '-Y', and has precedence over '-i'.
```
$ cat Y.lst
1|a
2|b
3|c
4|d
5|e
1|f
2|g
3|h
4|i
5|j
$ cat Y.lst | pipe.pl -71 -gc0:5
5|e
```


Displaying histogram of a columns value.
---
Shows a histogram of the column's value. If the value in the column
is not a whole, positive number, pipe.pl will issue an error message
and exit.
```
$ cat 6.lst
2017-09-22|1
2017-09-23|2
2017-09-24|3
2017-09-25|4
2017-09-26|5
$ cat 6.lst | pipe.pl -6c1:*
2017-09-22|*
2017-09-23|**
2017-09-24|***
2017-09-25|****
2017-09-26|*****
```
Computing differences between one line and the next
---------------------------------------------------
One common problem I face is I have a column of values, but I want to output the difference
between this lines value and the previous for a given column. To do that use '-4'. 
Example:
```
cat d.lst
1|10
2|10
3|10
4|10
5|10
7|10
9|10
11|10
15|10
19|10
23|10
```
Now try the following.
```
cat d.lst | pipe.pl -4'c0'
1|10
1|10
1|10
1|10
1|10
2|10
2|10
2|10
4|10
4|10
4|10
cat d.lst | pipe.pl -4'c1'
1|10
2|0
3|0
4|0
5|0
7|0
9|0
11|0
15|0
19|0
23|0
```

Using virtual matching with -i
----------------------
Sometimes you want to modify a column but only if some value in another column matches
a given expression. For example, given the following file, 
```
cat test.lst
 86019|4|
 86020|9|
 86019|7|
 86020|0|
 86019|0|
 86022|1|
```
flip the value in c1 to an '8' but only if the value in c0 = '86019'.
```
cat test.lst | pipe.pl -g'c0:86019' -i -f'c1:0.8'
86019|8
86020|9
86019|8
86020|0
86019|8
86022|1
```
The -i flag tells -g and -G to continue to ouput, match or no, but only process other flags if -g or -G match.

Increment a column number by a given step
-----------------------------------------
The '-3' switch allows you to increment a given set of columns by a given step.
```
echo 10 | pipe.pl -3'c0:-1'
9
echo 10 | pipe.pl -3'c0:2'
12
echo 10 | pipe.pl -3'c0:2.1'
12.1
echo 10 | pipe.pl -3'c0:2.1.3'
10
echo 10 | pipe.pl -3'c0:2.1.3' -D
columns requested: '0'
* warning invalid increment value: '2.1.3'
original: 0, modified: 0 fields at line number 1.
10
```

Using -5 to see the matching field with -g:any
----------------------------------------------
When using '-g' and the keyword 'any' for any column match adding -5 will output the match to STDERR. Consider the following data.
```
cat z.lst
21221023942342|EPL-ADU1FR|EPLMLW|ECONSENT|john.smith@mymail.org|20150717|
21221023464206|EPL-JUV|EPLMNA|EMAILCONV||20150717|
21221024955293|EPL-ADULT|EPLJPL|ENOCONSENT||20150717|
```
```
cat z.lst | pipe.pl -g"any:CONSENT" -5 >/dev/null
ECONSENT
ENOCONSENT
```
Another example.
```
cat z.lst | pipe.pl -g"any:CONSENT|2015" -5
ECONSENT
21221023942342|EPL-ADU1FR|EPLMLW|ECONSENT|john.smith@mymail.org|20150717|
20150717
21221023464206|EPL-JUV|EPLMNA|EMAILCONV||20150717|
ENOCONSENT
21221024955293|EPL-ADULT|EPLJPL|ENOCONSENT||20150717|
```
So you may notice that the 20150717 from first line didn't output. The reason is -g"any" returns immediately as soon as the regex matches, returning only the first match from the line. 

Another example with multiple matches. Using a line from a history log, find all NQ fields, all 'aA' fields, and all fields that start with 'S7', outputing all matches - but just the matches.
```
echo "E201405271803190011R ^S75FVFFADMIN^FEEPLMNA^FcNONE^NQ31221079015892^NOY^NSEPLJPL^IUa554837^tJ554837^aA(OCoLC)56729751^^O00099" | pipe.pl -W'\^' -g"any:IU|aA|S7" -5 >/dev/null
S75FVFFADMIN|IUa554837|aA(OCoLC)56729751
```

Add an auto-increment column
----------------------------
With '-2' you can add an auto-increment column with a default of '0' as an initial value.
```
cat p.lst | pipe.pl -2c0
0|1|2|3
1|1|2|4
2|1|2|4
3|1|2|3
```

Here we set the initial value to 999, and start counting from there.
```
cat p.lst | pipe.pl -2c100:999
1|2|3|999
1|2|4|1000
1|2|4|1001
1|2|3|1002
```

You aren't restricted to integers either. Try specifying a string as an initial value.
```
cat p.lst | pipe.pl -2c100:a
1|2|3|a
1|2|4|b
1|2|4|c
1|2|3|d
```
You may also reset the counting in a column with adding an additional parameter separated by a comma ("'").
```
$ cat p.lst | pipe.pl -2c100:a,b
1|2|3|a
1|2|4|b
1|2|4|a
1|2|3|b
```

Incrementing values in a column
-------------------------------
The ironic '-1' allows you to increment the values in a column.
```
echo 9 | pipe.pl -1c0
10
echo 'aaa' | pipe.pl -1c0
aab
echo 'zzz' | pipe.pl -1c0
aaaa
```

Merging columns
---------------
Using -O you can merge any specified columns into an arbitrary but specific column.
You specify columns as you do any other option in pipe, but the first column you identify
becomes the target column to which any other specified column, or columns are appended.
Examples:
```
echo 'aaa|bbb|ccc' | pipe.pl -Oc0,c1
aaabbb|bbb|ccc
echo 'aaa|bbb|ccc' | pipe.pl -Oc1,c0
aaa|bbbaaa|ccc
echo 'aaa|bbb|ccc' | pipe.pl -Oc2
aaa|bbb|ccc
echo 'aaa|bbb|ccc' | pipe.pl -Oc99  # Huh?
aaa|bbb|ccc
echo 'aaa|bbb|ccc' | pipe.pl -Oc99 -D
columns requested: '99'
** warning: merge target 'c99' doesn't exist in line 'aaa...'.
original: 2, modified: 2 fields at line number 1.
aaa|bbb|ccc
echo 'aaa|bbb|ccc' | pipe.pl -Oany
aaabbbccc|bbb|ccc
```
To remove extraneous columns use '-o' to order the column(s) output.

Quoted strings
--------------
Data can be easily converted into CSV as show below, but use '''-T"CVS:Optional,Column,Titles"''' 
to do this automatically.
```
cat data.lst | pipe.pl -TCVS
911677,"J 927.824 SWI, RYA"
612856,"E HAR"
1442211,"EGA"
758054,"DVD FLI"
1100335,"Large Print WIN"
708437,"General fiction, G PBK"
1488252,"746.43204 FIF"
362834,"CD POP ROCK MET"
1142623,"DVD J DIG"
1423109,"DVD INT"
851760,"364.10922 MAR"
884413,"DVD LIL v.3"
1487346,"ON-ORDER"
619767,"DVD IN"
```

Ordering, sorting, and splitting on non-pipe character
------------------------------------------------------
```
head file
Catkey 1456824 has 114 T024's
Catkey 1458347 has 136 T024's
Catkey 1458804 has 284 T024's
Catkey 1462712 has 153 T024's
Catkey 1463986 has 174 T024's
Catkey 1465362 has 195 T024's
Catkey 1465466 has 206 T024's
Catkey 1465861 has 116 T024's
Catkey 1467080 has 157 T024's
Catkey 1468840 has 100 T024's
Catkey 1478591 has 207 T024's
```

For all records we are only interested in field 2 (index 1) and field 4 (index 3). We want a count of lines in the file and a summation of index 3, but we don't need the other fields.

```
cat file | pipe.pl -a'c3' -c'c0' -o'c1,c3' -s'c0' -W" "
1456824|114
1458347|136
1458804|284
1462712|153
1463986|174
1465362|195
1465466|206
1465861|116
1467080|157
1468840|100
...
== count
c0:      31
=== sum ===
c3:    5641
```

Here c3 was summed up, then a count of all lines each line was then ordered and finally we sorted the list by c0, which is where index 3 ended up after ordering.


Grepping a specific field value, and counting the results
---------------------------------------------------------
You can specify a regular expression that will be applied to the contents of specific columns. This flag has precedence over other flags, and if the column specified matches the regex, the line is output for other operators.

```
cat test.lst | pipe.pl -W' '  -cc3 -ac3 -vc3
Catkey|1456824|has|114|T024's
Catkey|1458347|has|136|T024's
Catkey|1458804|has|284|T024's
Catkey|1462712|has|153|T024's
Catkey|1463986|has|174|T024's
Catkey|1465362|has|195|T024's
Catkey|1465466|has|206|T024's
Catkey|1465861|has|116|T024's
Catkey|1467080|has|157|T024's
Catkey|1468840|has|100|T024's
Catkey|1469205|has|157|T024's
Catkey|1469335|has|135|T024's
Catkey|1471170|has|102|T024's
Catkey|1474195|has|168|T024's
Catkey|1474421|has|172|T024's
Catkey|1474423|has|301|T024's
Catkey|1474761|has|102|T024's
Catkey|1475077|has|101|T024's
Catkey|1475754|has|126|T024's
Catkey|1475760|has|109|T024's
Catkey|1476430|has|410|T024's
Catkey|1477339|has|195|T024's
Catkey|1477343|has|101|T024's
Catkey|1478189|has|167|T024's
Catkey|1478591|has|207|T024's
Catkey|1478687|has|624|T024's
Catkey|1478965|has|165|T024's
Catkey|1479679|has|116|T024's
Catkey|1480485|has|168|T024's
Catkey|1481038|has|246|T024's
Catkey|1481241|has|134|T024's
== count
 c3:      31
==   sum
 c3:    5641
== average
 c3:  181.97
cat t.lst | pipe.pl -W' ' -G'c3:^1..' -c'c0'
Catkey|1458804|has|284|T024's
Catkey|1465466|has|206|T024's
Catkey|1474423|has|301|T024's
Catkey|1476430|has|410|T024's
Catkey|1478591|has|207|T024's
Catkey|1478687|has|624|T024's
Catkey|1481038|has|246|T024's
== count
c0:       7
cat t.lst | pipe.pl -W' ' -g'c1:^148' -G'c3:2.6' -c'c0'
Catkey|1480485|has|168|T024's
Catkey|1481241|has|134|T024's
== count
 c0:       2
```
```
cat t.lst | pipe.pl -W' ' -g'c3:^20.$'  -c'c0'
Catkey|1465466|has|206|T024's
Catkey|1478591|has|207|T024's
== count
c0:       2
```

Ignoring case on comparisons
----------------------------
Some switches like -d, -E, -f, -g, -G, -n, and -s, can be made more flexible by using the -I ignore case switch. For example.
```
echo ABC | pipe -f'c0:1?b.7'
ABC
echo ABC | pipe -f'c0:1?b.7' -I
A7C
echo 'aaa|bbb|ccc' | pipe -E'c1:BBB'
aaa|BBB|ccc
echo 'aaa|bbb|ccc' | pipe -E'c1:?BBB.777'
aaa|bbb|ccc
echo 'aaa|bbb|ccc' | pipe -E'c1:?BBB.777' -I
aaa|777|ccc
```
Using '-Q' in conjunction with '-g' and '-G'
--------------------------------------------
The -Q flag will display the context of a search with -g and -G. Sometimes it is useful to be able to see what the line before
and after a match looks like. I will demonstrate with the following data set.
```
 86019|4|
 86019|9|
 86019|7|
 86020|0|
 86021|0|
 86022|1|
```
Again finding the line that has '7' in the second column is done like so.
```
cat test.lst | pipe.pl -g'c1:7'
86019|7
```
Now with -Q
```
cat test.lst | pipe.pl -g'c1:7' -Q
<=86019|9|  # Note: these lines are immutable and appear on STDERR.
86019|7
=>86020|0|
cat test.lst | pipe.pl -g'c1:4' -Q
<=BOF
86019|4
=>86019|9|
cat test.lst | pipe.pl -g'c1:1' -Q
<=86021|0|
86022|1
=>EOF
```
This is what happens if 2 lines match, one after another.
```
cat test.lst | pipe.pl -g'c1:0' -Q
<=86019|7|
86020|0
=>86021|0|
<=86020|0
86021|0
=>86022|1|
```

Using masks
-----------
Masks work using two special characters '\#' to print a character, and '\_' to suppress a character. Any other character is output as-is, in order, until both the mask and the input string are exhausted. The special characters can also be output as literals if they are escaped with a back slash '\\'.
If the last character of the mask is a special character '\#' or '\_', the default behavior is to output, or suppress, the rest of the contents of the field.
```
echo 'abcd' | pipe.pl -m'c0:#'
abcd
echo 'abcd' | pipe.pl -m'c0:#_'
a
echo 'abcd' | pipe.pl -m'c0:#_#'
acd
echo 'abcd' | pipe.pl -m'c0:/foo/bar/#\_'
/foo/bar/a_
echo 'abcd' | pipe.pl -m'c0:/foo/bar/________________.List'
/foo/bar/.List
echo 'abcd' | pipe.pl -m'c0:/foo/bar/\_\_\_\_\_\_.List'
/foo/bar/______.List
echo 'abcd' | pipe.pl -m'c0:/foo/bar/#\#'
/foo/bar/a#
echo 'Balzac Billy, 21221012345678' | pipe.pl -W',' -m'c0:####_...,c1:___________#'
Balz...|5678
```
Reading the schedule of printed reports (printlist) is much easier with pipe than rptstat.pl.
```
cat printlist | pipe.pl -g'c5:adutext' -o'c0,c2,c3' | pipe.pl -m'c1:####-##-##_,c0:/s/sirsi/Unicorn/Rptprint/####.prn'
...
/s/sirsi/Unicorn/Rptprint/mxnd.prn|2015-05-29|OK
/s/sirsi/Unicorn/Rptprint/mxrt.prn|2015-05-30|OK
/s/sirsi/Unicorn/Rptprint/mxva.prn|2015-05-31|OK
/s/sirsi/Unicorn/Rptprint/myhf.prn|2015-06-01|ERROR
/s/sirsi/Unicorn/Rptprint/mypu.prn|2015-06-03|OK
/s/sirsi/Unicorn/Rptprint/mzbb.prn|2015-06-03|OK
...
```
Given the following history file entries:
```
...
E201411051046470005R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815538^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411051046470005R ^S02JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815504^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411051046470005R ^S03JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815512^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411081238191637R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLRIV^UO21221014186727^Uf8451^NQ31221106815504^HB11/08/2015^HKTITLE^HOEPLRIV^^O00108
E201411081238191637R ^S02JZFFBIBLIOCOMM^FcNONE^FEEPLRIV^UO21221014186727^Uf8451^NQ31221106815512^HB11/08/2015^HKTITLE^HOEPLRIV^^O00108
...
```

Output the user IDs and item IDs, the date without '-' and the last 3 characters of the library code.
```
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o'c3,c4,c6,c7' -m'c3:_____###,c4:__#,c6:__#,c7:__##_##_####'
CPL|21221019966206|31221106815538|11052015
CPL|21221019966206|31221106815504|11052015
CPL|21221019966206|31221106815512|11052015
RIV|21221014186727|31221106815504|11082015
RIV|21221014186727|31221106815512|11082015
LON|21221022260092|31221106815496|11122015
LON|21221022260092|31221106815520|11122015
LON|21221022260092|31221106815504|11122015
LON|21221022260092|31221106815512|11122015
WMC|21221019655684|31221106815504|11172015
```

Want to order it by item ID?
```
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o'c3,c4,c6,c7' -m'c3:_____###,c4:__#,c6:__#,c7:__##_##_####' -s'c2'
LON|21221022260092|31221106815496|11122015
CPL|21221019966206|31221106815504|11052015
LON|21221022260092|31221106815504|11122015
RIV|21221014186727|31221106815504|11082015
WMC|21221019655684|31221106815504|11172015
CPL|21221019966206|31221106815512|11052015
LON|21221022260092|31221106815512|11122015
RIV|21221014186727|31221106815512|11082015
LON|21221022260092|31221106815520|11122015
CPL|21221019966206|31221106815538|11052015
```

Output as tables
----------------
Pipe supports currently supports output as HTML, Mark Down, or MediaWiki table format. Using the data from the previous example I have 
removed the non-'-T' switch settings for clarity.
```
bash-3.2$ head holds_1411.lst | pipe.pl ... -T'HTML'
<table>
  <tbody>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815504</td><td>11052015</td></tr>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815512</td><td>11052015</td></tr>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815538</td><td>11052015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815496</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815504</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815512</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815520</td><td>11122015</td></tr>
  <tr><td>RIV</td><td>21221014186727</td><td>31221106815504</td><td>11082015</td></tr>
  <tr><td>RIV</td><td>21221014186727</td><td>31221106815512</td><td>11082015</td></tr>
  <tr><td>WMC</td><td>21221019655684</td><td>31221106815504</td><td>11172015</td></tr>
  </tbody>
</table>
```

You can add attributes to the outer table tag. 
```
bash-3.2$ head holds_1411.lst | pipe.pl ... -T'HTML:class="table table-hover"'
<table class="table table-hover">
  <tbody>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815504</td><td>11052015</td></tr>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815512</td><td>11052015</td></tr>
  <tr><td>CPL</td><td>21221019966206</td><td>31221106815538</td><td>11052015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815496</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815504</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815512</td><td>11122015</td></tr>
  <tr><td>LON</td><td>21221022260092</td><td>31221106815520</td><td>11122015</td></tr>
  <tr><td>RIV</td><td>21221014186727</td><td>31221106815504</td><td>11082015</td></tr>
  <tr><td>RIV</td><td>21221014186727</td><td>31221106815512</td><td>11082015</td></tr>
  <tr><td>WMC</td><td>21221019655684</td><td>31221106815504</td><td>11172015</td></tr>
  </tbody>
</table>
```

You can also create CSV output as follows.
```
cat z.lst | ./pipe.pl -T'CSV:User ID,Profile,Branch,Consent type,Email,Date of last activity'
"User ID","Profile","Branch","Consent type","Email","Date of last activity"
21221023942342,"EPL-ADU1FR","EPLMLW","ECONSENT","joseph.stewart@myldsmail.net",20150717
21221023464206,"EPL-JUV","EPLMNA","EMAILCONV","",20150717
21221024955293,"EPL-ADULT","EPLJPL","ENOCONSENT","",20150717
```

Masking and tables
------------------
A new feature in -m to allow arbitrary characters to be inserted. For data like this:

```
E201411051046470005R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815538^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411051046470005R ^S02JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815504^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411051046470005R ^S03JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815512^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108
E201411081238191637R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLRIV^UO21221014186727^Uf8451^NQ31221106815504^HB11/08/2015^HKTITLE^HOEPLRIV^^O00108
E201411081238191637R ^S02JZFFBIBLIOCOMM^FcNONE^FEEPLRIV^UO21221014186727^Uf8451^NQ31221106815512^HB11/08/2015^HKTITLE^HOEPLRIV^^O00108
```

Try
```
bash-3.2$  cat s.lst | pipe.pl -W"\^" -o'c0,c3' -m'c0:_####/##/## ##:##:##_,c3:_____###' -T'HTML'
<table>
  <tbody>
  <tr><td>2014/11/05 10:46:47</td><td>CPL</td></tr>
  <tr><td>2014/11/05 10:46:47</td><td>CPL</td></tr>
  <tr><td>2014/11/05 10:46:47</td><td>CPL</td></tr>
  <tr><td>2014/11/08 12:38:19</td><td>RIV</td></tr>
  <tr><td>2014/11/08 12:38:19</td><td>RIV</td></tr>
  </tbody>
</table>
```
... or in MediaWiki format:
```
bash-3.2$  cat s.lst | pipe.pl -W"\^" -o'c0,c3' -m'c0:_####/##/## ##:##:##_,c3:_____###' -T'WIKI'
{| class='wikitable'
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/08 12:38:19 || RIV
|-
| 2014/11/08 12:38:19 || RIV
|-|-
|}
```

... and further:
```
bash-3.2$  cat s.lst | pipe.pl -W"\^" -o'c0,c3' -m'c0:_####/##/## ##:##:##_,c3:_____###' -T'WIKI:cellpadding=5 style="border:1px solid #BBB"'
{| class='wikitable' cellpadding=5 style="border:1px solid #BBB"
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/05 10:46:47 || CPL
|-
| 2014/11/08 12:38:19 || RIV
|-
| 2014/11/08 12:38:19 || RIV
|-|-
|}
```


Formatting Unix tool outputs like **ls -la**, and a handy hack with masks
-------------------------------------------------------------------------
To get a list of all the Symphony history files from a 12 month period starting June of 2014 to June 2015
```
ls -l {$HIST_DIRECTORY} | pipe.pl -W'\s+' -g'c8:(2014(0[6-9]|1[0-2])|20150[1-6])'
-rw-r--r--   1 sirsi    sirsi    102193407 Jul  1  2014 201406.hist.Z
-rw-r--r--   1 sirsi    sirsi    108121444 Aug  1  2014 201407.hist.Z
-rw-r--r--   1 sirsi    sirsi    104152833 Sep  1  2014 201408.hist.Z
-rw-r--r--   1 sirsi    sirsi    105069921 Oct  1  2014 201409.hist.Z
-rw-r--r--   1 sirsi    sirsi    101697441 Nov  1  2014 201410.hist.Z
-rw-r--r--   1 sirsi    sirsi    102343923 Dec  1  2014 201411.hist.Z
-rw-r--r--   1 sirsi    sirsi    102214661 Jan  1 00:05 201412.hist.Z
-rw-r--r--   1 sirsi    sirsi    104051909 Feb  1 00:05 201501.hist.Z
-rw-r--r--   1 sirsi    sirsi    97355207 Mar  1 00:05 201502.hist.Z
-rw-r--r--   1 sirsi    sirsi    109503879 Apr  8 00:05 201503.hist.Z
-rw-r--r--   1 sirsi    sirsi    104102435 May  1 00:05 201504.hist.Z
-rw-r--r--   1 sirsi    sirsi    112107549 Jun  3 00:18 201505.hist.Z
-rw-r--r--   1 sirsi    sirsi    276267771 Jun 18 00:05 201506.hist
-rw-r--r--   1 sirsi    sirsi    3390599 Jun 18 10:12 20150618.hist
```

If you just want the file names you could just use ls but that is boring so let's use pipe.
```
ls -l {$HIST_DIRECTORY} | pipe.pl -W'\s+' -g'c8:(2014(0[6-9]|1[0-2])|20150[1-6])' -o'c8'
201406.hist.Z
201407.hist.Z
201408.hist.Z
201409.hist.Z
201410.hist.Z
201411.hist.Z
201412.hist.Z
201501.hist.Z
201502.hist.Z
201503.hist.Z
201504.hist.Z
201505.hist.Z
201506.hist
20150618.hist
```

To add a path:

```
ls -l {$HIST_DIRECTORY} | pipe.pl -W'\s+' -g'c8:(2014(0[6-9]|1[0-2])|20150[1-6])' -o'c8' -m 'c8:/s/sirsi/Unicorn/Hist/#'
/s/sirsi/Unicorn/Hist/201406.hist.Z
/s/sirsi/Unicorn/Hist/201407.hist.Z
/s/sirsi/Unicorn/Hist/201408.hist.Z
/s/sirsi/Unicorn/Hist/201409.hist.Z
/s/sirsi/Unicorn/Hist/201410.hist.Z
/s/sirsi/Unicorn/Hist/201411.hist.Z
/s/sirsi/Unicorn/Hist/201412.hist.Z
/s/sirsi/Unicorn/Hist/201501.hist.Z
/s/sirsi/Unicorn/Hist/201502.hist.Z
/s/sirsi/Unicorn/Hist/201503.hist.Z
/s/sirsi/Unicorn/Hist/201504.hist.Z
/s/sirsi/Unicorn/Hist/201505.hist.Z
/s/sirsi/Unicorn/Hist/201506.hist
/s/sirsi/Unicorn/Hist/20150618.hist
```

Dedup with counts compared to line counts ('-A'), count of dedupped values, and sum over a group (-J)
-----------------------------------------------------------------------------------------------------
To output the data set with line counts:
```
cat test.lst 
 86019|4|
 86019|9|
 86019|7|
 86020|0|
 86020|0|
 86020|1|
```
Using the above as test data show the line numbers from the file.
```
cat test.lst | pipe.pl -A
  1 86019|4
  2 86019|9
  3 86019|7
  4 86020|0
  5 86020|0
  6 86020|1
```
Find the count of different values in column 0.
```
cat test.lst | pipe.pl -dc0 -A
   3 86019|7
   3 86020|1
```
Another handy feature to use with dedup is the -J switch which will sum the values in another arbitrary column.
Find the sum of c1 for each uniq group in c0.
```
cat test.lst | pipe.pl -dc0 -Jc1
  20 86019|7
   1 86020|1
```
Of course you can separate the counts and sum from the other values to make further processing easier.
```
cat test.lst | pipe.pl -dc0 -Jc1 -P
20|86019|7|
1|86020|1|
```


Width reporting
---------------
Pipe can report the shortest and longest field of selected fields.
```
cat test.lst | pipe.pl -w'c8,c1,c6' -W'\s+' -L'+10' -A
  1 total|0
  2 drwxr-xr-x@|41|anisbet|staff|1394|25|Jun|21:53|.
  3 drwx------@|30|anisbet|staff|1020|29|Jun|23:03|..
  4 drwxr-xr-x@|3|anisbet|staff|102|2|May|09:13|3DPrinter
  5 drwxr-xr-x@|8|anisbet|staff|272|1|May|21:36|BestMatch
  6 drwxr-xr-x@|8|anisbet|staff|272|1|May|21:36|JDBCWorkBench
  7 drwxr-xr-x@|6|anisbet|staff|204|1|May|21:36|JVUpload
  8 drwxr-xr-x@|3|anisbet|staff|102|1|May|21:36|Licenses
  9 drwxr-xr-x@|6|anisbet|staff|204|1|May|21:36|Lisp
 10 drwxr-xr-x@|43|anisbet|staff|1462|1|May|21:39|MeCard
== width
 c1: min:  1 at line 1, max:  2 at line 2, mid: 1.5
 c6: min:  0 at line 0, max:  3 at line 2, mid: 1.5
 c8: min:  0 at line 0, max: 13 at line 6, mid: 6.5
 number of columns:  min: 2 at line: 1, max: 9 at line: 10, variance: 1
```

Another example

```
 cat test.lst | pipe.pl -W'\s+' -w"c6,c1,c8" -A -L'10-13'
 10 drwxr-xr-x@|43|anisbet|staff|1462|1|May|21:39|MeCard
 11 drwxr-xr-x@|10|anisbet|staff|340|1|May|21:36|MetroGUI
 12 drwxr-xr-x@|9|anisbet|staff|306|1|May|21:40|NewFolder
 13 drwxr-xr-x@|3|anisbet|staff|102|1|May|21:35|VisualStudio
== width
 c1: min:  1 at line 12, max:  2 at line 10, mid: 1.5
 c6: min:  3 at line 10, max:  3 at line 10, mid: 3.0
 c8: min:  6 at line 10, max: 12 at line 13, mid: 9.0
 number of columns: min, max: 9, variance: 0
```

Encode string in URL safe characters
------------------------------------
```
echo 'Hello World!' | pipe.pl -u'c0'
Hello%20World%21
```

Padding example
---------------
Padding allows you to pad a field to a maximum of 'n' fill characters. If the string you are padding is longer than the requested pad field width, the field will be output unaffected. A negative number denotes that the padding should be added to the end of the field, a '+', or no modifier, denotes padding on the front of the string. If you don't specify a padding character a single white space is used.
```
cat pad.lst
1
12
123
1234
12345
cat pad.lst | pipe.pl -pc0:"5.\."
....1
...12
..123
.1234
12345
cat pad.lst | pipe.pl -pc0:"-5.\."
1....
12...
123..
1234.
12345
```
Multiple characters may be used, but each string counts as a single padding sequence as shown in the next example.
```
echo 21221012345678 | pipe.pl -p'c0:17.dot'
dotdotdot21221012345678
```
and
```
echo 21221012345678 | pipe.pl -p'c0:-17.dot'
21221012345678dotdotdot
```
The '.' character is optional, but required if you want to specify digits as padding. For example.
```
$ echo '123|abc' | pipe.pl -pc0:"-5.1"
12311|abc
```

See also **-m** for additional formatting features.

Random line selection from data
-------------------------------
Sometimes it's helpful to get a random selection of input to use as test data for another process. With pipe this is easy:
```
cat t1.lst
1
2
3
4
5
```
...
```
18
19
20
cat t1.lst | pipe.pl -r'10'
19
20
cat t1.lst | pipe.pl -r'10'
9
13
cat t1.lst | pipe.pl -r'10'
3
16
cat t1.lst | pipe.pl -r'10'
10
3
```
Selection by line number or range of lines
------------------------------------------
Using the same data and the '-L' we can output specific lines or ranges of lines.
```
cat t1.lst | pipe.pl -L'10'
10

```
The '+' produces output from the head of the file.
```
cat t1.lst | pipe.pl -L'+5'
1
2
3
4
5
```
The '-' produces output from the tail of the file.
```
cat t1.lst | pipe.pl -L'-5'
16
17
18
19
20
```
A range can be specified as follows:
```
cat t1.lst | pipe.pl -L'11-15'
11
12
13
14
15
```
You can specify the output from a specific line onward to the end of the file.
```
cat t1.lst | pipe.pl -L'17-'
17
18
19
20
```
Combinations of lines can be specified as follows:
```
cat one_to_one_hundred.lst | pipe.pl -L'+3,13,27, 55-77, -5'
```
If you wish to output alternate lines like, say, every 3rd line use the 'skip' keyword as in the next example.
```
cat t1.lst | pipe.pl -Lskip3
3
6
9
12
15
18
```

A note about line numbering. -L take operator has precedence over other operations, so it you select the last 
10 lines of a file line numbering on output starts at 1, not the line from the incoming file. After that if you 
further select with -g, -G, -X, and or -Y, the successful match will print the line number from the -L selection.
Conditional test columns:
-------------------------
```
cat t02.lst
0 123.1
1 123.22
2 123.9
3 123.9
4 123.9
5 123.6
6 123.9
7 123.9
8 123.987888
9 123.0345
10 123.11
 cat t02.lst | pipe.pl -W'\s+' -C'c0:lt6'
0|123.1
1|123.22
2|123.9
3|123.9
4|123.9
5|123.6
 cat t02.lst | pipe.pl -W'\s+' -C'c0:le6'
0|123.1
1|123.22
2|123.9
3|123.9
4|123.9
5|123.6
6|123.9
 cat t02.lst | pipe.pl -W'\s+' -C'c0:gt6'
7|123.9
8|123.987888
9|123.0345
10|123.11
 cat t02.lst | pipe.pl -W'\s+' -C'c0:ge6'
6|123.9
7|123.9
8|123.987888
9|123.0345
10|123.11
 cat t02.lst | pipe.pl -W'\s+' -C'c0:eq6'
6|123.9
 cat t02.lst | pipe.pl -W'\s+' -C'c1:gt123.6'
2|123.9
3|123.9
4|123.9
6|123.9
7|123.9
8|123.987888
```
Also works on non-numeric field data
```
 cat alpha2.lst
metrically
atypic
chorizo
clarity
unmystic
retirer
dinkier
sligo
horopter
 cat alpha2.lst | pipe.pl -C'c0:gef'
metrically
unmystic
retirer
sligo
horopter
```
Using -U with -C for comparisons forces comparisons to be numeric to succeed.
```
echo '12345a' | pipe.pl -C'c0:ge12345'
12345a
echo '12345a' | pipe.pl -C'c0:ge12345' -U
<nil>
echo '12345a' | pipe.pl -C'c0:ge12345' -U -D
columns requested: '0'
regex: 'ge12345'
* comparison fails on non-numeric value: '12345a'
```

Using the column comparison feature.
------------------------------------
Consider the following data. In this example we want to output the line if the value in column 1 is less than or equal to the value in column 0. 
```
$ cat C.lst
1|2
2|2
3|2
$ cat C.lst | pipe.pl -Cc1:cclec0 
2|2
3|2
```

Using column comparison to confine comparisons to a range of values (numeric)
-----------------------------------------------------------------------------
The -C flag has an additional modifier to compare if a column's data falls within a given range of numbers. For example, consider the following data.
```
$ cat dashC.lst
OVERDUE|2012
LOST-CLAIM|2013
OVERDUE|2015
LOST|2017
OVERDUE|2018
```
Now output the rows from rows where the year in column 1 (c1) lies between 2015 to 2017. Note the range separator is a '+' character, and the range must have a start and end value or a 'malformed range operator' error is issued.
```
$ cat dashC.lst | pipe.pl -Cc1:"rg2015+2017"
OVERDUE|2015
LOST|2017
```
Similarly the range syntax can be used to output fields that have given widths, that is, contain a given number of characters. Using the same data set consider the following examples.

Output rows who's first column is exactly 7 characters wide.
```
$ cat dashC.lst | pipe.pl -Cc0:"width7+7" 
OVERDUE|2012
OVERDUE|2015
OVERDUE|2018
```

Output rows who's first column range from 4 - 7 characters wide.
```
$ cat dashC.lst | pipe.pl -Cc0:"width4+7"
OVERDUE|2012
OVERDUE|2015
LOST|2017
OVERDUE|2018
```

Output rows who's first column range from 4 - 6 characters wide.
```
$ cat dashC.lst | pipe.pl -Cc0:"width4+6"
LOST|2017
```

Output rows who's first column are at least 10 characters wide.
```
$ cat dashC.lst | pipe.pl -Cc0:"width10+1000"
LOST-CLAIM|2013
```


Use of '-S', sub strings
------------------------
You can use -S to output a sub string of the value in the specified column(s). The
'.', dot character is a single index delimiter and the '-' works as a range specifier
as expected. Here are some examples.
```
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'c0:24'
6
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'c0:-11'
121107s2011
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'15-'
caua   j 6    000 1 eng d
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'c0:1'
2
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'c0:15.16.17.18'
caua
```
Which is the same as:
```
echo '121107s2011    caua   j 6    000 1 eng d|' | pipe.pl -S'c0:15-19'
caua
```
because the last index specified in a range is not included in the selection.

Here is another example that shows how you can reverse a string.
```
echo 12345 | pipe.pl -Sc0:4-0
54321
```
For extra points, how do you reverse a line?
--------------------------------------------
```
echo "NQ31221079015892" | pipe.pl -S'c0:30-0'
29851097012213QN
```
How to trim the last character of an entry?
```
echo "NQ31221079015892" | pipe.pl -S'c0:30-0' | pipe.pl -m'c0:_#' | pipe.pl -S'c0:30-0'
NQ3122107901589
```

Using '-f' to flip a character
------------------------------
Sometimes it's helpful to change a value at a specific site within a string. You can
accomplish this with the replace function (TODO), or with '-f' as follows.
Change the character at index 3 to 'A'.
```
echo '0000000' | pipe.pl -f'c0:3.A'
000A000
```
Change the character at index 3 to 'A', only if the character at index 3 is '0'.
```
echo '0000000' | pipe.pl -f'c0:3?0.A'
000A000
```
Change the character at index 3 to 'A' only if the character at index 3 is '1'.
```
echo '0000000' | pipe.pl -f'c0:3?1.A'
0000000
```
If the character at index 3 is '1' change it to 'A', else change it to 'B'.
```
echo '0000000' | pipe.pl -f'c0:3?1.A.B'
000B000
```
If the character at index 3 is '1' change it to 'This', else change it to 'That'.
```
echo '0000000' | pipe.pl -f'c0:3?1.This.That'
000That000
```
Use a '\' as an escape character if you want to test for the delimiter character '.'
or use it as replacement character.
If the character at index 3 is '.' change it to '.', else change it to '.'.
```
echo '000.000' | pipe.pl -f'c0:3?\..\..\.'
000.000
```
Use the escape for ',' and '?' as well.

Changing case and normalizing with '-e'
-----------------------
You can change the case of data in a column with '-e' as in this example:
```
echo 'upper case|mIX cASE|LOWER CASE|12345678|hello world' | pipe.pl -e'c0:uc,c1:mc,c2:Lc,c3:UC,c4:us'
UPPER CASE|Mix Case|lower case|12345678|hello_world
```

Additionally '-e' can normalize strings in ways that '-n' can't. You can remove multiple spaces in a string with 'spc' and remove classes of characters using similar (case sensitive) Perl character classifiers, like 'd' - digits, 'D' - non-digits. Other supported classes include w - word characters, W - non-word characters, and s - white space, S - non-white space characters. 
For example:
```
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:uc
23)  LINE WITH     LOTS OF  #'S!
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:lc
23)  line with     lots of  #'s!
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:mc
23)  Line With     Lots Of  #'s!
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:us
23)__Line_with_____lots_of__#'s!
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:spc
23) Line with lots of #'s!
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:"NORMAL_d|W"  # you need the quotes for the '|' character.
Linewithlotsofs
$ echo " 23)  Line with     lots of  #'s!" | ./pipe.pl -ec0:NORMAL_D
23
```
=== Remove CSV formatting 
If you have a CSV as input and want to convert it back to pipe delimited format for processing by the following.
```
$ cat file.csv | pipe.pl -W, -eany:normal_Q 
```
  

Using -E to replace fields conditionally.
-----------------------------------------
Like the -f flag that replaces specific characters in a field, this function replaces the entire
field. The operation can also include a conditional test that behaves like an if statement.
Here are some examples.
```
echo '111|222|333' | pipe.pl -E'c2:nnn'
111|222|nnn
echo '111|222|333' | pipe.pl -E'c1:nnn'
111|nnn|333
echo '111|222|333' | pipe.pl -E'c1:?222.444'
111|444|333
echo '111|222|333' | pipe.pl -E'c1:?aaa.444.bbb'
111|bbb|333
echo '1|2|3' | pipe.pl -E'c1:?aaa.444.bbb'
1|bbb|3
```

Using -F for conversions.
-------------------------
Binary:
```
echo 'hello' | pipe.pl -F'c0:b'
01101000 01100101 01101100 01101100 01101111
```
but numbers are handled as expected, not as characters.
```
echo '123' | pipe.pl -F'c0:b'
01111011
```
Hex:
```
echo 'hello' | pipe.pl -F'c0:h'
68 65 6c 6c 6f
```
Decimal:
```
echo 'hello' | pipe.pl -F'c0:d'
104 101 108 108 111
```
Using -l to translate values in columns
---------------------------------------
Sometimes it's useful to replace character sequences within a targeted column.
The '-l' switch does this. Here are some examples.
```
echo "Catkey 1456824 has 114 T024's" | pipe.pl -W'\s+' -lc4:\'.\s
Catkey|1456824|has|114|T024s
```
Replace all the '1's with '8' within a column.
```
echo "Catkey 1481241 has 134 T024's" | pipe.pl -W'\s+' -l'c1:1.8'
Catkey|8488248|has|134|T024's
```
An entry that has no value in 'c0', you can add a default value with:
```
echo "|Catkey|8488248|has|134|T024's" | pipe.pl -l'c0:^$.NA'
NA|Catkey|8488248|has|134|T024's
```
The -l flag also allows for the user to replace a character with a space (\s), a line break (\n OS agnostic), and a tab (\t). In the example below I change multiple spaces in a column to a single space.
```
echo "15285    59th Street" | pipe.pl -lc0:"\s+.\s"
15285 59th Street
```


Simple scripting with -k
------------------------
You can add a new column anywhere within a line, with content taken and processed from another column.
Given a line of data
```
'1234|abcd    |789'
```
Replace field 1 with the substring of field 1, from character 1 to the end of the field.
```
echo '1234|abcd    |789' | pipe.pl -k"c1:-Sc1:1-"
1234|bcd    |789
```
Replace field 1 with the substring of field 1, from character 1 to the end of the field, then trim the trailing whitespace.
```
echo '1234|abcd    |789' | pipe.pl -k"c1:-tc1(-Sc1:1-)"
1234|bcd|789
```
The inner ```-Sc1:1-``` indicates that we want the substring from character 1 to the end of the field.
The result is passed up to ```-tc1``` then replaces the value in ```c1``` as described in the expression ```-k"c1:```.
The ```-t``` flag requires a column descriptor ```c1``` in this case, but the column descriptor of most inner call is the
column that continues to be operated on for the remainder of the column's computation.

Here is another example.

```
echo 'abcdefg|12345678|xyz|987' | pipe.pl -k"c0:-Sc1:2-4,c1:-Sc0:0-2,c2:-Sc3:0-9,c3:-Sc2:9-0"
34|ab|987|zyx
```
The examples use ```-S```, but any pipe switch can be used, although some switches make no sense.

Suppress new line on output
---------------------------
You can make all your output appear on one line with '-H'
```
cat p.lst
1|2|3
1|2|4|
1|2|4|
1|2|3
cat p.lst | pipe.pl -H
1|2|31|2|4|1|2|4|1|2|3
```
And with -P you can ensure that all fields are separated with a single pipe '|'.
```
cat p.lst | pipe.pl -H -P
1|2|3|1|2|4|1|2|4|1|2|3|
```

Change output delimiter with -h
-------------------------------
Long requested; here now. 
```
cat p.lst
1|2|3
1|2|4|
1|2|4|
1|2|3

cat p.lst | pipe.pl -d'c2' -A  -h'^'
   2 1^2^3
   2 1^2^4

cat p.lst | pipe.pl -d'c2' -A -P -h'^'
2^1^2^3^
2^1^2^4^
```
Stop output of the last delimiter on the last line. This can be useful if your output is sensitive to trailing delimiters on the last
line of data like when you are producing JSON.
```
cat p.lst | pipe.pl -d'c2' -A -P -h'^' -j
2^1^2^3^
2^1^2^4
```

-W and -h work independantly.
```
cat s.lst
E201411051046470005R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815538^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108

cat s.lst | pipe.pl -W'\^' -h'#'
E201411051046470005R #S01JZFFBIBLIOCOMM#FcNONE#FEEPLCPL#UO21221019966206#Uf3250#NQ31221106815538#HB11/05/2015#HKTITLE#HOEPLCPL##O00108
``` 

Ensure output and input have matching delimiter counts
------------------------------------------------------
Some functions produce undesirable results if the trailing columns are empty.
```
echo '123|||' | pipe.pl -t'c1'
123
```
This is a case when to use -V. It will ensure you get the same number of fields back as were sent in.
```
echo '123|||' | pipe.pl -t'c1' -V
123|||
```

Look ahead searches
-------------------
Sometimes you may want to find a value in data, then once found, output likes that match a different set of criteria.
```
cat x.lst
1
2
3
4
5
6
7
8
9
```
Search for '5' in column 0, then start outputting lines.
```
cat x.lst | pipe.pl -X'c0:5'
5
6
7
8
9
```
Sometimes it's you would like to see all the data in between one match pattern and another that occurs later in the file. This can be done using the -Y flag. The first use of -X opens a selection match frame. The -Y match closes the match frame.
```
cat X.lst | pipe.pl -X"c0:2" -Y"c0:6"
2
3
4
5
6
```
This is especially useful when the column data are sorted dates.

What about a special case within a regular-patterned file. Consider the following data.
```
$ cat XYg_simple.lst
A
B
C
A
B
7
C
A
B
C
```
If we want all the groups that start with 'B' and end with 'C' we could -X and -Y like the above example. But what if we wanted only the frame that also contained a '7'? We would then use -g in conjunction with -X and -Y. If the 3 switches together only the frame(s) that match all the flags are output to STDERR and include a '=>' prefix to STDOUT output. This feature can be turned off the prefix with -N. Only the line(s) that match -g within the frame are output to STDOUT. 
```
$ cat XYg_simple.lst | pipe.pl -Xc0:B -Yc0:C -gc0:7
7
=>B
=>7
=>C
```
To just get the match use pipe in this way.
```
$ cat XYg_simple.lst | pipe.pl -Xc0:B -Yc0:C -gc0:7 -N >/dev/null # Drops STDOUT.
B
7
C
``` 

Pro tips
--------
Replace all the spaces in the following: '31221 21448 3104'

Method 1: Replace any space char with nothing.
```
echo 31221 21448 3104 | pipe.pl -l'c0:\ .'
```

Method 2: Suppress the space characters.
```
echo 31221 21448 3104 | pipe.pl -m'c0:#####_#####_####'
```

Method 3: The fastest and easiest -- normalize the string.
```
echo 31221 21448 3104 | pipe.pl -n'c0'
```


Consider the following data output from mysql.
```
13      13      2012-05-29 15:36:39     55197   38619   0
14      14      2012-05-29 15:36:39     52806   63713   0
15      15      2012-05-29 15:36:39     16797   19044   0
32      13      2012-05-29 15:41:40     55206   38635   0
1421    14      2012-05-30 07:41:39     53275   64352   0
1422    15      2012-05-30 07:41:39     16888   19186   0
```
Split the line into columns by white space and by hour minute and second.
```
pipe.pl -W'(\s+|:)'
13|13|2012-05-29|15|36|39|55197|38619|0
14|14|2012-05-29|15|36|39|52806|63713|0
15|15|2012-05-29|15|36|39|16797|19044|0
32|13|2012-05-29|15|41|40|55206|38635|0
1421|14|2012-05-30|07|41|39|53275|64352|0
1422|15|2012-05-30|07|41|39|16888|19186|0
```

