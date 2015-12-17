Usage notes for pipe.pl. This application is a accumulation of helpful scripts that performs common tasks on pipe-delimited files. The count function (-c), for example counts the number of non-empty values in the specified columns. Other functions work similarly. Stacked functions are operated on in alphabetical order by flag letter, that is, if you elect to order columns and trim columns, the columns are first ordered, then the columns are trimmed, because -o comes before -t. The exceptions to this rule are those commands that require the entire file to be read before operations can proceed (-d dedup, -r random, and -s sort). Those operations will be done first then just before output the remaining operations are performed.
Example:
cat file.lst | pipe.pl -c'c0'
pipe.pl only takes input on STDIN. All output is to STDOUT. Errors go to STDERR.
Things pipe.pl can do
---------------------
1.  Trim arbitrary fields.
2.  Order and suppress output of arbitrary fields.
3.  Randomize all, or a specific sample size of the records from input.
4.  De-duplicate records from input.
5.  Count non-empty fields from input records.
6.  Summation over non-empty numeric values of arbitrary fields.
7.  Sort input lines based on one or more arbitrary fields, numerically or lexical-ly.
8.  Mask output of specific characters, and range of characters, within arbitrary fields.
9.  Averages over columns.
10. Output line numbers or counts of dedups.
11. Force trailing pipe on output.
12. Grep a specific column value with regular expressions.
13. Compare columns for differences.
14. Flexibly pad output fields.
15. Report maximum and minimum width of column data.
16. Output sub strings of values in columns by specific index or range of indices.
17. Change case of fields.
18. Flip character value conditionally.
19. Output characters in different bases.
20. Replace values in columns conditionally.
21. Translate values within columns.
22. Compute new column values based on values in other columns recursively.

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
 -a[c0,c1,...cn]: Sum the non-empty values in given column(s).
 -A             : Modifier that outputs the number of key matches from dedup.
                  The end result is output similar to 'sort | uniq -c' ie: ' 4 1|2|3'
                  for a line that was duplicated 4 times on a given key. If
                  -d is not selected, line numbers of successfully matched lines
                  are output. If the last 10 lines of a file are selected, the output
                  are numbered from 1 to 10 but if other match functions like -g -G -X or -Y
                  are used, the successful matched line is reported.
 -b[c0,c1,...cn]: Compare fields and output if each is equal to one-another.
 -B[c0,c1,...cn]: Compare fields and output if columns differ.
 -c[c0,c1,...cn]: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -C[any|c0:[gt|lt|eq|ge|le]value,... ]: Compare column and output line if value in column
                  is greater than (gt), less than (lt), equal to (eq), greater than
                  or equal to (ge), or less than or equal to (le) the value that follows.
                  The following value can be numeric, but if it isn't the value's
                  comparison is made lexically. All specified columns must match to return
                  true, that is '-C' is logically AND across columns. This behaviour changes
                  if the keyword 'any' is used, in that case test returns true as soon  
                  as any column comparison matches successfully.
 -d[c0,c1,...cn]: Dedups file by creating a key from specified column values
                  which is then over written with lines that produce
                  the same key, thus keeping the most recent match. Respects (-r).
 -D             : Debug switch.
 -e[c0:[uc|lc|mc|us],...]: Change the case of a value in a column to upper case (uc),
                  lower case (lc), mixed case (mc), or underscore (us).
 -E[c0:[r|?c.r[.e]],...]: Replace an entire field conditionally, if desired. Similar
                  to the -f flag but replaces the entire field instead of a specific
                  character position. r=replacement string, c=conditional string, the
                  value the field must have to be replaced by r, and optionally
                  e=replacement if the condition failed.
                  Example: '111|222|333' '-E'c1:nnn' => '111|nnn|333'
                  '111|222|333' '-E'c1:?222.444'     => '111|444|333'
                  '111|222|333' '-E'c1:?aaa.444.bbb' => '111|bbb|333'
 -f[c0:n[.p|?p.q[.r]],...]: Flips an arbitrary but specific character conditionally,
                  where 'n' is the 0-based index of the target character. A '?' means
                  test the character equals p before changing it to q, and optionally change
                  to r if the test fails. Works like an if statement.
                  Example: '0000' -f'c0:2.2' => '0020', '0100' -f'c0:1.A?1' => '0A00',
                  '0001' -f'c0:3.B?0.c' => '000c', finally
                  echo '0000000' | pipe.pl -f'c0:3?1.This.That' => 000That000.
 -F[c0:[x|b|d],...]: Outputs the field in hexidecimal (x), binary (b), or decimal (d).
 -g[any|c0:regex,...]: Searches the specified field for the regular (Perl) expression.
                  Example data: 1481241, -g"c0:241$" produces '1481241'. Use
                  escaped commas specify a ',' in a regular expression because comma
                  is the column definition delimiter. Selecting multiple fields acts
                  like an AND function, all fields must match their corresponding regex
                  for the line to be output. The behaviour of -g turns into OR if the
                  keyword 'any' is used. In that case all other column specifications
                  are ignored and any successful match will return true.
 -G[any|c0:regex,...]: Inverse of '-g', and can be used together to perform AND operation as
                  return true if match on column 1, and column 2 not match. If the keyword
                  'any' is used, all columns must fail the match to return true.
 -h             : Change delimiter from the default '|'. Changes -P and -K behaviour, see -P, -K.
 -H             : Suppress new line on output.
 -I             : Ignore case on operations (-d, -g, -G, and -s) dedup grep and sort.
 -kcn:(expr_n(expr_n-1(...))): Use scripting command to add field. Syntax: -k'cn:(script)'
                  where [script] are pipe commands defined like (-f'c0:0?p.q.r' -> -S'c0:0-3')
                  and the result would be put in field c1, clobbering any value there. To
                  preserve the results, place it at the end of the expected output with a very
                  large column number.
                  '20151110|Andrew' -k"c100:(-f'c0:3?5.6.4'),c0:(-S'c1:0-3')" => 'Andr|20161110'
                  '20151110' -k"c100:(-Sc0:0-4(-fc0:3?5.6.4)) => '20151110|2016'
                  '20151110' -k'c0:(-tc0(-pc0:20 ))' => '20151110', pad upto 20 chars left, then trim.
 -K             : Use line breaks instead of the current delimiter between columns (default '|').
                  Turns all columns into rows.
 -l[c0:exp,... ]: Translate a character sequence if present. Example: 'abcdefd' -l"c0:d.P".
                  produces 'abcPefP'.
 -L[[+|-]?n-?m?]: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Multiple 
                  requests can be comma separated like this -L'1,3,8,23-45,12,-100'.
 -m[c0:*[_|#]*] : Mask specified column with the mask defined after a ':', and where '_'
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
 -n[any|c0,c1,...cn]: Normalize the selected columns, that is, make upper case and remove white space.
 -N             : Normalize keys before comparison when using (-d and -s) dedup and sort.
                  Makes the keys upper case and remove white space before comparison.
                  Output is not normalized. For that see (-n).
                  See also (-I) for case insensitive comparisons.
 -o[c0,c1,...cn]: Order the columns in a different order. Only the specified columns are output.
 -p[c0:exp,... ]: Pad fields left or right with white spaces. 'c0:-10.,c1:14 ' pads 'c0' with a
                  maximum of 10 trailing '.' characters, and c1 with upto 14 leading spaces.
 -P             : Ensures a tailing delimiter is output at the end of all lines.
                  The default delimiter of '|' can be changed with -h.
 -r<percent>    : Output a random percentage of records, ie: -r100 output all lines in random
                  order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
 -R             : Reverse sort (-d and -s).
 -s[c0,c1,...cn]: Sort on the specified columns in the specified order.
 -S[c0:range]   : Sub string function. Like mask, but controlled by 0-based index in the columns' strings.
                  Use '.' to separate discontinuous indexes, and '-' to specify ranges.
                  Ie: '12345' -S'c0:0.2.4' => '135', -S'c0:0-2.4' => '1235', and -S'c0:2-' => '345'.
                  Note that you can reverse a string by reversing your selection like so:
                  '12345' -S'c0:4-0' => '54321', but -S'c0:0-4' => '1234'.
 -t[any|c0,c1,...cn]: Trim the specified columns of white space front and back.
 -T[HTML|WIKI]  : Output as a Wiki table or an HTML table.
 -u[any|c0,c1,...cn]: Encodes strings in specified columns into URL safe versions.
 -U             : Sort numerically. Multiple fields may be selected, but an warning is issued
                  if any of the columns used as a key, combined, produce a non-numeric value
                  during the comparison. With -C, non-numeric value tests always fail, that is
                  '12345a' -C'c0:ge12345' => '12345a' but '12345a' -C'c0:ge12345' -U fails.
 -v[c0,c1,...cn]: Average over non-empty values in specified columns.
 -V             : Validate that the output has the same number of columns as the input.
 -w[c0,c1,...cn]: Report min and max number of characters in specified columns, and reports
                  the minimum and maximum number of columns by line.
 -W[delimiter]  : Break on specified delimiter instead of '|' pipes, ie: "\^", and " ".
 -x             : This (help) message.
 -X[any|c0:regex,...]: Like the '-g' flag, grep columns for values, and if matched, either
                  start outputting lines, or output '-Y' matches if selected. See '-Y'.
                  If the keyword 'any' is used the first column to match will return true.
 -Y[any|c0:regex,...]: Like the '-g', search for matches on columns after initial match(es)
                  of '-X' (required). See '-X'.
                  If the keyword 'any' is used the first column to match will return true.
 -z[c0,c1,...cn]: Suppress line if the specified column(s) are empty, or don't exist.
 -Z[c0,c1,...cn]: Show line if the specified column(s) are empty, or don't exist.
```

**Note**: I recommend that you put your command line flags in alphabetical order as in the example below.
Order of operations
-------------------
The order of operations is as follows:
```
  -x - Usage message, then exits.
  -X - Grep values in specified columns, start output, or start searches for -Y values.
  -Y - Grep values in specified columns once greps with -X succeeds.
  -k - Run a series of scripted commands.
  -L - Output only specified lines, or range of lines.
  -A - Displays line numbers or summary of duplicates if '-D' is selected.
  -u - Encode specified columns into URL-safe strings.
  -C - Conditionally test column values.
  -e - Change case of string in column.
  -E - Replace string in column conditionally.
  -f - Modify character in string based on 0-based index.
  -F - Format column value into bin, hex, or dec.
  -G - Inverse grep specified columns.
  -g - Grep values in specified columns.
  -m - Mask specified column values.
  -S - Sub string column values.
  -l - Translate character sequence.
  -n - Remove white space and upper case specified columns.
  -t - Trim selected columns.
  -I - Ingnore case on sort and dedup. See '-d', '-s', '-g', '-G', and '-n'.
  -d - De-duplicate selected columns.
  -r - Randomize line output.
  -s - Sort columns.
  -b - Suppress line output if columns' values differ.
  -B - Only show lines where columns are different.
  -Z - Show line output if column(s) test empty.
  -z - Suppress line output if column(s) test empty.
  -w - Output minimum an maximum width of column data.
  -a - Sum of numeric values in specific columns.
  -c - Count numeric values in specified columns.
  -v - Average numerical values in selected columns.
  -T - Output in table form.
  -V - Ensure output and input have same number of columns.
  -K - Output everything as a single column.
  -o - Order selected columns.
  -P - Add additional delimiter if required.
  -H - Suppress new line on output.
  -h - Replace default delimiter.
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
Pipe supports currently supports output as HTML or MediaWiki table format.
```
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o'c3,c4,c6,c7' -m'c3:_____###,c4:__#,c6:__#,c7:__##_##_####' -s'c2' -T'HTML'
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

Dedup with counts compared to line counts ('-A')
------------------------------------------------
To output the data set with line counts:
```
cat test.lst | pipe.pl -A
 1  86019|4|
 2  86019|9|
 3  86019|7|
 4  86019|0|
 5  86019|0|
 6  86019|1|
```
With -d the line count feature changes to reporting the number of redundant lines.
```
cat test.lst | pipe.pl -d'c0' -A
6 86019|1|
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
cat pad.lst | pipe.pl -pc0:5.
....1
...12
..123
.1234
12345
cat pad.lst | pipe.pl -pc0:-5.
1....
12...
123..
1234.
12345
```
Multiple characters may be used, but each string counts as a single padding sequence as shown in the next example.
```
echo 21221012345678 | pipe.pl -p'c0:17dot'
dotdotdot21221012345678
```
and
```
echo 21221012345678 | pipe.pl -p'c0:-17dot'
21221012345678dotdotdot
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

Changing case with '-e'
-----------------------
You can change the case of data in a column with '-e' as in this example:
```
echo 'upper case|mIX cASE|LOWER CASE|12345678|hello world' | pipe.pl -e'c0:uc,c1:mc,c2:Lc,c3:UC,c4:us'
UPPER CASE|Mix Case|lower case|12345678|hello_world
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
echo "Catkey 1456824 has 114 T024's" | pipe.pl -W'\s+' -l"c4:\'. "
Catkey|1456824|has|114|T024s
```
Replace all the '8's within a column.
```
echo "Catkey 1481241 has 134 T024's" | pipe.pl -W'\s+' -l'c1:1.8'
Catkey|8488248|has|134|T024's
```
An entry that has no value in 'c0', you can add a default value with:
```
echo "|Catkey|8488248|has|134|T024's" | pipe.pl -l'c0:^$.NA'
NA|Catkey|8488248|has|134|T024's
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

cat p.lst | ./p.exp.pl -d'c2' -A  -h'^'
   2 1^2^3
   2 1^2^4

cat p.lst | ./p.exp.pl -d'c2' -A -P -h'^'
2^1^2^3^
2^1^2^4^
```
-W and -h work independantly.
```
cat s.lst
E201411051046470005R ^S01JZFFBIBLIOCOMM^FcNONE^FEEPLCPL^UO21221019966206^Uf3250^NQ31221106815538^HB11/05/2015^HKTITLE^HOEPLCPL^^O00108

cat s.lst | ./p.exp.pl -W'\^' -h'#'
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
Search for '2' in column 0, then output any line where column 0 matches '6'.
```
cat x.lst | pipe.pl -X'c0:2+' -Y'c0:6' 
2
6
```

