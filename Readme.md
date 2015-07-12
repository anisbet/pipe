Usage notes for /s/sirsi/Unicorn/Bincustom/pipe.pl. This application is a accumulation of helpful scripts that performs common tasks on pipe-delimited files. The count function (-c), for example counts the number of non-empty values in the specified columns. Other functions work similarly. Stacked functions are operated on in alphabetical order by flag letter, that is, if you elect to order columns and trim columns, the columns are first ordered, then the columns are trimmed, because -o comes before -t. The exceptions to this rule are those commands that require the entire file to be read before operations can proceed (-d dedup, -r random, and -s sort). Those operations will be done first then just before output the remaining operations are performed.
Example:
cat file.lst | pipe.pl -c“c0”
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

A note on usage; because of the way this script works it is quite possible to produce mystifying results. For example, failing to remember that ordering comes before trimming may produce perplexing results. You can do multiple transformations, but if you are not sure you can pipe output from one process to another pipe process. If you order column so that column 1 is output then column 0, but column 0 needs to be trimmed you would have to write:
```
cat file | pipe.pl -o“c1,c0” -t“c1”
```
because -o will first order the row, so the value you want trimmed is now c1. If that is too radical to contemplate then:
```
cat file | pipe.pl -t“c0” | pipe.pl -o“c1,c0”
```
**Note**: I recommend that you put your command line flags in alphabetical order as in the example below.
Order of operations
-------------------
The order of operations is as follows:
```
-x - Usage message, then exits.
-L - Output only specified lines, or range of lines.
-a - Sum of numeric values in specific columns.
-A - Displays line numbers or summary of duplicates if '-D' is selected.
-c - Count numeric values in specified columns.
-u - Encode specified columns into URL-safe strings.
-G - Inverse grep specified columns.
-g - Grep values in specified columns.
-m - Mask specified column values.
-n - Remove white space and upper case specified columns.
-o - Order selected columns.
-t - Trim selected columns.
-v - Average numerical values in selected columns.
-I - Ingnore case on sort and dedup. See '-d', '-s', and '-n'.
-d - De-duplicate selected columns.
-r - Randomize line output.
-s - Sort columns.
-b - Suppress line output if columns' values differ.
-B - Only show lines where columns are different.
-z - Suppress line output if column(s) test empty.
-w - Output minimum an maximum width of column data.
-T - Output in table form.
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
cat file | pipe.pl -a“c3” -c“c0” -o“c1,c3” -s“c0” -W" "
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
cat test.lst | ./pipe.pl -W' '  -c“c0”
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
c0:      31
cat t.lst | ./pipe.pl -W' ' -G'c3:^1..' -c“c0”
Catkey|1458804|has|284|T024's
Catkey|1465466|has|206|T024's
Catkey|1474423|has|301|T024's
Catkey|1476430|has|410|T024's
Catkey|1478591|has|207|T024's
Catkey|1478687|has|624|T024's
Catkey|1481038|has|246|T024's
== count
c0:       7
cat t.lst | ./pipe.pl -W' ' -g'c1:^148' -G'c3:2.6' -c“c0”
Catkey|1480485|has|168|T024's
Catkey|1481241|has|134|T024's
== count
 c0:       2
```
```
cat t.lst | ./pipe.pl -W' ' -g“c3:^20.$”  -c“c0”
Catkey|1465466|has|206|T024's
Catkey|1478591|has|207|T024's
== count
c0:       2
```
Cleaning log entries using masks, outputting as tables
------------------------------------------------------
Masks work using two special characters '\#' to print a character, and '\_' to suppress a character. Any other character is output as-is, in order, until both the mask and the input string are exhausted. The special characters can also be output as literals if they are escaped with a back slash '\\'.
If the last character of the mask is a special character '\#' or '\_', the default behavior is to output, or suppress, the rest of the contents of the field.
```
echo “abcd” | ./pipe.pl -m“c0:#”
abcd
echo “abcd” | ./pipe.pl -m“c0:#_”
a
echo “abcd” | ./pipe.pl -m“c0:#_#”
acd
cat printlist | pipe.pl -g'c5:adutext' -o'c0,c2,c3' | pipe.pl -m'c1:####-##-##_,c0:/s/sirsi/Unicorn/Rptprint/####.prn'
...
/s/sirsi/Unicorn/Rptprint/mxnd.prn|2015-05-29|OK
/s/sirsi/Unicorn/Rptprint/mxrt.prn|2015-05-30|OK
/s/sirsi/Unicorn/Rptprint/mxva.prn|2015-05-31|OK
/s/sirsi/Unicorn/Rptprint/myhf.prn|2015-06-01|ERROR
/s/sirsi/Unicorn/Rptprint/mypu.prn|2015-06-03|OK
/s/sirsi/Unicorn/Rptprint/mzbb.prn|2015-06-03|OK
...
echo “abcd” | ./pipe.pl -m“c0:/foo/bar/#\_”
/foo/bar/a_
echo “abcd” | ./pipe.pl -m“c0:/foo/bar/________________.List”
/foo/bar/.List
echo “abcd” | ./pipe.pl -m“c0:/foo/bar/\_\_\_\_\_\_.List”
/foo/bar/______.List
echo “abcd” | ./pipe.pl -m“c0:/foo/bar/#\#”
/foo/bar/a#
echo “Balzac Billy, 21221012345678” | pipe.pl -W',' -m'c0:####_...,c1:___________#'
Balz...|5678
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
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o“c3,c4,c6,c7” -m“c3:_____###,c4:__#,c6:__#,c7:__##_##_####”
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
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o“c3,c4,c6,c7” -m“c3:_____###,c4:__#,c6:__#,c7:__##_##_####” -s“c2”
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

Or as a table?
```
bash-3.2$ head holds_1411.lst | pipe.pl -W"\^" -o“c3,c4,c6,c7” -m“c3:_____###,c4:__#,c6:__#,c7:__##_##_####” -s“c2” -T“HTML”
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
bash-3.2$  cat s.lst | pipe.pl -W"\^" -o“c0,c3” -m“c0:_####/##/## ##:##:##_,c3:_____###” -T“HTML”
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

