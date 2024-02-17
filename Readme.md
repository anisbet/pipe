
# Pipe
A Perl script that simplifies common flat text file queries and formatting.

A swiss-army-knife application featuring functions useful for
manipulating data on the command line. The application is intended for
system administrators, or others that find themselves on the command line
without a access or advanced knowledge of awk, Bash, or Pandas.

For those in a hurry jump to the [flag description](#usage) section, or
[here for a usage cheat sheet](#api-cheat-sheet).

## Author

- [@anisbet](https://github.com/anisbet)


## License

[AGPL-3.0-only](https://choosealicense.com/licenses/agpl-3.0/)


## Deployment

This application is stand-alone Perl, and does not make use of additional
libraries or dependancies.

To deploy this project drop ```pipe.pl``` into your favourite directory and
add the directory to ```$PATH``` if you haven't already. Add execution 
permissions if required as follows.

```bash
chmod +x pipe.pl
```


## Running Tests

To run tests, run the following commands. The CLONE_DIR is where you cloned 
the pipe git repo.

To do everything in one step.
```bash
cd $CLONE_DIR/tests
make all
```

## Acknowledgements

Special thanks to [Edmonton Public Library](https://epl.ca) for giving me an awesome
job and for letting me build this useful tool. See [here](https://github.com/Edmonton-Public-Library) and 
[here](https://github.com/EPLibrary) some of the other interesting projects.

## API Reference

[-?](#flag-?) - Perform math operations on columns.  
[-0](#flag-0) - Input from named file. (See also [-M](#flag-m)).  
[-1](#flag-1) - Increment value in specified columns.  
[-2](#flag-2) - Add an auto-increment field to output.  
[-3](#flag-3) - Increment value in specified columns by a specific step.  
[-4](#flag-4) - Output difference between this and previous line.  
[-5](#flag-5) - Output all [-g](#flag-g-1) 'any' keyword matches to STDERR.  
[-6](#flag-6) - Histogram values in column(s).  
[-7](#flag-7) - Stop search after n-th match.  
[-8](#flag-8) - Change the record separator. Default is new line.  
[-A](#flag-a) - Displays line numbers or summary of duplicates if '[-d](#flag-d-1)' is selected.  
[-a](#flag-a-1) - Sum of numeric values in specific columns.  
[-B](#flag-b) - Only show lines where columns are different.  
[-b](#flag-b-1) - Suppress line output if columns' values differ.  
[-C](#flag-c) - Conditionally test column values.  
[-c](#flag-c-1) - Count numeric values in specified columns.  
[-D](#flag-d) - Turn on debugging.  
[-d](#flag-d-1) - De-duplicate selected columns.  
[-E](#flag-e) - Replace string in column conditionally.  
[-e](#flag-e-1) - Change case and normalize strings.  
[-F](#flag-f) - Format column value into bin, hex, or dec.  
[-f](#flag-f-1) - Modify character in string based on 0-based index.  
[-G](#flag-g) - Inverse grep specified columns.  
[-g](#flag-g-1) - Grep values in specified columns.  
[-H](#flag-h) - Suppress new line on output.  
[-h](#flag-h-1) - Replace default delimiter.  
[-I](#flag-i) - Ignore case on operations [-b](#flag-b-1), [-B](#flag-b), [-C](#flag-c), [-d](#flag-d-1), [-E](#flag-e), [-f](#flag-f-1), [-g](#flag-g-1), [-G](#flag-g), [-l](#flag-l-1), [-n](#flag-n-1) and [-s](#flag-s-1).  
[-i](#flag-i-1) - Output all lines, but process only if [-b](#flag-b-1), [-B](#flag-b), [-C](#flag-c), [-g](#flag-g-1), [-G](#flag-g), [-z](#flag-z-1) or [-Z](#flag-z) match.                                         
[-J](#flag-j) - Displays sum over group if '[-d](#flag-d-1)' is selected.  
[-j](#flag-j-1) - Remove last delimiter on the last line of data output.  
[-K](#flag-k) - Output everything as a single column.  
[-k](#flag-k-1) - Run perl script on column data.  
[-L](#flag-l) - Output only specified lines, or range of lines.  
[-l](#flag-l-1) - Translate character sequence.  
[-M](#flag-m) - Merge and compare columns across two files. See [-0](#flag-0).  
[-m](#flag-m-1) - Mask specified column values.  
[-N](#flag-n) - Normalize summaries, keys before comparisons, abs(result). Strips formatting.  
[-n](#flag-n-1) - Remove non-word characters in specified columns.  
[-O](#flag-o) - Merge selected columns.  
[-o](#flag-o-1) - Order selected columns.  
[-P](#flag-p) - Add additional delimiter if required.  
[-p](#flag-p-1) - Pad fields to specified width with an arbitrary character.  
[-Q](#flag-q) - Output 'n' lines before and after a '[-g](#flag-g-1)', or '[-G](#flag-g)' match to STDERR.  
[-q](#flag-q-1) - Selectively allow new line output of '[-H](#flag-h)'.  
[-R](#flag-r) - Reverse line order when [-d](#flag-d-1), [-4](#flag-4) or [-s](#flag-s-1) is used.  
[-r](#flag-r-1) - Randomize line output.  
[-S](#flag-s) - Sub string column values.  
[-s](#flag-s-1) - Sort columns.  
[-T](#flag-t) - Output in table form.  
[-t](#flag-t-1) - Trim selected columns.  
[-U](#flag-u) - Prioritize sorts in numerical order.  
[-u](#flag-u-1) - Encode specified columns into URL-safe strings.  
[-V](#flag-v) - Ensure output and input have same number of columns. Deprecated.  
[-v](#flag-v-1) - Average numerical values in selected columns.  
[-W](#flag-w) - Change the delimiter of input data.  
[-w](#flag-w-1) - Output minimum an maximum width of column data.  
[-X](#flag-x) - Grep values in specified columns, start output, or start searches for [-Y](#flag-y) values.  
[-x](#flag-x-1) - Displays usage message then exits.  
[-Y](#flag-y) - Stops -X output once -Y succeeds.  
[-y](#flag-y-1) - Specify precision of floating computed variables, or trim string to length.  
[-Z](#flag-z) - Show line output if column(s) test empty.  
[-z](#flag-z-1) - Suppress line output if column(s) test empty.  




## Flag: ?
```-?{opr}:{c0,c1,...,cn}``` 

Performs math operations over multiple columns. Supported operators are 'add', 'sub',
'mul', and 'div'. The order of columns is important for subtraction and division 
since ```'1|2' -?div:c0,c1 => '0.5|1|2'``` and '1|2' ```-?div:c1,c0 => '2|1|2'```.
The result always appears as the first column (c0), see [-o](#flag-o-1) to re-order.
The precision of results can be changed with [-y](#flag-y-1).

Errors like divide by zero will result in 'NaN'. If a column contains non-numeric
data it is ignored during the calculation.

Use case: Subtraction operations over columns  
Parameters: -? sub:c0,c1,c2,c3,c4

Input: 
```1|2|0|10|1 => -12|1|2|0|10|1```

Use case: Addition over columns  
Parameters: -? add:c0,c1,c2,c3,c4

Input: 
```1|2|0|10|1 => 14|1|2|0|10|1```

Use case: Multiplication over columns  
Parameters: -? mul:c0,c1,c2,c3,c4

Input: 
```1|2|0|10|1 => 0|1|2|0|10|1```

Use case: Divide column c0 by c1  
Parameters: -? div:c0,c1

Input: 
```1|2|0|10|1 => 0.50|1|2|0|10|1```

Use case: Divide by zero issues an error.  
Parameters: -? div:c1,c2

Input: 
```1|2|0|10|1 => NaN|1|2|0|10|1```

Use case: Sum column with none numeric value.  
Parameters: -? add:c0,c1,c2

Input:
```1|cat|2 => 3|1|cat|2```

## Flag: 0
```-0 {foo/bar.txt}```

Takes input from a named file, or if used with [-M](#flag-m) defines the file to be read as data to be merged with data coming in on STDIN. 

Use case: Read data from file1.  
Parameters: -0file1

Input: file1
```
1000048|The Berenstain Bears
```

Input:
```
```
Output:
```
1000048|The Berenstain Bears
```

Use case: Compare column from file1 and file2 if the same append data from file2.  
Parameters: -0file2 -M c0:c0?c1.na

Input: file2
```
1000048|The Berenstain Bears
```

Input:
```
1000048|6|15|
1000049|10|2|
1000048|10|4|
```
Output:
```
1000048|6|15|The Berenstain Bears
1000049|10|2|na
1000048|10|4|The Berenstain Bears
```

## Flag: 1
```-1{c0,c1,...cn}```

Increment a numeric value stored in given column(s).

Use case: Increment an integer in c0.  
Parameters: -1c0

Input: 
```1 => 2```

Use case: Increment a string value from "aaa" to "aab".  
Parameters: -1c0

Input: 
```aaa => aab```

Use case: Increment multiple columns.  
Parameters: -1c0,c1,c2

Input: 
```1|2|3 => 2|3|4```

## Flag: 2
```-2{cn:[start,[end]]}``` 

Adds a field to the data that auto increments starting at a given integer.
The auto-increment value will be appended to the end of the line if the
column index is specified is greater than, or equal to, the number of 
columns a given line. Column increments can be reset with an 'end' period.

Use case: Add auto-increment column at c1 and start counting from 100.  
Parameters: -2c1:100

Input:
```
a|b|c
a|b|c
a|b|c
```
Output:
```
a|100|b|c
a|101|b|c
a|102|b|c
```

Use case: Increment and reset a value by a given period.  
Parameters: -2 c1:0,1

Input:
```
a|b|c
a|b|c
a|b|c
a|b|c
a|b|c
```
Output:
```
a|0|b|c
a|1|b|c
a|0|b|c
a|1|b|c
a|0|b|c
```

Use case: Add auto increment column starting at a and ending at c, then repeat.   
Parameters: -2 c0:a,c

Input:
```
1
1
1
1
```
Output:
```
a|1
b|1
c|1
a|1
```

With '-2' you can add an auto-increment column with a default of '0' as an initial value.

Use case: Add an auto-incremented column.  
Parameters: -2 c0

Input:
```
1|2|3
1|2|4
1|2|4
1|2|3
```
Output:
```
0|1|2|3
1|1|2|4
2|1|2|4
3|1|2|3
```
Use case: seed the initial value of new column with 999.  
Parameters: -2c100:999

Input:
```
1|2|3
1|2|4
1|2|4
1|2|3
```
Output:
```
1|2|3|999
1|2|4|1000
1|2|4|1001
1|2|3|1002
```
Use case: Seed column with initial value.  
Parameters: -2c100:a

Input:
```
1|2|3
1|2|4
1|2|4
1|2|3
```
Output:
```
1|2|3|a
1|2|4|b
1|2|4|c
1|2|3|d
```

Use case: Reset the column count by adding an additional parameter separated by a comma ",".  
Parameters: -2c100:a,b

Input:
```
1|2|3
1|2|4
1|2|4
1|2|3
```
Output:
```
1|2|3|a
1|2|4|b
1|2|4|a
1|2|3|b
```

## Flag: 3
```-3{c0[:n],c1,...cn}```

Increment the value stored in given column(s) by a given step.

Use case: Increment a column integer value by 1.  
Parameters: -3c0:1

Input: 
```1 => 2```

Use case: Increment a column by a step of 3.  
Parameters: -3c0:3

Input: 
```7 => 10```

Use case: Decrement a column by using a step of -1.  
Parameters: -3c0:-1

Input: 
```7 => 6```

## Flag: 4
```-4{c0,c1,...cn}```

Compute difference between value in previous column. If the values in the
line above are numerical the previous line is subtracted from the current line.
If the -R switch is used the current line is subtracted from the previous line.

Use case: Compute differences between one line and the next.  
Parameters: -4c0

Input:
```
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
Output:
```
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
```

Use case: Differences c1.  
Parameters: -4c1

Input:
```
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
Output:
```
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

## Flag: 5
```-5```

Modifier used with -[g|X|Y]'any:{regex}', outputs all the values that match the regular
expression to STDERR.

Use case: output only the complete -g match.  
When using '-g' and the keyword 'any' for any   column match adding -5 will output the match to STDERR. Consider the following data.

Parameters: -5 -gany:CONSE

Input:
```
21221023942342|EPL-ADU1FR|EPLMLW|ECONSENT|john.smith@mymail.org|20150717|
21221023464206|EPL-JUV|EPLMNA|EMAILCONV||20150717|
21221024955293|EPL-ADULT|EPLJPL|ENOCONSENT||20150717|
```
Output:
```
21221023942342|EPL-ADU1FR|EPLMLW|ECONSENT|john.smith@mymail.org|20150717|
21221024955293|EPL-ADULT|EPLJPL|ENOCONSENT||20150717|
```
Error:
```
ECONSENT
ENOCONSENT
```


## Flag: 6
```-6{cn:[char]}```

Displays histogram of columns' numeric value.
If the column doesn't contain a whole number pipe.pl will issue an
error and exit.

Use case: Test -6 makes histogram of specified column count.  
Parameters: c1:*

Input: 
```  
2017-09-22|1
2017-09-23|2
2017-09-24|3
2017-09-25|4
2017-09-26|5
```
Output:
```
2017-09-22|*
2017-09-23|**
2017-09-24|***
2017-09-25|****
2017-09-26|*****
```

Use case: Test -6 makes histogram even if 0 or text is used in a column.  
Parameters: c1:*

Input: 
```  
2017-09-22|1
2017-09-23|2
2017-09-24|0
2017-09-25|hello
2017-09-26|5
```
Output:
```
2017-09-22|*
2017-09-23|**
2017-09-24|
2017-09-25|
2017-09-26|*****
```

## Flag: 7
```-7{positive-integer}```

Return after n-th line match of a search is output. See [-g](#flag-g-1), [-G](#flag-g), [-X](#flag-x), [-Y](#flag-y), [-C](#flag-c) and has precedence over [-i](#flag-i-1).

Use case: Output the first 2 matches of '1' in column 0.  
Parameters: -72 -gc0:1

Input:
```
1|a
2|b
1|c
4|d
5|e
1|f
2|g
3|h
1|i
5|j
```
Output:
```
1|a
1|c
```

Use case: Output the first 3 matches of '1' in column 0.  
Parameters: -72 -gc0:1

Input:
```
1|a
2|b
1|c
4|d
5|e
1|f
2|g
3|h
1|i
5|j
```
Output:
```
1|a
1|c
```

Use case: Output the first three numbers greater than equal to 300.  
Parameters: -7 3 -C c0:ge300

Input:
```
700
850
20
333
299
399
```
Output:
```
700
850
333
```

## Flag: 8
```-8{record_separator|regex}```

Change the input record separator. Works with multiple files using [-0](#flag-0) and [-M](#flag-m). See also [-W change delimiter](#flag-w).

Use case: change input record separator to ":".
Parameters: -8:

Input:
```
1:2:3
```
Output:
```
1
2
3
```

Use case: Compare column from file1 and file2 if the same append data from file2, but use '%' as a record separator.  
Parameters: -8% -M c0:c0?c1.na -0file2

Input: file2
```
1000048|The Berenstain Bears%1000050|Not The Berenstain Bears
```

Input:
```
1000048|6|15|%1000049|10|2|%1000048|10|4|
```
Output:
```
1000048|6|15|The Berenstain Bears
1000049|10|2|na
1000048|10|4|The Berenstain Bears
```

## Flag: A
```-A```
 
Modifier that outputs line numbers from input, or if [-d (deduplicate)](#flag-d) is used, the number 
of records that match the column key selection that were de-duplicated.
The end result is output similar to 'sort | uniq -c'. In other match
functions like [-g](#flag-g-1), [-G](#flag-g), [-X](#flag-x), or [-Y](#flag-y) the line numbers of successful matches
are reported.

Use case: Sum all numeric values in the first column (c0).  
Parameters: -A -dc0

Input:
```
5
5
5
6
5
```
Output:
```
   4 5
   1 6
```

Use case: Separate deduplicate values and counts with default delimiter.  
Parameters: -A -dc0 -P

Input:
```
5
5
5
6
5
```
Output:
```
4|5|
1|6|
```

Use case: Report the line number of each match in conjunction with -g.  
Parameters: -A -gc0:5

Input:
```
5
5
5
6
5
```
Output:
```
  1 5
  2 5
  3 5
  5 5
```

Use case: Report the line number of each match in conjunction with -g, but add a pipe character between the fields.  
Parameters: -A -gc0:5 -P

Input:
```
5
5
5
6
5
```
Output:
```
1|5|
2|5|
3|5|
5|5|
```

Use case: Report the line number of each match in conjunction with -g, but change delimiter between the fields.  
Parameters: -A -gc0:5 -P -h,

Input:
```
5
5
5
6
5
```
Output:
```
1,5,
2,5,
3,5,
5,5,
```

## Flag: a
```-a{c0,c1,...cn}```
 
Sum the non-empty values in given column(s).

Use case: Sum all numeric values in the first column (c0).  
Parameters: -ac0

Input:
```
5
5
a
5
6
5
```
Output:
```
5
5
a
5
6
5
```
Error:
```
==       sum
 c0:      26
```

## Flag: B
```-B{c0,c1,...cn}```

Compare fields and output if columns differ.

Use case: Output lines where two columns differ.  
Parameters: -Bc0,c2

Input:
```
7069|Feb|7069
7862|Feb|7862
8753|Feb|8753
7866|Feb|7869
7442|Feb|7442
6950|Feb|6950
6769|Feb|6769
```
Output:
```
7866|Feb|7869
```

## Flag: b
```-b{c0,c1,...cn}```

Compare fields and output if each is equal to one-another.

Use case: Output lines where two columns are the same.  
Parameters: -bc0,c2

Input:
```
7069|Feb|70169
7862|Feb|78162
8753|Feb|87153
7866|Feb|7866
7442|Feb|74142
6950|Feb|69150
6769|Feb|67169
```
Output:
```
7866|Feb|7866
```

## Flag: C
```-C{any|num_cols{n-m}|cn:(gt|ge|eq|le|lt|ne|rg{n-m}|width{n-m})|cc(gt|ge|eq|le|lt|ne)cm,...}```

Compare column values and output line if value in column is greater than (gt),
less than (lt), equal to (eq), greater than or equal to (ge), not equal to (ne),
or less than or equal to (le) the value that follows. The following value can be
numeric, but if it isn't the value's comparison is made lexically. All specified
columns must match to return true, that is -C is logically AND across columns.
This behaviour changes if the keyword 'any' is used, in that case test returns
true as soon as any column comparison matches successfully.

-C supports comparisons across columns. Using the modified syntax 
```-Cc1:ccgec0``` 
where 'c1' refers to source of the comparison data,
'cc' is the keyword for column comparison, 'ge' - the comparison
operator, and 'c0' the column who's value is used for comparison.
"2|1" => ```-Cc0:ccgec1``` means compare if the value in c1 is greater
than or equal to the value in c1, which is true, so the line is output.

A range can be specified with the 'rg' modifier. Start and end values may be
[+/-] integers or [+/-] floating values. Once set only numeric
values that are greater or equal to the lower bound, and less than equal
to the upper bound will be output. The range is separated with a '-'
character. Outputting rows that have value within the range of 
0 and 5 is as follows ```-Cany:rg0-5```. To output rows with values
between -100 and -50 is specified with ```-Cany:rg-100--50```.
Further, -Cc0:rg-5-5 is the same as -Cc0:rg-5-+5. See also [-I](#flag-i) and [-N](#flag-n).

Row output can also be controlled with the 'width' modifier.
Like the 'rg' modifier, you can output rows with columns of a 
given width. "abc|1" => -Cc0:"width0-3", or output the rows if c0
is between 0 and 3 characters wide.
Also outputs lines that match a range of expected columns. For example
"2|1" => ```-Cnum_cols:'width2-10'``` prints output, because the number of columns falls between 2 and 10. 'num_cols' has precedence over other comparisons.

Use case: Output rows that contain values greater than 300 in the third (c2).  
Parameters: -C c2:ge300

Input:
```
1
1|2
1|220|3
1|2|333|4
1|2|299|4
1|301|399|4|57
```
Output:
```
1|2|333|4
1|301|399|4|57
```
Use case: Output rows where any column contains values greater than 300.  
Parameters: -C any:ge300

Input:
```
1
1|2
1|220|3
1|2|333|4
1|2|299|4
1|301|299|4|57
```
Output:
```
1|2|333|4
1|301|299|4|57
```

Use case: Output a row if column 2 (c1) is greater than or equal to column 4 (c3).  
Parameters: -Cc1:ccgec3

Input:
```
1|2|3|4|5
5|4|3|2|1
5|4|3|4|1
```
Output:
```
5|4|3|2|1
5|4|3|4|1
```

Use case: Limit output of rows where column is between 2 and 3 characters wide.  
Parameters: -Cc3:width2-3

Input:
```
73|19|11|1|11
86|99|12|6|12
76|40|13|68|13
32|16|18|100|18
```
Output:
```
76|40|13|68|13
32|16|18|100|18
```

Use case: Output rows that are between 2 and 4 columns wide.  
Parameters: -C num_cols:width2-4

Input:
```
1
1|2
1|2|3
1|2|3|4
1|2|3|4|5
```
Output:
```
1|2
1|2|3
1|2|3|4
```

Use case: Output rows that are between -2.1 and 4.5 columns wide.  
Parameters: -C num_cols:width-2.1-4.5

Input:
```
1
1|2
1|2|3
1|2|3|4
1|2|3|4|5
```
Output:
```
1
1|2
1|2|3
1|2|3|4
```

Use case: Output rows that are dated between 2020 and 2021.  
Parameters: -C c0:rg2020-2021

Input:
```
2019|$85548.89
2019|$78378.04
2019|$55121.42
2021|$40004.20
2020|$47905.60
2020|$73310.84
2019|$91106.42
2019|$89423.77
2019|$20785.86
2021|$98715.03
2021|$55012.40
2019|$75064.13
2022|$19306.39
2018|$21617.20
2019|$92560.53
2021|$20448.73
2019|$56657.82
2021|$50074.81
2021|$82168.48
2020|$31839.12
2020|$92819.03
2022|$94313.43
2019|$67587.04
2019|$67513.08
2020|$67053.88
```
Output:
```
2021|$40004.20
2020|$47905.60
2020|$73310.84
2021|$98715.03
2021|$55012.40
2021|$20448.73
2021|$50074.81
2021|$82168.48
2020|$31839.12
2020|$92819.03
2020|$67053.88
```

Use case: Output rows if column 2 (c1) has a value between -20 and +40.  
Parameters: -C c1:rg-20-40

Input:
```
49|-68|9|57
54|0|10|35
73|-19|11|1
86|39|12|62
76|-40|13|6
```
Output:
```
54|0|10|35
73|-19|11|1
86|39|12|62
```

Use case: Output a value is between -10 and -40.  
Parameters: -C c0:rg-10--40

Input:
```
15
10
5
0
-5
-10
-15
```
Output:
```
-10
-15
```

Use case: Output a value is between 10 and -10.  
Parameters: -C c0:rg10--10

Input:
```
15
10
5
0
-5
-10
-15
```
Output:
```
10
5
0
-5
-10
```

Use case: Output a value is between 1.9 and 2.1.  
Parameters: -C c0:rg1.9-2.1

Input:
```
1.7
1.8
1.9
2.0
2.1
2.2
```
Output:
```
1.9
2.0
2.1
```

## Flag: c
```-c{c0,c1,...cn}```

Count the non-empty values in given column(s), that is if a value for a specified column is empty or doesn't exist,
don't count otherwise add 1 to the column tally.

Use case: Count the number of non-empty entries in the second column (c1).  
Parameters: -cc1

Input:
```
7069|Feb|70169
7862|Feb|78162
8753|Feb|87153
7866||7866
7442|Feb|74142
6950|Feb|69150
6769|Feb|67169
```
Output:
```
7069|Feb|70169
7862|Feb|78162
8753|Feb|87153
7866||7866
7442|Feb|74142
6950|Feb|69150
6769|Feb|67169
```
Error:
```
==     count
 c1:       6
```
## Flag: D
```-D```

Displays debugging information.

Use case: Output debugging information about any transformation.  
Parameters: -D

Input:
```
12345
```
Output:
```
12345
```
Error:
```
original: 0, modified: 0 fields at line number 1.
```

## Flag: d
```-d{c0,c1,...cn}```

De-duplicates column(s) of data. The order of the columns informs pipe.pl 
the priority of column de-duplication. The last duplicate found is output to STDOUT.

Use case: De-duplicate data in the first column (c0).  
Parameters: -d c0

Input:
```
1
2
2
3
3
3
```
Output:
```
1
2
3
```

Use case: De-duplicate data prioritizing column two, then column one.  
Parameters: -d c1,c0

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
3|bat
1|cat
2|cat
3|cat
```

The count of count of duplicates can be output with [-A](#flag-a). See also [-P](#flag-p) to add a delimiter between the count and the duplicate data.

Use case: De-duplicate data prioritizing column one, then column two, and precede each output with the number of duplicates.  
Parameters: -d c0,c1 -A

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
   1 1|cat
   2 2|cat
   3 3|bat
   1 3|cat
```

Use case: De-duplicate data prioritizing column one, then column two, and precede each output with the number of duplicates, separated by a pipe character.  
Parameters: -d c0,c1 -A -P

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
1|1|cat|
2|2|cat|
3|3|bat|
1|3|cat|
```

Use case: De-duplicate data prioritizing column one, then column two, and precede each output with the number of duplicates, and change delimiter.  
Parameters: -d c0,c1 -A -P -h,

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
1,1,cat,
2,2,cat,
3,3,bat,
1,3,cat,
```

## Flag: E
```-E{cn:[r|?c.r[.e]],...}```

Replace an entire field conditionally. Similar
to the [-f](#flag-f-1) flag but replaces the entire field instead of a specific
character position. r=replacement string, c=conditional string, the
value the field must have to be replaced by r, and optionally
e=replacement if the condition failed.

'111|222|333' '-E'c1:?222.444'     => '111|444|333'
'111|222|333' '-E'c1:?aaa.444.bbb' => '111|bbb|333'

Use case: Replace column two (c1) with 'nnn'.  
Parameters: -E c1:nnn

Input:
```111|222|333 => 111|nnn|333```

Use case: Replace column two (c1) with '444' if the value of the column is '222'.  
Parameters: -E c1:?222.444

Input:
```
111|222|333
111|nnn|333
```
Output:
```
111|444|333
111|nnn|333
```

Use case: Replace column two (c1) with '444' if the value of the column is 'aaa' and 'bbb' otherwise.  
Parameters: -E c1:?aaa.444.bbb

Input:
```
111|aaa|333
111|nnn|333
```
Output:
```
111|444|333
111|bbb|333
```


## Flag: e
```-e{[any|cn]:[csv|lc|mc|pipe|uc|us|spc|normal_[W|w,S|s,D|d,P|q|Q]|order_{from}-{to}|collapse][,...]]}:```

Change the case, normalize, or order field data 
in a column to upper case (uc), lower case (lc), mixed case (mc), or
underscore (us). An extended set of commands include (spc) to replace multiple white spaces with a
single space character, and (normal_{char}) which allows the removal of 
classes of characters. For example 'NORMAL_d' removes all digits, 'NORMAL_D'
removes all non-digits from the input string. Different classes are
supported based on Perl's regex class qualifiers W,w word, D,d digit,
and S,s whitespace. 

Multiple qualifiers can be separated with a '|' character. For example normalize removing digits and non-word characters.

NORMAL_q removes single quotes.
NORMAL_Q removes double quotes in field.
NORMAL_P removes all characters that are not upper/lower case characters, digits or spaces.
normal_csv converts input CSV data into pipe-delimited data, preserving commas in quotes, but removing quote characters.

'pipe' removes pipe.pl sensitive characters (:,|).
'csv' removes commas from within quoted strings.

The order key word allows character sequences to be ordered within a field
like using -o can order fields, but order names each character within a  
field and allows those named characters to be mapped to new positions 
on output. For example: '123' -ec0:order_xyz-zyx => '321' or 
'20180911' -ec0:order_yyyymmdd-ddmmyyyy => '11092018'. If the length of
the input is longer than the variable string, the remainder of the string
is output as is. The input variable declaration must match the output 
in length and is case sensitive.

Using the keyword 'collapse' will remove empty or undefined columns values from the line.

Use case: Change c0 to upper case.  
Parameters: -e c0:uc

Input:
```
A
b
c
```
Output:
```
A
B
C
```

Use case: Change all columns to lower case.  
Parameters: -e any:lc

Input:
```ANT|BAT|CAT => ant|bat|cat```

Use case: Change all columns to capital case.  
Parameters: -e any:mc

Input:
```ANT|BAT the bat|CAT => Ant|Bat The Bat|Cat```

Use case: Change spaces to underscores in all columns.  
Parameters: -e any:us

Input:
```Bat The Bat|Cat in the hat => Bat_The_Bat|Cat_in_the_hat```

Use case: Change multiple spaces to a single in all columns.  
Parameters: -e any:spc

Input:
```Bat   The         Bat|Cat    in the   hat => Bat The Bat|Cat in the hat```

Use case: Remove non-digit characters.  
Parameters: -e c0:normal_D

Input:
```123hello => 123```

Use case: Remove all digit characters.  
Parameters: -e c0:normal_d

Input:
```123hello => hello```

Use case: Normalize by removing all non-word characters and digits.  
Parameters: -e c0:normal_d|W

Input:
```23)  Line with     lots of  #'s! => Linewithlotsofs```

Use case: NORMAL_q removes single quotes.  
Parameters: -e c0:normal_q

Input:
```this means 'this', not "that" => this means this, not "that"```

Use case: NORMAL_Q removes double quotes in field.  
Parameters: -e c0:normal_Q

Input:
```this means 'this', not "that" => this means 'this', not that```

'20180911' -ec0:order_yyyymmdd-ddmmyyyy => '11092018'

Use case: Order 123 in reverse (321).  
Parameters: -e c0:order_xyz-zyx

Input:
```123 => 321```

This can be useful when you need to reorder months, days and years in different date types.

Use case: Order the digits in a date string of YYYYMMDD to MMDDYYYY.  
Parameters: -e c0:order_yyyymmdd-mmddyyyy

Input:
```20180927 => 09272018```

Use case: Remove comma from quoted strings.  
Parameters: -e c0:csv

Input:
```
id,Animal,CS
1,"Snake, eastern indigo",4-400 - Stone
2,Silver-backed fox,11-600 - Laboratory Equipment
3,Weeper capuchin,13-120 - Pre-Engineered Structures
4,"Lemur, sportive",13-175 - Ice Rinks
5,"Egret, snowy",2 - Site Construction
6,Tree porcupine,7-100 - Damproofing and Waterproofing
7,"Sheep, red",14-900 - Transportation
8,Bengal vulture,10-400 - Identification Devices
9,Egyptian goose,12-900 - Furnishings Restoration and Repair
```
Output:   
```
id,Animal,CS
1,"Snake  eastern indigo",4-400 - Stone
2,Silver-backed fox,11-600 - Laboratory Equipment
3,Weeper capuchin,13-120 - Pre-Engineered Structures
4,"Lemur  sportive",13-175 - Ice Rinks
5,"Egret  snowy",2 - Site Construction
6,Tree porcupine,7-100 - Damproofing and Waterproofing
7,"Sheep  red",14-900 - Transportation
8,Bengal vulture,10-400 - Identification Devices
9,Egyptian goose,12-900 - Furnishings Restoration and Repair
```

Use case: Remove all punctuation leaving only upper/lower case characters, digits, and spaces.  
Parameters: -e c0:normal_P

Input:
```'Parenthetical citation': (Grady et al., 2019) => Parenthetical citation Grady et al 2019```

Use case: Normalize CSV into pipe-delimited data.
Parameters: -e c0:normal_csv

Input:
```
id,Animal,CS
1,"Snake, eastern indigo",4-400 - Stone
2,Silver-backed fox,11-600 - Laboratory Equipment
3,Weeper capuchin,13-120 - Pre-Engineered Structures
4,"Lemur, sportive",13-175 - Ice Rinks
5,"Egret, snowy",2 - Site Construction
6,Tree porcupine,7-100 - Damproofing and Waterproofing
7,"Sheep, red",14-900 - Transportation
8,Bengal vulture,10-400 - Identification Devices
9,Egyptian goose,12-900 - Furnishings Restoration and Repair
```

Output:   
```
id|Animal|CS
1|Snake, eastern indigo|4-400 - Stone
2|Silver-backed fox|11-600 - Laboratory Equipment
3|Weeper capuchin|13-120 - Pre-Engineered Structures
4|Lemur, sportive|13-175 - Ice Rinks
5|Egret, snowy|2 - Site Construction
6|Tree porcupine|7-100 - Damproofing and Waterproofing
7|Sheep, red|14-900 - Transportation
8|Bengal vulture|10-400 - Identification Devices
9|Egyptian goose|12-900 - Furnishings Restoration and Repair
```
This can be useful when you need to reorder months, days and years in different date types.

Use case: Collapse all the empty fields.  
Parameters: -e any:collapse

Input:
```1||2|||3| => 1|2|3```

Use case: Collapse all the empty fields even if only one selected.  
Parameters: -e c0:collapse

Input:
```1||2|||3| => 1|2|3```

Use case: Collapse all the empty fields even if it contains '0'.  
Parameters: -e any:collapse

Input:
```0||0|||0| => 0|0|0```


## Flag: F
```-F[cn:[b|c|d|h][.[b|c|d|h]],...}```

Outputs the field in character (c), binary (b), decimal (d)
or hexadecimal (h). A single radix defines the desired output and assumes
decimal input. A second radix (delimited from the first with a '.') instructs
pipe.pl to convert from radix 'a' to radix 'b'. Example -Fc0:b.h specifies
the input as binary, and outputs hexadecimal.

Use case: Output the binary string "1111" as hexadecimal.  
Parameters: -F c0:b.h

Input:
```1111 => f```

Use case: Output the decimal "700" as a string of binary digits.  
Parameters: -F c0:d.b

Input:
```700 => 1010111100```

Use case: Output the hexadecimal value of the character "M" and "m".  
Parameters: -F c0:c.h,c1:c.h

Input:
```M|m => 4d|6d```

## Flag: f
```-f{cn:n.p[?p[.q]],...}```

Flips an arbitrary but specific character conditionally,
where 'n' is the 0-based index of the target character. 

Use '?' to test the character's value before changing it
and optionally use a different character if the test fails.

Use case: Flip the third character (index 2) to a '9' in column 1 (c0).  
Parameters: -f c0:2.9

Input:
```0000 => 0090```

Use case: If the second character is '1' flip it to 'A', and no change otherwise.  
Parameters: -f c0:1.1?A

Input:
```0100 => 0A00```

Use case: Fail to change the character if character 1 is a '1' test fails.  
Parameters: -f c0:1.1?A

Input:
```0200 => 0200```

Use case: If the second character is '1' flip it to 'A', and 'B' otherwise.  
Parameters: -f c0:1.1?A.B

Input:
```0100 => 0A00```

Use case: If the second character is '1' flip it to 'A', and 'B' otherwise.  
Parameters: -f c0:1.1?A.B

Input:
```0200 => 0B00```

Use case: If the forth character is a '0', flip character to 'T', and 't' otherwise.  
Parameters: -f c0:3.0?T.t

Input:
```0000000 => 000T000```

## Flag: G
```-G{[any|cn]:regex,...}```

Inverse of [-g](#flag-g-1), and can be used together to perform AND operation as
return true if match on column 1, and column 2 not match. If the keyword
'any' is used, all columns must fail the match to return true. Empty regular
expressions are permitted, see [-g](#flag-g-1).

Use case: Find the line where the regular expression does not match any specified column.  
Parameters: -G c0:[7-9][7-9],c4:

Input:
```
73|19|11|1|11
86|99|12|6|12
79|40|13|68|88
32|16|18|100|18
```
Output:
```
73|19|11|1|11
86|99|12|6|12
32|16|18|100|18
```

Use case: Find the line that does not have letter characters in the second column (c1).  
Parameters: -G c1:[a-z]

Input:
```
73|qi|11|1|11
86|99|12|6|12
79|at|13|68|88
32|zi|18|100|18
```
Output:
```
86|99|12|6|12
```

Use case: Find the line that does not have letter characters all fields.  
Parameters: -G any:[a-z]

Input:
```
73|qi|11|1|11
86|99|12|6|12
79|at|13|68|88
32|zi|18|100|18
```
Output:
```
86|99|12|6|12
```

## Flag: g
```-g{[any|cn]:regex,...}```

Searches the specified field using Perl regular expressions.

Escape any commas in a regular expression because comma
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
if used in combination with [-X](#flag-x) and [-Y](#flag-y). The -g outputs just the frame that is 
bounded by [-X](#flag-x) and [-Y](#flag-y), but if -g matches, only the matching frame is output 
to STDERR, while only the -g that matches within the frame is output to STDOUT.

Use case: Match string that contains '812'.  
Parameters: -g c0:812

Input:
```1481241 => 1481241```

Use case: Output any line where the third column (c2) is '13'.  
Parameters: -g c2:13

Input:
```
13|13|11|13|13
13|13|12|13|13
13|13|13|13|13
13|13|18|13|13
```
Output:
```
13|13|13|13|13
```

Use case: Output any line that contains a '13' in it.  
Parameters: -g any:13

Input:
```
73|19|11|1|11
86|99|12|6|12
76|40|13|68|27
32|16|18|100|18
```
Output:
```
76|40|13|68|27
```

Use case: Multi-match using one regular expression.  
Parameters: -g c0:[7-9][7-9],c4:

Input:
```
73|19|11|1|11
86|99|12|6|12
79|40|13|68|88
32|16|18|100|18
```
Output:
```
79|40|13|68|88
```

## Flag: H
```-H```

Suppress new line on output. Some switches can modify this behaviour. [-i](#flag-i-1) will
suppress a new line only if the [-g](#flag-g-1) matches. New lines are suppressed starting
with any [-X](#flag-x) match until a [-Y](#flag-y) match is found.

See [-q](#flag-q-1) for setting periodic new lines.

Use case: Suppress new lines.  
Parameters: -H

Input:
```
1|
2|
3|
4|
```
Output: Ignore last newline
```
1|2|3|4|
```
  
The new line can be suppressed on a line match with virtual matching.

Use case: Suppress new line on a line match with virtual matching.  
Parameters: -H -g c0:2 -i

Input:
```
1|
2|
3|
4|
```
Output: Ignore white space
```
1|
2|3|
4|
```

Use case: Suppress new line [-X](#flag-x) and [-Y](#flag-y) matching.  
Parameters: -H -X c0:2 -Y c0:4

Input:
```
1|
2|
3|
4|
5|
```
Output: Ignore last newline
```
2|3|4|
```

## Flag: h
```-h{new_delimiter}```

Change output delimiter delimiter. See [-P](#flag-p) and [-K](#flag-k).

Use case: Change the delimiter to a comma ','.  
Parameters: -h,

Input: 
```
1|A
2|B
```
Output:
```
1,A
2,B
```

## Flag: I
```-I```

Ignore case on operations [-b](#flag-b-1), [-B](#flag-b), [-C](#flag-c-1), [-d](#flag-d-1), [-E](#flag-e), [-f](#flag-f-1), [-g](#flag-g-1), [-G](#flag-g), [-l](#flag-l-1), [-n](#flag-n-1) and [-s](#flag-s-1).

By default sorts are case-sensitive, -I sorts ascending order or decending if -R is used.

Use case: Compare two columns with [-b](#flag-b-1) ignoring differences in case.  
Parameters: -I -b c0,c1

Input:
```
a|A
B|b
A|C
```
Output:
```
a|A
B|b
```

Use case: Output lines where two columns differ ignoring differences in case.  
Parameters: -I -B c0,c1

Input:
```
a|A
B|b
A|c
```
Output:
```
A|c
```

Use case: De-duplicate data but ignore case.  
Parameters: -I -d c0

Input:
```
Cat
cAt
caT
CAT
BAT
bAt
baT
```
Output:
```
baT
CAT
```

Use case: Grep for a string case insensitively.  
Parameters: -I -g c0:cat

Input:
```
Cat
cAt
caT
CAT
BAT
bAt
baT
```
Output:
```
Cat
cAt
caT
CAT
```

Use case: Find all items that are not 'cat', ignoring case.  
Parameters: -I -G c0:cat

Input:
```
Cat
cAt
caT
CAT
BAT
bAt
baT
```
Output:
```
BAT
bAt
baT
```

Use case: Compare values in columns with -C, ignoring case.  
Parameters: -I -C c0:eqCAT

Input:
```
Cat
cAt
caT
CAT
BAT
bAt
baT
```
Output:
```
Cat
cAt
caT
CAT
```

Use case: Replace column two (c1) with 'bbb' if the value of the column is just 'A's , regardless of case.  
Parameters: -I -E c1:?aaa.BBB

Input:
```
111|AaA|333
111|nnn|333
```
Output:
```
111|BBB|333
111|nnn|333
```

Use case: Flip the third character (index 2) to a 'z' if the current character is either 'c' or 'C'.  
Parameters: -I -f c0:2.c?z

Input:
```ABCD => ABzD```

Use case: Change any "a" or "A" character to a "*".  
Parameters: -I -l c0:a.*

Input:
```AbracAdabrA => *br*c*d*br*```

Use case: Remove all spaces and non-alphanumeric characters but preserve case.  
Parameters: -I -nc0

Input:
```
cats And Dogs
120
123_b
123.f
124_C
```
Output:
```
catsAndDogs
120
123_b
123f
124_C
```

Use case: Sort in ascending order.  
Parameters: -I -sc0

Input:
```
c
D
a
d
B
C
A
b
```
Output:
```
a
A
B
b
c
C
D
d
```

Use case: Sort in descending order.  
Parameters: -I -sc0 -R

Input:
```
c
D
a
d
B
C
A
b
```
Output:
```
d
D
C
c
b
B
A
a
```

## Flag: i
```-i```

Turns on virtual matching for [-b](#flag-b-1), [-B](#flag-b), [-C](#flag-c), [-g](#flag-g-1), [-G](#flag-g), [-H](#flag-h), [-z](#flag-z-1) and [-Z](#flag-z). Normally fields are 
conditionally suppressed or output depending on the above conditional flags. '[-i](#flag-i-1)'  
allows further modifications on lines that match these conditions, while allowing 
all other lines to pass through, in order, unmodified.

Use case: Output all data and allow matches only to be manipulated.  
Parameters: -i -gc0:\d{3}19 -fc1:0.changed

Sometimes you want to modify a column but only if some value in another column matches a given expression. For example, given the following file. By default -g and -G only output match, or no match respectively. With -i all data is output and only matches are operated on by other flags.

In this example we want to change a value in c1 to 'changed' if the value in column 0 matches the regular expression.
Input:
```
86019|4|
86020|9|
86019|7|
86020|0|
86019|0|
86022|1|
```
Output:
```
86019|changed|
86020|9|
86019|changed|
86020|0|
86019|changed|
86022|1|
```

## Flag: J
```-J[min|max|avg|sum|count]{cn}```

Math operations on buckets created by de-duplicates '-d'.

Functions include `min`, `max`, `avg`, `sum`, and `count`.
See [-d](#flag-d-1), [-*](#flag-a), [-J](#flag-j), and [-P](#flag-p). 

Flag [-A](#flag-a) and [-J](#flag-j) are mutually exclusive.

Use case: De-duplicate data prioritizing column one, then column two, and sum the values in c0.  
Parameters: -J c0 -d c0,c1

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
   1 1|cat
   4 2|cat
   9 3|bat
   3 3|cat
```

Use case: Find the minimum value in the first column when de-duplicating the second column.  
Parameters: -J minc0 -d c1

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
   3 3|bat
   1 3|cat
```

Use case: Find the maximum value in the first column when de-duplicating the second column.  
Parameters: -J maxc0 -d c1

Input:
```
1|cat
2|cat
3|cat
4|cat
300|bat
399|bat
302|bat
```
Output:
```
 399 302|bat
   4 4|cat
```

Use case: Find the average of the values in the first column, group by second column.   
Parameters: -J avgc0 -d c1

Input:
```
1|cat
2|cat
3|cat
4|cat
300|bat
399|bat
302|bat
```
Output:
```
 333.67 302|bat
 2.50 4|cat
```

Use case: Find the count of the values in the first column, group by second column. Equivalent to [-A](#flag-a).   
Parameters: -J countc0 -d c1

Input:
```
1|cat
2|cat
3|cat
4|cat
300|bat
399|bat
302|bat
```
Output:
```
   3 302|bat
   4 4|cat
```

Use case: Find the sum of the values in the first column, group by second column. Equivalent to -J c0.   
Parameters: -J sumc0 -d c1

Input:
```
1|cat
2|cat
3|cat
4|cat
300|bat
399|bat
302|bat
```
Output:
```
 1001 302|bat
  10 4|cat
```

## Flag: j
```-j```

Removes the last delimiter from the last line of output when using [-P](#flag-p), [-K](#flag-k), or [-h](#flag-h-1).

Use case: Append a delimiter to the end of each line of data except the last.  
Parameters: -j -P

Input:
```
Lewis|Hamilton|1
Max|Verstappen|2
Sergio|Perez|3
Charles|Leclerc|4
```
Output:
```
Lewis|Hamilton|1|
Max|Verstappen|2|
Sergio|Perez|3|
Charles|Leclerc|4
```

## Flag: K
```-K```

Use line breaks as column delimiters.

Use case: Change delimiter to line break.  
Parameters: -K

Input:
```
1|2|3|4|5
```
Output:
```
1
2
3
4
5
```

## Flag: k
```-k{cn:expr,(...)}```

Use Perl scripting to manipulate a field. Syntax: -kcn:'(script)'
The existing value of the column is stored in an internal variable called '\$value'.

If ALLOW_SCRIPTING is set to FALSE, pipe.pl will issue an error and exit.

Use case: Increment the second column (c1).  
Parameters: -k c1:\$value++;

Input:
```
1|2
2|99
```
Output:
```
1|3
2|100
```

## Flag: L
```-L{[[+|-]?n-?m?|skip n]}```

Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
'99', line 99 only, '35-40', from lines 35 to 40 inclusive. Multiple
requests can be comma separated like this -L'1,3,8,23-45,12,-100'.
The 'skip' keyword will output alternate lines. 'skip2' will output every other line.
'skip 3' every third line and so on. The skip keyword takes precedence over
over other line output selections.

Use case: Output first three lines of output.  
Parameters: -L +3

Input:
```
1
2
3
4
5
```
Output:
```
1
2
3
```

Use case: Output last three lines of output.  
Parameters: -L -3

Input:
```
1
2
3
4
5
```
Output:
```
3
4
5
```

Use case: Output line four.  
Parameters: -L 4

Input:
```
one
two
three
four
five
```
Output:
```
four
```

Use case: Output from line 2 to the end of the input.  
Parameters: -L 2-

Input:
```
one
two
three
four
five
```
Output:
```
two
three
four
five
```

Use case: Skip every other line on output.  
Parameters: -L skip2

Input:
```
one
two
three
four
five
six
seven
```
Output:
```
two
four
six
```

Use case: Output from lines 4-6.  
Parameters: -L 4-6

Input:
```
one
two
three
four
five
six
seven
```
Output:
```
four
five
six
```

Use case: Output a combo of lines.  
Parameters: -L 4-6,2,7

Input:
```
one
two
three
four
five
six
seven
```
Output:
```
two
four
five
six
seven
```


## Flag: l
```-l{[any|cn]:exp,... }```

Translate a character sequence if present. Example: 'abcdefd' -l"c0:d.P".
produces 'abcPefP'. 3 white space characters are supported '\\s', '\\t',
and '\\n'. "Hello" -lc0:"e.\\t" => 'H       llo'
Can be made case insensitive with [-I](#flag-i). This flag also supports regular expressions so to change the first letter on every line to an underscore ('_'), use `-lcn:'^[A-Za-z]._'`

Use case: Change any "d" to a "P" in a string.  
Parameters: -l c0:d.P

Input:
```abcdefd => abcPefP```

Use case: Change any "e" character to a space.  
Parameters: -l c0:e.\s

Input:
```Hello => H llo```

Use case: Change any "a" or "A" character to a "*".  
Parameters: -l c0:a.* -I

Input:
```A is for Alphabet => * is for *lph*bet```

## Flag: M
```-M{cn:cm?cp[+cq...][.{literal}[+{literal}...]]```

Compares columns from two files and either outputs the specified column(s) 
from file two, or an optional literal string value.

File one (f1) is STDIN to pipe.pl, file two (f2) is specified with '-0' (zero).
if a specific column from f1 matches f2 columns from f2 are appended to the 
line output from f1. Additional columns can be appended with the '+' operator
and can be any order. Example ```-M c0:c0?c1+c3+c2``` means if f1's c0 matches f2's c0
then add f2's c1, c3, and c2 in that order. Further, ```-M c0:c0?c1+c3+c2.none``` means
if f1's c0 *does not match* f2's c0 then output "none". Matching behaviour can also be modified with [-I](#flag-i) and [-N](#flag-n).

Both files must use the same column delimiter, and any use of [-W](#flag-w) will
apply to both. 

Use case: Compare column from file1 and file2 if the same append data from file2.  
Parameters: -M c0:c0?c1.na -0file2

Input: file2
```
1000048|The Berenstain Bears
```

Input:
```
1000048|6|15|
1000049|10|2|
1000048|10|4|
```
Output:
```
1000048|6|15|The Berenstain Bears
1000049|10|2|na
1000048|10|4|The Berenstain Bears
```

Use case: Comparison without normalization.  
Parameters: -Mc1:c0?c0.na -0file3

Input: file3

```
one|1
two|2
4|four
threE|3
```

Input:
```
1|one
2|TWO
3|ThReE
```

Output:
```
1|one|one
2|TWO|na
3|ThReE|na
```

Use case: Normalize before comparison.  
Parameters: -M c1:c0?c0.na -0file4 -N

Input: file4
```
one|1
two|2
4|four
threE|3
```
Input:
```
1|one
2|TWO
3|ThReE
```

Output:
``` 
1|one|one
2|TWO|two
3|ThReE|threE
```

Use case: Merge record if exists and ignore otherwise.  
Parameters: -M c0:c0?c1 -0 file5 

Input: file5
```
one|three
```
Input:
```
one|two
two|one
```

Output:
``` 
one|two|three
two|one
```

Use case: Merge record if exists and add '0' otherwise.  
Parameters: -M c0:c0?c1.0 -0 file6 

Input: file6
```
one|three
```
Input:
```
one|two
two|one
```

Output:
``` 
one|two|three
two|one|0
```

Use case: Merge record if exists and add a literal '0' column and a '1' column if not.  
Parameters: -M c0:c0?c1.0+1 -0 file7 

Input: file7
```
one|three
```
Input:
```
one|two
two|one
```

Output:
``` 
one|two|three
two|one|0|1
```

## Flag: m
```-m{[any|cn]:*[_|#]|[@]*}```

Mask specified column with the mask defined after a ':', and where '_'
means suppress, '#' means output character, any other character at that
position will be inserted.

If the last character in a mask is either '_' or '#' that rule is repeated for all remaining characters in the field. Any non-rule characters are output as literals.

Characters '_', '#', '@' and ',' can be output by escaping them with a back slash (\\).

The symbol '@' outputs the field contents without any change. This is useful when you want to append content to a field but not change it.

Using -y instructs -m to insert a '.' into the string at -y places from the 
end of the string (See [-y](#flag-y-1)). This works on both numeric or alphanumeric strings.

Use case: Format ragged ANSI dates into YYYY-MM-DD date format.  
Parameters: -m c1:####-##-##_

Input:
```
OVERDUE|20120506=Date
OVERDUE|20120506 Contact customer.
OVERDUE|20120718
OVERDUE|20120506 Called already.
OVERDUE|20120506
```
Output:
```
OVERDUE|2012-05-06
OVERDUE|2012-05-06
OVERDUE|2012-07-18
OVERDUE|2012-05-06
OVERDUE|2012-05-06
```

Use case: Remove the first two character codes from all columns.  
Parameters: -m any:__#

Input:
```
NQ31221106815538|FEEPLCPL|UO21221019966206|Uf3250
FEEPLCPL|UO21221019966206|Uf3250|NQ31221106815504
NQ31221106815512|FEEPLCPL|UO21221019966206|Uf3250
FEEPLRIV|UO21221014186727|Uf8451|NQ31221106815504
NQ31221106815512|FEEPLRIV|UO21221014186727|Uf8451
```
Output:
```
31221106815538|EPLCPL|21221019966206|3250
EPLCPL|21221019966206|3250|31221106815504
31221106815512|EPLCPL|21221019966206|3250
EPLRIV|21221014186727|8451|31221106815504
31221106815512|EPLRIV|21221014186727|8451
```

Use case: Format Symphony timestamp into date and time separated by literal underscore.  
Parameters: -m c0:_####-##-##\_##:##:##_

Input:
```E201501051855331663R => 2015-01-05_18:55:33```

Use case: Add information to a column.  
Parameters: -m c0:Date\:_####-##-##_

Input:
```E201501051855331663R => Date:2015-01-05```

Use case: Insert a '.' between the forth and third last characters.  
Parameters: -m c0:# -y 3

Input:
```Readmetxt => Readme.txt```

Use case: Add content to a field without changing the field.  
Parameters: -m c0:The@BrownFox

Input:
```Quick => TheQuickBrownFox```

## Flag: N
```-N```

Normalize keys before comparison when using ([-d](#flag-d-1), [-C](#flag-c), and [-s](#flag-s-1)) de-duplicate, compare, and sort.
Normalization removes all non-word characters before comparison. Use the [-I](#flat-i)
switch to preserve keys' case during comparison. See [-n](#flag-n-1), and [-I](#flat-i).
Outputs absolute value of [-a](#flag-a-1), [-v](#flag-v-1), [-1](#flag-l-1), [-3](#flag-3), [-4](#flag-4), results.
Causes summaries to be output with delimiter to STDERR on last line.

Use case: Normalize keys before de-duplicating data. Note the last duplicate is output.  
Parameters: -N -d c0

Input:
```
Cat
cat
caT
cAt
```
Output:
```
cAt
```

Use case: Normalize keys before finding all numbers greater than 123.  
Parameters: -N -C c0:ge123

Input:
```
11_a
120xxx
123_b
123.f
124_c
```
Output:
```
123_b
123.f
124_c
```

Use case: Output column number and sum, pipe-delimited to error when adding values.  
Parameters: -N -a c0,c1

Input:
```
1|1
2|2
3|3
4|4
5|5
```
Output:
```
1|1
2|2
3|3
4|4
5|5
```
Error:
```
c0|15
c1|15
```

## Flag: n
```-n{[any|cn],...}```

Normalize the selected columns, that is, removes all non-word characters
(non-alphanumeric and '_' characters), and changing the remaining characters 
to upper case. Using the -I switch will preserve case. See [-N](#flag-n),
[-I](#flag-i) switches for more information.

Use case: Remove all spaces and non-alphanumeric characters and standardize characters to uppercase.  
Parameters: -nc0 

Input:
```
cats and dogs
120
123_b
123.f
124_c
```
Output:
```
CATSANDDOGS
120
123_B
123F
124_C
```

Use case: Remove all spaces and non-alphanumeric characters but preserve case with [-I](#flag-i).  
Parameters: -nc0 -I

Input:
```
cats And Dogs
120
123_b
123.f
124_C
```
Output:
```
catsAndDogs
120
123_b
123f
124_C
```

Use case: Remove irrelevant characters from data.  
Parameters: -nc0 

Input:
```
21221 01234 56789
(780) 555-1212
780-555-1212
```
Output:
```
212210123456789
7805551212
7805551212
```

## Flag: O
```-O{[any|cn],...}```

Merge columns. The first column is the anchor column, any others are appended to it
ie: 'aaa|bbb|ccc' -Oc2,c0,c1 => 'aaa|bbb|cccaaabbb'. Use [-o](#flag-o-1) to remove extraneous columns.
Using the 'any' keyword causes all columns to be merged in the data in first column (c0).

Use case: Merge column 1 onto the end of column 0.  
Parameters: -Oc0,c1

Input:
```aaa|bbb|ccc => aaabbb|bbb|ccc```

Use case: Merge column 0 onto the end of column 1.  
Parameters: -Oc1,c0

Input:
```aaa|bbb|ccc => aaa|bbbaaa|ccc```

Use case: Merge all columns into column 0.  
Parameters: -Oany

Input:
```aaa|bbb|ccc => aaabbbccc|bbb|ccc```


## Flag: o
```-o{c0,c1,...,cn[,continue][,last][,remaining][,reverse][,exclude]}```

Re-orders and control which columns are output.

Only specified columns are output unless the keyword 'remaining', or 'continue' are used.  
The 'remaining' keyword outputs all columns that have not already been specified, 
in order. The 'continue' keyword outputs all the columns from the last specified 
column to the last column in the line. 'last' will output the last column in a row.
'reverse' reverses the column order. The 'exclude' keyword all but the listed columns
in order. Once a keyword is encountered (except 'exclude'), any additional columns are omitted. 

Use case: Output column 3, column 2, then column 1.  
Parameters: -oc3,c2,c1

Input:
```1|2|3|4 => 4|3|2```

Use case: Output column 1 and remaining columns.  
Parameters: -oc2,remaining

Input:
```1|2|3|4 => 3|1|2|4```

Use case: Output column 2 and continue output of columns in order.  
Parameters: -oc1,continue

Input:
```1|2|3|4 => 2|3|4```

Use case: Reverse column order.  
Parameters: -o reverse

Input:
```1|2|3|4 => 4|3|2|1```

Use case: Output the last column.  
Parameters: -o last

Input:
```1|2|3|4 => 4```

Use case: Output all but the third column (c2).  
Parameters: -oc2,exclude

Input:
```1|2|3|4 => 1|2|4```


## Flag: P
```-P```

Terminates each row with the defined delimiter. By default '|' but can be changed. See '-h' for more information.

When used in conjunction with [-d de-duplicate](#flag-d-1), [-J and de-duplicate](#flag-J), and [-A and de-duplicate](#flag-A), a pipe character is inserted between the count and output data.

Use case: Terminate a row with the default pipe ("|").  
Parameters: -P

Input: 
```
1|A
2|B
```
Output:
```
1|A|
2|B|
```

Use case: Terminate a row with the delimiter specified with "-h".  
Parameters: -P -h:

Input: 
```
1|A
2|B
```
Output:
```
1:A:
2:B:
```

Use case: Separate count of duplicates from columns with a pipe character.  
Parameters: -P -d c0,c1 -A

Input:
```
1|cat
2|cat
2|cat
3|cat
3|bat
3|bat
3|bat
```
Output:
```
1|1|cat|
2|2|cat|
3|3|bat|
1|3|cat|
```

## Flag: p
```-p{cn:N.char,... }```

Pad fields left or right with arbitrary 'N' characters. The expression is separated by a
'.' character. '123' -pc0:"-5", -pc0:"-5.\s" both do the same thing: '123  '. Literal
digit(s) can be used as padding. '123' -pc0:"-5.0" => '12300'. Spaces are qualified 
with either '\s', '\t', '\n', or '_DOT_' for a literal period.

Use case: Pad a column with leading zeros.  
Parameters: -pc0:6.0

Input:
```1|2 => 000001|2```

Use case: Pad column 2 (c1) with x characters until the column is 5 characters wide.  
Parameters: -pc1:-5.x

Input:
```1|2 => 1|2xxxx```

Use case: Pad column 2 (c1) with leading dots (.) until the width of the column is 10 characters wide.  
Parameters: -pc1:10._DOT_

Input:
```1|2 => 1|.........2```

Use case: If the column is wider than the padding, do nothing.  
Parameters: -pc1:10._DOT_

Input:
```1|0123456789 => 1|0123456789```


## Flag: Q
```-Q{integer}```

Output 'n' lines before and line after a -g, or -G match to STDERR. Used to
view the context around a match, that is, the line before the match and the line after.
The lines are written to STDERR, and are immutable. The line preceding a match
is denoted by '<=', the line after by '=>'. If the match occurs on the first line
the preceding match is '<=BOF', beginning of file, and if the match occurs on
the last line the trailing match is '=>EOF'. The arrows can be suppressed with -N.

Use case: Show two lines proceeding and after a match.  
Parameters: -Q2 -gc0:5

Input:
```
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
Output:
```
5
```
Error:
```
<=3
<=4
=>6
=>7
```

*Note that in practice the stdout is sandwiched between the stderr giving the following effect.*
 ```
<=3
<=4
5
=>6
=>7
 ```

Use case: Show 3 lines before and end of file if there are not 3 lines in the file after matching.  
Parameters: -Q3 -gc0:8

Input:
```
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
Output:
```
8
```
Error:
```
<=5
<=6
<=7
=>9
=>EOF
```
*or*
 ```
<=5
<=6
<=7
8
=>9
=>EOF
 ```

Use case: Show BOF if there are not 3 lines before a match.  
Parameters: -Q3 -gc0:2

Input:
```
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
Output:
```
2
```
Error:
```
<=BOF
<=1
=>3
=>4
=>5
```

*or*
 ```
<=BOF
<=1
2
=>3
=>4
=>5
 ```

## Flag: q
```-q{lines}```

Modifies [-H](#flag-h) behaviour to allow new lines for every n-th line of output.
This has the effect of joining n-number of lines into one line.

Use case: Add a line break after every three lines of output.  
Parameters: -q3 -H

Input:
```
1|
2|
3|
4|
5|
6|
```
Output:
```
1|2|3|
4|5|6|
```

## Flag: R
```-R```

Reverse sort when using [-d](#flag-d-1), [-4](#flag-4) or [-s](#flag-s-1).

Use case: Reverse sort first column (c0).  
Parameters: -R -sc0 

Input:
```
cat
bat
hat
ant
```
Output:
```
hat
cat
bat
ant
```

Use case: Reverse sort first column (c0) alpha-numerically.  
Parameters: -R -sc0

Input:
```
5
1
3
4
10
2
```
Output:
```
5
4
3
2
10
1
```

Use case: Use the -U to sort first column (c0) numerically.  
Parameters: -R -sc0 -U

Input:
```
5
1
3
4
10
2
```
Output:
```
10
5
4
3
2
1
```

## Flag: r
```-r{percent}```

Output a random percentage of records, ie: -r100 output all lines in random order. 
-r15 outputs 15% of the input in random order. -r0 produces all output in order.

Use case: Output all values in random order.  
Parameters: -r100

 Input:
 ```
1
2
3
4
 ```
 Output:
 ```
3
1
4
2
 ```

Use case: Output all values in order.  
Parameters: -r0

Input:
```
1
2
3
4
```
Output:
```
1
2
3
4
```

## Flag: S
```-S{cn:range}```

Sub-string of a columns' contents.
Use '.' to separate discontinuous indexes, and '-' to specify ranges. The second value
in a range is not included in the range selection.

Use '.' to separate discontinuous indexes, and '-' to specify ranges.
Ie: '12345' -S'c0:0.2.4' => '135', -S'c0:0-2.4' => '1235', and -S'c0:2-' => '345'.
Reverse a string: '12345' -S'c0:4-0' => '54321'. Characters can be removed
from the end of columns with the syntax (n - m), where 'n' is a literal
that stands for the column length and 'm' the number of characters
to be trimmed from the end of the string, ie '12345' => -S'c0:0-(n -1)' = '1234'.

Use case: Output the first, third, and fifth character in the string "12345".  
Parameters: -S c0:0.2.4

Input:
```12345 => 135```

Use case: Output the first up to, but not including, the forth, and the fifth characters from "12345".  
Parameters: -S c0:0-3.4

Input:
```12345 => 1235```

Use case: Output the third character to the end of the string "12345".  
Parameters: -S c0:2-

Input:
```12345 => 345```

You can reverse a string by inverting the range.

Use case: Output the string "12345" in reverse.  
Parameters: -S c0:4-0

Input:
```12345 => 54321```

Characters can be removed from the end a string with syntax (n - m), where 'n' is a literal,
and represents the length of the data, and 'm' represents the number of characters
to be trimmed from the end of the line, as illustrated in the next use case.

Use case: Trim the last character off of the string "12345".  
Parameters: -S c0:0-(n-1)

Input:
```12345 => 1234```

Use case: Output from the forth character to the second from the last character in the string "123456".  
Parameters: -S c0:3-(n-2)

Input:
```123456 => 4```

## Flag: s
 ```-s{c0,c1,...cn}```

Sort lines based on data in specific column(s).

Use case: Sort first column (c0).  
Parameters: -sc0

Input:
```
cat
bat
hat
ant
```
Output:
```
ant
bat
cat
hat
```

Use case: Sort first column (c0) alpha-numerically.  
Parameters: -sc0

Input:
```
5
1
3
4
10
2
```
Output:
```
1
10
2
3
4
5
```

Use case: Use the -U to sort first column (c0) numerically.  
Parameters: -sc0 -U

Input:
```
5
1
3
4
10
2
```
Output:
```
1
2
3
4
5
10
```

Use case: Sort in ascending order.  
Parameters: -sc0 -I

Input:
```
c
D
a
d
B
C
A
b
```
Output:
```
a
A
B
b
c
C
D
d
```

Use case: Sort in descending order.  
Parameters: -sc0 -R -I

Input:
```
c
D
a
d
B
C
A
b
```
Output:
```
d
D
C
c
b
B
A
a
```

## Flag: T
```-T{HTML[:attributes]|MEDIA_WIKI[:h1,h2,...]|WIKI[:h1,h2,...]|MD[:h1,h2,...]|CSV[_UTF-8][:h1,h2,...]}|CHUNKED:[BEGIN={literal}][,SKIP={integer}.{literal}][,END={literal}]```

Output as a Media/Wiki table, Markdown, CSV, CSV_UTF-8 or an HTML table, with attributes.
With CSV or CSV_UTF-8 the attributes become column titles and queue pipe.pl
to consider the width of the rows on output, filling in empty values as required.
Example: -TCSV:"Name,Date,Address,Phone" or -TCSV:'Name,Date, , '.
HTML also allows for adding CSS or other HTML attributes to the ```<table>``` tag.
A bootstrap example is '1|2|3' -T'HTML:class="table table-hover"'. 

Tables can be ```CHUNKED``` into groups of lines with the optional keywords ```BEGIN```, ```SKIP```, and ```END```. 
Each corresponds to the insertion location of the literal string that follows the keyword.
SKIP will place the literal string every 'n' lines.

Use case: Output data in CSV, double-quoting all non-numeric values.  
Parameters: -TCSV:FName,LName

Input:
```
Lewis|Hamilton
Max|Verstappen
Sergio|Perez
Charles|Leclerc
Fake|Driver Name
```
Output:
```
"FName","LName"
"Lewis","Hamilton"
"Max","Verstappen"
"Sergio","Perez"
"Charles","Leclerc"
"Fake","Driver Name"
```

Use case: Output data in CSV UTF-8 format.  
Parameters: -TCSV_UTF-8:FName,LName

Input:
```
Lewis|Hamilton
Max|Verstappen
Sergio|Perez
Charles|Leclerc
Fake|Driver Name
```
Output:
```
FName,LName
Lewis,Hamilton
Max,Verstappen
Sergio,Perez
Charles,Leclerc
Fake,Driver Name
```

The next example is outputting chunked data. This is useful if you are generating sql statements and need to commit periodically.
Use case: Output a commit statement after every seventh line.  
Parameters: -TCHUNKED:BEGIN=BEGIN_TRANSACTION;,SKIP=7.COMMIT;,END=END_TRANSACTION;
Input:
```
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
```
Output:
```
BEGIN_TRANSACTION;
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
COMMIT;
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
INSERT INTO TableName (count) VALUES (1);
COMMIT;
INSERT INTO TableName (count) VALUES (1);
END_TRANSACTION;
```

Use case: Output table data as HTML.  
Parameters: -THTML:id="example"

Input:
```
1|2|3|4
5|6|7|8
10|11|12|13
```
Output:
```
<table id="example">
  <tbody>
  <tr><td>1</td><td>2</td><td>3</td><td>4</td></tr>  <tr><td>5</td><td>6</td><td>7</td><td>8</td></tr>  <tr><td>10</td><td>11</td><td>12</td><td>13</td></tr>  </tbody>
</table>
```

Use case: Output table data in MediaWiki format.  
Parameters: -TWIKI

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
{| class="wikitable"
|-
| lynx || 127.0.0.1
|-
| piper || 127.0.0.1
|-
| lister || localhost
|}
```

Use case: Output table data in Wiki format with headers.  
Parameters: -TWIKI:A,B

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
{| class="wikitable"
|- style="font-weight:bold;"
! A
! B
|-
| lynx || 127.0.0.1
|-
| piper || 127.0.0.1
|-
| lister || localhost
|}
```

Use case: Output table data in MediaWiki format.  
Parameters: -T MEDIA_WIKI

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
{| class="wikitable"
|-
| lynx
| 127.0.0.1
|-
| piper
| 127.0.0.1
|-
| lister
| localhost
|}
```

Use case: Output table data in MediaWiki format with headers.  
Parameters: -T MEDIA_WIKI:A,B

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
{| class="wikitable"
|- style="font-weight:bold;"
! A
! B
|-
| lynx
| 127.0.0.1
|-
| piper
| 127.0.0.1
|-
| lister
| localhost
|}
```

Use case: Output table data in Markdown format.  
Parameters: -TMD

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
| lynx | 127.0.0.1 | 
| piper | 127.0.0.1 | 
| lister | localhost | 
```

Use case: Output table data in Markdown format with headers.  
Parameters: -TMD:A,B

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
```
| **A** | **B** |
|:---:|---:|
| lynx | 127.0.0.1 | 
| piper | 127.0.0.1 | 
| lister | localhost | 
```

Use case: Attempt to use an undefined table type.  
Parameters: -TFOO_BAR

Input:
```
lynx|127.0.0.1
piper|127.0.0.1
lister|localhost
```
Output:
``` 
```
Error:
```
** error, unsupported table type 'FOO_BAR'
```

## Flag: t
```-t{[any|cn],...}```

Trim leading and trailing white space from column data. If [-y](#flag-y-1) is
used, the string is trimmed of white space then truncated to the length specified by [-y](#flag-y-1).

Use case: Trim leading and trailing white space on all columns.  
Parameters: -tany

Input: 
```  1 |  2  |  3 => 1|2|3```

Use case: Trim leading and trailing white space on a column.  
Parameters: -tc0,c2

Input: 
```  1 |  2  |  3 => 1|  2  |3```

## Flag: U
```-U```

Forces sorts and reverse sorts to be done based on numeric values
rather than alpha-numeric. If the data in a specified column is not 
numeric, matches fail.

See also [-C deduplicate](#flag-c-1), [-d deduplicate](#flag-d), [-R reverse a sort](#flag-R), and [-s sort](#flag-s).

Use case: Demonstrate -U coerces numeric string '5' -C'c0:ge5'.  
Parameters: -U -C c0:ge5

Input:
```
4
5
6
```
Output:
```
5
6
```

Use case: Demonstrate -U fails if non-numeric string is encountered.  
Parameters: -U -C c0:ge5

Input:
```
4
5
5a
6
```
Output:
```
5
6
```

## Flag: u
```-u{[any|cn],...}```

Encodes strings in specified columns into URL safe versions.
Use case: Encode 'This+that = the other'  
Parameters: -u c0

Input:
```This+that = the other => This%2Bthat%20%3D%20the%20other```


## Flag: V
```-V```

Deprecated. Validate that the output has the same number of columns as the input.


## Flag: v
```-v{c0,c1,...cn}```

Average over non-empty values in specified columns.

Use case: Compute the average of the first column of data.  
Parameters: -v c0

Input:
```
2.0
2.1
6.8
9.0
cat
2

7.8888
```
Output:
```
2.0
2.1
6.8
9.0
cat
2

7.8888
```
Error:
```
==   average
 c0:    4.96
```

## Flag: W
```-W{delimiter}```

Change the input delimiter.

Use case: change input delimited to ":".  
Parameters: -W:

Input: 
```a:b => a|b```

## Flag: w
```-w{c0,c1,...cn}```

Report min and max number of characters in specified columns, and reports
the minimum and maximum number of columns by line.

Use case: Report the max, min number of characters in an arbitrary but specific column, and the max and min number of columns in the input data to STDERR.   
Parameters: -w c0

Input:
```
Lewis|Hamilton|1
Max|Verstappen|2
Sergio|Perez|3
Charles|Leclerc|4
Fake|Driver Name|5
Driver
```
Output:
```
Lewis|Hamilton|1
Max|Verstappen|2
Sergio|Perez|3
Charles|Leclerc|4
Fake|Driver Name|5
Driver
```
Error:
```
== width
 c0: min:  3 at line 2, max:  7 at line 4, mid: 5.0
 number of columns:  min: 1 at line: 6, max: 3 at line: 5, variance: 1
```

## Flag: X
```-X{[any|cn]:regex,...}```

Like the [-g](#flag-g), but once a line matches all subsequent lines are also
output until a [-Y](#flag-y-1) match succeeds.

If the keyword 'any' is used the first column to match will return true.

Use case: Output all from test 'Q' and after.  
Parameters: -Xc0:Q

Input:
```
test-v
test-u
test-q
test-3
test-?
test-V
test-7
test-Q
test-w
test-a
test-o
test-U
test-6
test-O
test-p
test-t
test-5
test-M
test-T
test-S
```
Output:
```
test-Q
test-w
test-a
test-o
test-U
test-6
test-O
test-p
test-t
test-5
test-M
test-T
test-S
```

## Flag: x
```-x```

Outputs usage message and exits.

## Flag: Y
```-Y{[any|cn]:regex,...}```

Stops [-X](#flag-x) output if -Y matches. See [-X](#flag-x) and [-g](#flag-g-1).

In this way it can be used to output lines between two milestones.

Use case: Output all data between test 'Q' and test 'o'.  
Parameters: -Yc0:o -Xc0:Q

Input:
```
test-v
test-u
test-q
test-3
test-?
test-V
test-7
test-Q
test-w
test-a
test-o
test-U
test-6
test-O
test-p
test-t
test-5
test-M
test-T
test-S
```
Output:
```
test-Q
test-w
test-a
test-o
```

Use case: Output lines starting 2022-01-05 until the next time c1 = 2.  
Parameters: -Y c1:2 -X c0:2022-01-05

Input:
```
2022-01-01|2
2022-01-02|2
2022-01-03|1
2022-01-04|1
2022-01-05|1
2022-01-06|1
2022-01-07|2
2022-01-08|2
2022-01-09|2
2022-01-10|1
```
Output:
```
2022-01-05|1
2022-01-06|1
2022-01-07|2
```

## Flag: y
```-y{integer}```

Controls precision of computed floating point number output. When used with -t, selected columns are truncated to 'n' characters wide.

Use case: Output 5 decimal places of a accuracy instead of the default two.  
Parameters: -y 5 -v c0

Input:
```
2.0
2.1
6.8
9.0
cat
2

7.8888
```
Output:
```
2.0
2.1
6.8
9.0
cat
2

7.8888
```
Error:
```
==   average
 c0: 4.96480
```

Use case: Truncate 6 characters off the end of the string in the first column.  
Parameters: -y 6 -t c0

Input:
```one.......|two => one...|two```


## Flag: Z
```-Z{c0,c1,...cn}```

Show line if the specified column(s) are empty, or don't exist. See ([-i](#flag-i-1)).

Use case: Express line if the second column (c1) is empty.  
Parameters: -Zc1

Input:
```
c0|c1|c2|c3|c4
60||1|63|1
76|95|2|86|2
58||3||3
```

Output:
```
60||1|63|1
58||3||3
```

## Flag: z
```-z{c0,c1,...cn}```

Suppress line if the specified column(s) are empty, or don't exist. Works with the virtualization flag [-i](#flag-i-1).

Use case: Suppress line if the second column (c1) is empty.   
Parameters: -z c1

Input:
```
c0|c1|c2|c3|c4
60||1|63|1
76|95|2|86|2
58||3||3
```
Output:
```
c0|c1|c2|c3|c4
76|95|2|86|2
```

## API Cheat Sheet
  ```console
  [cat file|echo value] | pipe.pl [-5ADiIjKLNUVx] [-0{file} -M{options}] [options]
  ```

[-?](#flag-?) ```-?{opr}:{c0,c1,...,cn}```     
[-0](#flag-0) ```-0{file_name}[-Mcn:cm?cp[+cq...][.{literal}]```     
[-1](#flag-1) ```-1{c0,c1,...cn}```     
[-2](#flag-2) ```-2{cn:[start,[end]]}```     
[-3](#flag-3) ```-3{c0[:n],c1,...cn}```     
[-4](#flag-4) ```-4{c0,c1,...cn}```     
[-6](#flag-6) ```-6{cn:[char]}```     
[-7](#flag-7) ```-7{positive-integer}```   
[-a](#flag-a-1) ```-a{c0,c1,...cn}```   
[-B](#flag-b)|[b](#flag-b-1) ```-B|b{c0,c1,...cn}```   
[-c](#flag-c-1) ```-c{c0,c1,...cn}```   
[-C](#flag-c) ```-C{any|num_cols{n-m}|cn:(gt|ge|eq|le|lt|ne|rg{n-m}|width{n-m})|cc(gt|ge|eq|le|lt|ne)cm,...}```   
[-d](#flag-d-1) ```[-IRN]{c0,c1,...,cn} [-A|-J{cn}]```   
[-e](#flag-e-1) ```-e{[any|cn]:[csv|lc|mc|pipe|uc|us|spc|normal_[W|w,S|s,D|d,P|q|Q]|order_{from}-{to}][,...]]}:```      
[-E](#flag-e) ```-E{cn:[r|?c.r[.e]],...}```   
[-f](#flag-f-1) ```-f{cn:n.p[?p[.q]],...}```   
[-F](#flag-f) ```-F[cn:[b|c|d|h][.[b|c|d|h]],...}```   
[-g](#flag-g-1)|[G](#flag-g) ```{any|c0,c1,...,cn:[regex],...} [-5iI]```   
[-h](#flag-h-1) ```-h{new_delimiter}```   
[-H](#flag-h)  ```[-q{positive integer}]```   
[-J](#flag-j) ```-J{cn}```      
[-k](#flag-k-1) ```-k{cn:expr,(...)}```   
[-l](#flag-l-1) ```-l{[any|cn]:exp,... }```   
[-L](#flag-l) ```-L{[[+|-]?n-?m?|skip n]}```   
[-m](#flag-m-1) ```-m{[any|cn]:*[_|#]|[@]*}```   
[-M](#flag-m) ```{cn:cm?cp[+cq...][.{literal}[+{literal}...]]```    
[-n](#flag-n-1) ```-n{[any|cn],...}```   
[-O](#flag-o) ```-O{[any|cn],...}```   
[-o](#flag-o-1) ```-o{c0,c1,...,cn[,continue][,last][,remaining][,reverse][,exclude]}```   
[-p](#flag-p-1) ```-p{cn:N.char,... }```   
[-q](#flag-q-1) ```-q{integer}```   
[-Q](#flag-q) ```-Q{integer}```   
[-r](#flag-r-1) ```-r{percent}```   
[-s](#flag-s-1) ```-s{c0,c1,...,cn} [-IRN]```   
[-S](#flag-s) ```-S{cn:range}```   
[-t](#flag-t-1) ```-t{[any|cn],...} [-y {integer}]```   
[-T](#flag-t) ```-T{HTML[:attributes]|MEDIA_WIKI[:h1,h2,...]|WIKI[:h1,h2,...]|MD[:h1,h2,...]|CSV[_UTF-8][:h1,h2,...]}|CHUNKED:[BEGIN={literal}][,SKIP={integer}.   {literal}][,END={literal}]```   
[-u](#flag-u-1) ```-u{[any|cn],...}```   
[-v](#flag-v-1) ```-v{c0,c1,...cn}```   
[-w](#flag-w-1) ```-w{c0,c1,...cn}```   
[-W](#flag-w) ```-W{delimiter}```   
[-X](#flag-x) ```-X{[any|cn]:regex,...} [-Y{[any|cn]:regex,...} [-g{[any|cn]:regex,...}]]```   
[-y](#flag-y-1) ```-y{integer}```   
[-Y](#flag-y) ```-Y{[any|cn]:regex,...}```   
[-z](#flag-z-1)|[Z](#flag-z) ```-[Z|z]{c0,c1,...cn} [-i]```   
   