Formatting troublesome Unix tool outputs like **ls -la**, and a handy hack with masks
-------------------------------------------------------------------------------------
```
 ls -l gpn hist/ | egrep -e '(2014(0[6-9]|1[0-2])|20150[1-6])' 
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
ls -l gpn hist/ | egrep -e '(2014(0[6-9]|1[0-2])|20150[1-6])' | pipe.pl -W'\s+' -o'c8' 
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
ls -l gpn hist/ | egrep -e '(2014(0[6-9]|1[0-2])|20150[1-6])' | pipe.pl -W'\s+' -o'c8' -m “c8:/s/sirsi/Unicorn/Hist/#”
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

```
cat test.lst
1010152186019|4|
1010152186019|9|
1010152186019|7|
1010152186019|0|
1010152186019|0|
1010152186019|1|
cat test.lst | pipe.pl -d'c0' -A
6 1010152186019|1|
cat test.lst | pipe.pl -A
 1  1010152186019|4|
 2  1010152186019|9|
 3  1010152186019|7|
 4  1010152186019|0|
 5  1010152186019|0|
 6  1010152186019|1|
 ```

Width reporting
---------------
Pipe can report the shortest and longest field of selected fields.
```
cat test.lst | ./pipe.pl -W'\s+' -w"c8" -A -L'10-13' 
 ...
 10 drwxr-xr-x@|43|anisbet|staff|1462|1|May|21:39|MeCard
 11 drwxr-xr-x@|10|anisbet|staff|340|1|May|21:36|MetroGUI
 12 drwxr-xr-x@|9|anisbet|staff|306|1|May|21:40|NewFolder
 13 drwxr-xr-x@|3|anisbet|staff|102|1|May|21:35|VisualStudio
 ...
== width
 c8: min:  6 at line 10, max: 12 at line 13, mid: 9.0
 ```
Another example

```
drwxr-xr-x@|41|anisbet|staff|1394|10|May|21:06|blender
drwxr-xr-x@|7|anisbet|staff|238|1|May|21:34|c
drwxr-xr-x@|7|anisbet|staff|238|2|May|11:04|createyourproglang
drwxr-xr-x@|6|anisbet|staff|204|1|May|22:02|cybera
drwxr-xr-x@|11|anisbet|staff|374|1|May|21:36|d3
== width
 c1: min:  1 at line 17, max:  2 at line 16, mid: 1.5
 c6: min:  3 at line 16, max:  3 at line 16, mid: 3.0
 c8: min:  1 at line 17, max: 18 at line 18, mid: 9.5
```

Encode string in URL safe characters
------------------------------------
```
echo “Hello World!” | pipe.pl -u'c0'
Hello%20World%21
```

Padding example
---------------
Padding allows you to pad a field to a maximum of 'n' fill characters. If the string you are padding is longer than the requested pad field width, the field will be output unaffected. A negative number denotes that the padding should be added to the end of the field, a '+', or no modifier, denotes padding on the front of the string. If you don't specify a padding character a single white space is used.
```
echo 21221012345678 | pipe.pl -p'c0:-16:'
21221012345678::
echo 21221012345678 | pipe.pl -p'c0:16:'
::21221012345678
echo 21221012345678 | pipe.pl -p'c0:+16:'
::21221012345678
```
Multiple characters may be used, but each string counts as a single padding sequence as shown in the next example.
```
echo 21221012345678 | pipe.pl -p'c0:16this'
thisthis21221012345678
```
and
```
echo 21221012345678 | pipe.pl -p'c0:-16this'
21221012345678thisthis
```

See also **-m** for additional formatting features.

Usage
-----
The script is a stand alone Perl script, and requires no special libraries.
Flags
-----
```
-a[c0,c1,...cn]: Sum the non-empty values in given column(s).
-A             : Modifier that outputs the number of key matches from dedup.
                 The end result is output similar to 'sort | uniq -c' ie: ' 4 1|2|3'
                 for a line that was duplicated 4 times on a given key. If 
                 -d is not selected, each line of output is numbered sequentially
                 prior to output. 
-b[c0,c1,...cn]: Compare fields and output if each is equal to one-another.
-B[c0,c1,...cn]: Compare fields and output if columns differ.
-c[c0,c1,...cn]: Count the non-empty values in given column(s), that is
                 if a value for a specified column is empty or doesn't exist,
                 don't count otherwise add 1 to the column tally. 
-d[c0,c1,...cn]: Dedups file by creating a key from specified column values 
                 which is then over written with lines that produce
                 the same key, thus keeping the most recent match. Respects (-r).
-D             : Debug switch.
-g[c0:regex,...]: Searches the specified field for the regular (Perl) expression.  
                 Example data: 1481241, -g“c0:241$” produces '1481241'. Use 
                 escaped commas specify a ',' in a regular expression because comma
                 is the column definition delimiter. See also '-m' mask.
-G[c0:regex,...]: Inverse of '-g', and can be used together to perform AND operation as
                 return true if match on column 1, and column 2 not match.
-I             : Ignore case on operations (-d and -s) dedup and sort.
-L[[+|-]?n-?m?]: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                 Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                 '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Line output
                 is suppressed if the entered value is greater than lines read on STDIN.
-m[c0:<-|\#[*]>]: Mask specified column with the mask defined after a ':', and where '-' 
                 means suppress, '#' means output character, any other character at that 
                 position will be inserted. If the mask is shorter than the target string, 
                 the last character of the mask will control the remainder of the output.
                 If the last character is neither '_' or '#', then it will be repeated for 
                 the number of characters left in the line. 
                 Characters '_', '#' and ',' are reserved and cannot be inserted within a mask.
                 Example data: 1481241, -m“c0:__#” produces '81241'. -m“c0:__#_”
                 produces '8' and suppress the rest of the field.
                 Example data: E201501051855331663R,  -m“c0:_####/##/## ##:##:##_”
                 produces '2015/01/05 18:55:33'.
                 Example: 'ls *.txt | pipe.pl -m“c0:/foo/bar/#”' produces '/foo/bar/README.txt'.
                 Use '\' to escape either '_', ',' or '#'. 
-n[c0,c1,...cn]: Normalize the selected columns, that is, make upper case and remove white space.
-N             : Normalize keys before comparison when using (-d and -s) dedup and sort.
                 Makes the keys upper case and remove white space before comparison.
                 Output is not normalized. For that see (-n).
                 See also (-I) for case insensitive comparisons.
-o[c0,c1,...cn]: Order the columns in a different order. Only the specified columns are output.
-p[c0:exp,... ]: Pad fields left or right with white spaces. 'c0:-10.,c1:14 ' pads 'c0' with a
                 maximum of 10 trailing '.' characters, and c1 with upto 14 leading spaces.
-P             : Output a trailing pipe before new line on output.
-r<percent>    : Output a random percentage of records, ie: -r100 output all lines in random
                 order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
-R             : Reverse sort (-d and -s).
-s[c0,c1,...cn]: Sort on the specified columns in the specified order.
-t[c0,c1,...cn]: Trim the specified columns of white space front and back.
-T[HTML|WIKI]  : Output as a Wiki table or an HTML table.
-u[c0,c1,...cn]: Encodes strings in specified columns into URL safe versions.
-U             : Sort numerically. Multiple fields may be selected, but an warning is issued
                 if any of the columns used as a key, combined, produce a non-numeric value
                 during the comparison.
-v[c0,c1,...cn]: Average over non-empty values in specified columns.
-w[c0,c1,...cn]: Report min and max number of characters in specified columns.
-W[delimiter]  : Break on specified delimiter instead of '|' pipes, ie: "\^", and " ".
-x             : This (help) message.
-z[c0,c1,...cn]: Suppress line if the specified column(s) are empty, or don't exist.
```