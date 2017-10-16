#!/usr/bin/perl -w
#####################################################################################
#
# Perl source file for project pipe.
#
# Pipe performs handy operations on pipe delimited files.
#    Copyright (C) 2015 - 2017  Andrew Nisbet
# The Edmonton Public Library respectfully acknowledges that we sit on
# Treaty 6 territory, traditional lands of First Nations and Metis people.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Created: Mon May 25 15:12:15 MDT 2015
#
# Rev:
# 0.42.5 - October 16, 2017 Allow reset of -2 switch.
#
####################################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;

### Globals
my $VERSION           = qq{0.42.5};
my $KEYWORD_ANY       = qw{any};
# Flag means that the entire file must be read for an operation like sort to work.
my $LINE_RANGES       = {};
my $MAX_LINE          = 100000000;
$LINE_RANGES->{'1'}   = $MAX_LINE;
my $READ_FULL         = 0; # Set true to read the entire file before output as with -L'-n'.
my $KEEP_LINES        = 10; # Number of lines to keep in buffer if -L'-n' is used.
my @LINE_BUFF         = (); # Buffer of last 'n' lines used with -L'-n'.
my $FAST_FORWARD      = 0;  # 0 means keep reading 1 means stop reading input.
my @ALL_LINES         = ();
# For every requested operation we need an array that can hold the columns
# for that operation; in that way we can have multiple operations on different
# columns working at the same time. We store different columns totals on a hash ref.
##### Scripting
my $DELIMITER         = '|';
my $SUB_DELIMITER     = "{_PIPE_}";
my @SCRIPT_COLUMNS    = (); my $script_ref    = {};
#####
my @INCR_COLUMNS      = ();                          # Columns to increment.
# Column and seed value to insert auto-increment columns into.
my $AUTO_INCR_COLUMN  = (); my $AUTO_INCR_SEED= {};  my $AUTO_INCR_RESET = {};
my $AUTO_INCR_ORIG_VALUE = 0; # Used if a reset value is selected.
my @HISTOGRAM_COLUMN  = (); my $hist_ref      = {};  # Column for histogram and character to use.
my @INCR3_COLUMNS     = (); my $increment_ref = {};  # Stores increment values for each of the target columns.
my @DELTA4_COLUMNS    = (); my $delta_cols_ref= {};  # Stores columns we want deltas for, and previous lines value used in difference.
my @COUNT_COLUMNS     = (); my $count_ref     = {};
my @SUM_COLUMNS       = (); my $sum_ref       = {};
my @WIDTH_COLUMNS     = (); my $width_min_ref = {}; my $width_max_ref = {}; my $width_line_min_ref = {}; my $width_line_max_ref = {};
my @AVG_COLUMNS       = (); my $avg_ref       = {}; my $avg_count = {};
my @DDUP_COLUMNS      = (); my $ddup_ref      = {};
my @CASE_COLUMNS      = (); my $case_ref      = {};
my @REPLACE_COLUMNS   = (); my $replace_ref   = {}; # Replacement columns and content. Handled like -f.
my @COND_CMP_COLUMNS  = (); my $cond_cmp_ref  = {}; # case switching expressions like uc,lc,mc.
my @TRIM_COLUMNS      = ();
my @ORDER_COLUMNS     = ();
my @NORMAL_COLUMNS    = ();
my @SORT_COLUMNS      = ();
my @TRANSLATE_COLUMNS = (); my $trans_ref     = {}; # Translation values.
my @MASK_COLUMNS      = (); my $mask_ref      = {}; # Stores the masks by column number.
my @SUBS_COLUMNS      = (); my $subs_ref      = {}; # Stores the sub string indexes by column number.
my @PAD_COLUMNS       = (); my $pad_ref       = {}; # Stores the pad instructions by column number.
my @FLIP_COLUMNS      = (); my $flip_ref      = {}; # Stores the flip instructions by column number.
my @FORMAT_COLUMNS    = (); my $format_ref    = {}; # Stores the format instructions by column number.
my @MATCH_COLUMNS     = (); my $match_ref     = {}; # Stores regular expressions.
my @NOT_MATCH_COLUMNS = (); my $not_match_ref = {}; # Stores regular expressions for -G.
my $IS_X_MATCH        = 0;                          # True if -X matched. Turns on -y or -Y.
my @MATCH_START_COLS  = (); my $match_start_ref= {};# Stores each columns IS_MATCHED flag, and turns on -Y.
my @MATCH_Y_COLUMNS   = (), my $match_y_ref   = {}; # Look ahead -Y test conditions supplied by user.
my @U_ENCODE_COLUMNS  = (); my $url_characters= {}; # Stores the character mappings.
my @MERGE_COLUMNS     = (); # List of columns to merge. The first is the anchor column.
my @EMPTY_COLUMNS     = (); # empty column number checks.
my @SHOW_EMPTY_COLUMNS= (); # Show empty column number checks.
my @COMPARE_COLUMNS   = (); # Compare all collected columns and report if equal.
my @NO_COMPARE_COLUMNS= (); # ! Compare all collected columns and report if equal.
my $LINE_NUMBER       = 0;
my $START_OUTPUT      = 0;
my $END_OUTPUT        = 0;
my $TAIL_OUTPUT       = 0; # Is this a request for the tail of the file.
my $TABLE_OUTPUT      = 0; my $TABLE_ATTR = ''; # Does the user want to output to a table.
my $WIDTHS_COLUMNS    = {};
my $X_UNTIL_Y         = 0;
my $LAST_LINE         = 0; # Used for -j to trim last delimiter.
my $SKIP_LINE         = 0; # Used for -L for alternate line output.
my $PREVIOUS_LINE     = "BOF"; # For '-Q' region search display.
my $IS_A_POST_MATCH   = 0;  # For '-Q' region search display.
my $FALSE             = 1;
my $TRUE              = 0;
my $ALLOW_SCRIPTING   = $TRUE;
my $JOIN_COUNT        = 0; # lines to continue to join if -H used.
my $PRECISION         = 2; # Default precision of computed floating point number output.
my $MATCH_LIMIT       = 1; my $MATCH_COUNT = 0; # Number of search matches output before exiting.

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

    usage: cat file | pipe.pl [-5ADijLQtUVx]
       -0<file_name>
       -Wh<delimiter>
       -14bBcovwzZ<c0,c1,...,cn>
       -3<c0:n,c1:m,...,cn:p>
       -nOtu<[any|c0,c1,...,cn]>
       -C<[any|cn]:(gt|lt|eq|ge|le)exp,...>
       -ds[-IRN]<c0,c1,...,cn> [-J[cn]]
       -e[c0:[uc|lc|mc|us],...>
       -E[c0:[r|?c.r[.e]],...>
       -f[c0:n.p[?p.q[.r]],...>
	   -7<n-th match>
       -F[c0:[x|b|d],...>
       -gG<any|cn:[regex],...>
       -H[-q<positive integer>]
       -k<cn:expr,(...)>
       -l<c0:n.p,...>
       -L<[[+|-]n[[,|-]n]?|skip n]>
       -m<cn:*[_|#]*,...>
       -p<cn:[+|-]countChar+,...>
       -q<n-th> [-Q]
       -S<cn:[range],...>
       -y<precision>
       -2<cn:[start],...>
       -6<cn:[char],...>
       -THTML[:attributes]|WIKI[:attributes]|MD[:attributes]|CSV[:col1,col2,...,coln]
       -X<any|cn:[regex],...> [-Y<any|cn:regex,...> [-M]]
Usage notes for pipe.pl. This application is a accumulation of helpful scripts that
performs common tasks on pipe-delimited files. The count function (-c), for
example counts the number of non-empty values in the specified columns. Other
functions work similarly. Stacked functions are operated on in alphabetical
order by flag letter, that is, if you elect to order columns and trim columns,
the columns are first ordered, then the columns are trimmed, because -o comes
before -t. The exceptions to this rule are those commands that require the
entire file to be read before operations can proceed (-d dedup, -r random, and
-s sort). Those operations will be done first then just before output the
remaining operations are performed.

Example: cat file.lst | pipe.pl -c"c0"

pipe.pl only takes input on STDIN. All output is to STDOUT. Errors go to STDERR.
All column references are 0 based.

 -0<file_name>  : Name of a text file to use as input as alternative to taking input on STDIN.
 -1<c0,c1,...cn>: Increment the value stored in given column(s). Works on both integers and
                  strings. Example: 1 -1c0 => 2, aaa -1c0 => aab, zzz -1c0 => aaaa.
                  You can optionally change the increment step by a given value.
                  '10' '-1c0:-1' => 9.
 -2<cn:start,[end]> : Adds a field to the data that auto increments starting at a given integer.
                  Example: a|b|c -2'c1:100' => a|100|b|c, a|101|b|c, a|102|b|c, etc. This 
                  function occurs last in the order of operations. The auto-increment value
                  will be appended to the end of the line if the specified column index is
                  greater than, or equal to, the number of columns a given line. A value
				  can be entered as a reset value to start incrementing again.
                  Example: -2c0:0,1 would output 0, 1, 0, 1, 0, ...
 -3<c0[:n],c1,...cn>: Increment the value stored in given column(s) by a given step.
                  Like '-1', but you can specify a given step value like '-2'.
                  '10' '-1c0:-2' => 8. An invalid increment value will fail silently unless 
                  '-D' is used.
 -4<c0,c1,...cn>: Compute difference between value in previous column. If the values in the
                  line above are numerical the previous line is subtracted from the current line.
                  If the '-R' switch is used the current line is subtracted from the previous line.
 -5             : Modifier used with -[g|X|Y]'any:<regex>', outputs all the values that match the regular
                  expression to STDERR.
 -6<cn:[char]>  : Displays histogram of columns' numeric value. '5' '-6c0:*' => '*****'.
                  If the column doesn't contain a whole number pipe.pl will issue an error and exit.
 -7<nth-match>  : Return after 'n'th line match of a search. See '-g', '-G', '-X', '-Y'.
 -a<c0,c1,...cn>: Sum the non-empty values in given column(s).
 -A             : Modifier that outputs the number of key matches from dedup.
                  The end result is output similar to 'sort | uniq -c' ie: ' 4 1|2|3'
                  for a line that was duplicated 4 times on a given key. If
                  -d is not selected, line numbers of successfully matched lines
                  are output. If the last 10 lines of a file are selected, the output
                  are numbered from 1 to 10 but if other match functions like -g -G -X or -Y
                  are used, the successful matched line is reported.
 -b<c0,c1,...cn>: Compare fields and output if each is equal to one-another.
 -B<c0,c1,...cn>: Compare fields and output if columns differ.
 -c<c0,c1,...cn>: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -C<any|c0:<gt|lt|eq|ge|le]value,... >: Compare column and output line if value in column
                  is greater than (gt), less than (lt), equal to (eq), greater than
                  or equal to (ge), or less than or equal to (le) the value that follows.
                  The following value can be numeric, but if it isn't the value's
                  comparison is made lexically. All specified columns must match to return
                  true, that is '-C' is logically AND across columns. This behaviour changes
                  if the keyword 'any' is used, in that case test returns true as soon  
                  as any column comparison matches successfully.
 -d<c0,c1,...cn>: Dedups file by creating a key from specified column values
                  which is then over written with lines that produce
                  the same key, thus keeping the most recent match. Respects (-r).
 -D             : Debug switch.
 -e<c0:[uc|lc|mc|us],...>: Change the case of a value in a column to upper case (uc),
                  lower case (lc), mixed case (mc), or underscore (us).
 -E<c0:[r|?c.r[.e]],...>: Replace an entire field conditionally, if desired. Similar
                  to the -f flag but replaces the entire field instead of a specific
                  character position. r=replacement string, c=conditional string, the
                  value the field must have to be replaced by r, and optionally
                  e=replacement if the condition failed.
                  Example: '111|222|333' '-E'c1:nnn' => '111|nnn|333'
                  '111|222|333' '-E'c1:?222.444'     => '111|444|333'
                  '111|222|333' '-E'c1:?aaa.444.bbb' => '111|bbb|333'
 -f<c0:n[.p|?p.q[.r]],...>: Flips an arbitrary but specific character conditionally,
                  where 'n' is the 0-based index of the target character. A '?' means
                  test the character equals p before changing it to q, and optionally change
                  to r if the test fails. Works like an if statement.
                  Example: '0000' -f'c0:2.2' => '0020', '0100' -f'c0:1.A?1' => '0A00',
                  '0001' -f'c0:3.B?0.c' => '000c', finally
                  echo '0000000' | pipe.pl -f'c0:3?1.This.That' => 000That000.
 -F<c0:[x|b|d],...>: Outputs the field in hexidecimal (x), binary (b), or decimal (d).
 -g<[any|c0:regex,...>: Searches the specified field for the Perl regular expression.
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
				  succeeds because the value in c1 matches the value in c3.
 -G<[any|c0:regex,...>: Inverse of '-g', and can be used together to perform AND operation as
                  return true if match on column 1, and column 2 not match. If the keyword
                  'any' is used, all columns must fail the match to return true. Empty regular
                  expressions are permitted. See '-g' for more information.
 -h             : Change delimiter from the default '|'. Changes -P and -K behaviour, see -P, -K.
 -H             : Suppress new line on output.
 -i             : Turns on virtual matching for -g, -G. Causes further processing on the line ONLY
                  if -g or -G succeed. Normally -g or -G will suppress output if a condition matches.
                  The -i flag will override that behaviour but suppress any additional processing of 
                  the line unless the -g or -G flag succeeds.
 -I             : Ignore case on operations -b, -B, -d, -E, -f, -g, -G, -n and -s.
 -j             : Removes the last delimiter from the last processed line. See -P, -K, -h.
 -J<cn>         : Sums the numeric values in a given column during the dedup process (-d)
                  providing a sum over group-like functionality. Does not work if -A is selected
                  (see -A).  
 -k<cn:expr,(...)>: Use perl scripting to manipulate a field. Syntax: -kcn:'(script)'
                  The existing value of the column is stored in an internal variable called '\$value'
                  and can be manipulated and output as per these examples.
                  "13|world"    => -kc0:'\$a=3; \$b=10; \$value = \$b + \$a;'
                  "hello|worle" => -kc1:'\$value++;'
                  Note use single quotes around your script.
                  If ALLOW_SCRIPTING is set to FALSE, pipe.pl will issue an error and exit.
 -K             : Use line breaks instead of the current delimiter between columns (default '|').
                  Turns all columns into rows.
 -l<c0:exp,... >: Translate a character sequence if present. Example: 'abcdefd' -l"c0:d.P".
                  produces 'abcPefP'.
 -L<[[+|-]?n-?m?|skip n]>: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Multiple 
                  requests can be comma separated like this -L'1,3,8,23-45,12,-100'.
                  The 'skip' keyword will output alternate lines. 'skip2' will output every other line.
                  'skip 3' every third line and so on. The skip keyword takes precedence over
                  over other line output selections in the '-L' flag.
 -m<c0:*[_|#]*> : Mask specified column with the mask defined after a ':', and where '_'
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
 -M             : Print the enclosing lines between successful '-X' and '-Y' matches. See '-X' and '-Y'.
 -n<any|c0,c1,...cn>: Normalize the selected columns, that is, removes all non-word characters
                  (non-alphanumeric and '_' characters). The '-I' switch leaves the value's case
                  unchanged. However the default is to change the case to upper case. See '-N',
                  '-I' switches for more information.
 -N             : Normalize keys before comparison when using (-d and -s) dedup and sort.
                  Normalization removes all non-word characters before comparison. Use the '-I'
                  switch to preserve keys' case during comparison. See '-n', and '-I'.
 -o<c0,c1,...cn>: Order the columns in a different order. Only the specified columns are output.
 -O<any|c0,c1,...cn>: Merge columns. The first column is the anchor column, any others are appended to it
                  ie: 'aaa|bbb|ccc' -Oc2,c0,c1 => 'aaa|bbb|cccaaabbb'. Use -o to remove extraneous columns.
                  Using the 'any' keyword causes all columns to be merged in the data in column 0.
 -p<c0:exp,... >: Pad fields left or right with white spaces. 'c0:-10.,c1:14 ' pads 'c0' with a
                  maximum of 10 trailing '.' characters, and c1 with upto 14 leading spaces.
 -P             : Ensures a tailing delimiter is output at the end of all lines.
                  The default delimiter of '|' can be changed with -h.
 -q<lines>      : Modifies '-H' behaviour to allow new lines for every n-th line of output.
                  This has the effect of joining n-number of lines into one line. 
 -Q             : Output the line before and line after a '-g', or '-G' match to STDERR. Used to 
                  view the context around a match, that is, the line before the match and the line after.
                  The lines are written to STDERR, and are immutable. The line preceding a match 
                  is denoted by '<=', the line after by '=>'. If the match occurs on the first line 
                  the preceding match is '<=BOF', beginning of file, and if the match occurs on 
                  the last line the trailing match is '=>EOF'. 
 -r<percent>    : Output a random percentage of records, ie: -r100 output all lines in random
                  order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
 -R             : Reverse sort (-d, -4 and -s).
 -s<c0,c1,...cn>: Sort on the specified columns in the specified order.
 -S<c0:range>   : Sub string function. Like mask, but controlled by 0-based index in the columns' strings.
                  Use '.' to separate discontinuous indexes, and '-' to specify ranges.
                  Ie: '12345' -S'c0:0.2.4' => '135', -S'c0:0-2.4' => '1235', and -S'c0:2-' => '345'.
                  Note that you can reverse a string by reversing your selection like so:
                  '12345' -S'c0:4-0' => '54321', but -S'c0:0-4' => '1234'. Removal of characters
                  from the end of data can be specified with syntax (n -m), where 'n' is a literal
                  and represents the length of the data, and '-m' represents the number of characters
                  to be trimmed from the end of the line, ie '12345' => -S'c0:0-(n -1)' = '1234'.
 -t<any|c0,c1,...cn>: Trim the specified columns of white space front and back.
 -T<HTML[:attributes]|WIKI[:attributes]|MD[:attributes]|CSV[:col1,col2,...,coln]>
                : Output as a Wiki table, Markdown, CSV or an HTML table, with attributes.
                  CSV:Name,Date,Address,Phone
                  HTML also allows for adding CSS or other HTML attributes to the <table> tag. 
                  A bootstrap example is '1|2|3' -T'HTML:class="table table-hover"'.
 -u<any|c0,c1,...cn>: Encodes strings in specified columns into URL safe versions.
 -U             : Sort numerically. Multiple fields may be selected, but an warning is issued
                  if any of the columns used as a key, combined, produce a non-numeric value
                  during the comparison. With -C, non-numeric value tests always fail, that is
                  '12345a' -C'c0:ge12345' => '12345a' but '12345a' -C'c0:ge12345' -U fails.
 -v<c0,c1,...cn>: Average over non-empty values in specified columns.
 -V             : Validate that the output has the same number of columns as the input.
 -w<c0,c1,...cn>: Report min and max number of characters in specified columns, and reports
                  the minimum and maximum number of columns by line.
 -W<delimiter>  : Break on specified delimiter instead of '|' pipes, ie: "\^", and " ".
 -x             : This (help) message.
 -X<any|c0:regex,...>: Like the '-g' flag, grep columns for values, and if matched, either
                  start outputting lines, or output '-Y' matches if selected. See '-Y'.
                  If the keyword 'any' is used the first column to match will return true.
                  Also allows comparisons across columns.
 -y<precision>  : Controls precision of computed floating point number output (example '-v').
 -Y<any|c0:regex,...>: Like the '-g', search for matches on columns after initial match(es)
                  of '-X' (required). See '-X'.
                  If the keyword 'any' is used the first column to match will return true.
                  The default behaviour is to output the X and Y matches only, but can be changed.
                  See '-M' for more details.
 -z<c0,c1,...cn>: Suppress line if the specified column(s) are empty, or don't exist.
 -Z<c0,c1,...cn>: Show line if the specified column(s) are empty, or don't exist.

The order of operations is as follows:
  -x - Usage message, then exits.
  -y - Specify precision of floating computed variables (see -v).
  -0 - Input from named file.
  -d - De-duplicate selected columns.
  -r - Randomize line output.
  -s - Sort columns.
  -v - Average numerical values in selected columns.
  -X - Grep values in specified columns, start output, or start searches for -Y values.
  -Y - Grep values in specified columns once greps with -X succeeds.
  -M - Output all data until -Y succeeds.
  -1 - Increment value in specified columns.
  -3 - Increment value in specified columns by a specific step.
  -4 - Output difference between this and previous line.
  -k - Run perl script on column data.
  -L - Output only specified lines, or range of lines.
  -A - Displays line numbers or summary of duplicates if '-d' is selected.
  -J - Displays sum over group if '-d' is selected.
  -u - Encode specified columns into URL-safe strings.
  -C - Conditionally test column values.
  -e - Change case of string in column.
  -E - Replace string in column conditionally.
  -f - Modify character in string based on 0-based index.
  -F - Format column value into bin, hex, or dec.
  -7 - Stop search after n-th match.
  -i - Output all lines, but process only if -g or -G match.
  -5 - Output all -g 'any' keyword matchs to STDERR.
  -G - Inverse grep specified columns.
  -g - Grep values in specified columns.
  -Q - Output the line before and line after a '-g', or '-G' match to STDERR.
  -m - Mask specified column values.
  -S - Sub string column values.
  -l - Translate character sequence.
  -n - Remove non-word characters in specified columns.
  -t - Trim selected columns.
  -I - Ingnore case on '-b', '-B', '-d', '-E', '-f', '-s', '-g', '-G', and '-n'.
  -R - Reverse line order when -d, -4 or -s is used.
  -b - Suppress line output if columns' values differ.
  -B - Only show lines where columns are different.
  -Z - Show line output if column(s) test empty.
  -z - Suppress line output if column(s) test empty.
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

Version: $VERSION
EOF
	exit;
}

# Takes a single argument from the command line in pipe.pl style input and returns a list of the column index and the value supplied.
# Looks like this: -2c1:1000, where '-2' is the flag, c1 is the column requested, and 1000 the additional input for the column. A reset value is also allowed as in -2c1:1000,1200, which resets the increment to 1000 after 1200 is reached.
# param:  string argument from the command line.
# return: List of 2 values, the column index and the requested value. In the example above the return values are (1, 1000).
sub parse_single_column_single_argument( $ )
{
	my $input = shift;
	if ( $input =~ m/^[C|c]\d{1,}/ )
	{
		my ( $colNum, $value ) = split ':', $input;
		my $reset = '';    # might not be used if user doesn't specify a reset value.
		$colNum =~ s/c//i; # get rid of the 'c' because it causes problems later.
		# There may be an additional value after the column specifier (or not).
		if ( $input =~ m/:/ )
		{
			$value = $';
			if ( $input =~ m/,/ )
			{
				( $value, $reset ) = split ',', $value;
				$value = trim( $value );
				$reset = trim( $reset );
			}
			printf STDERR "increment start='%s', end='%s'\n", $value, $reset if ( $opt{'D'} );
		}
		if ( ! $value )
		{
			$value = 0;
		}
		return ( $colNum, $value, $reset );
	}
	printf STDERR "** error parsing column specification in '%s'\n", $input;
	exit( 0 );
}

# Reads the values supplied on the command line and parses them out into the argument list,
# and populates the appropriate hash reference of column qualifiers hash-reference.
# param:  command line string of requested columns.
# param:  hash reference of column names and qualifiers.
# param:  is_allowed string that specifies a keyword like $KEYWORD_ANY.
# return: New array.
sub read_requested_qualified_columns( $$$ )
{
	my $line       = shift;
	my @list       = ();
	my $hash_ref   = shift;
	my $is_allowed = shift;
	# Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
	$line .= "," if ( $line !~ m/,/ );
	# To accommodate expressions that include a ',' as part of the mask split on non-escaped ','s
	# we use a negative look behind.
	my @cols = split( m/(?<!\\),/, $line );
	foreach my $colNum ( @cols )
	{
		# Columns are designated with 'c' prefix to get over the problem of perl not recognizing
		# '0' as a legitimate column number.
		if ( $colNum =~ m/[C|c]\d{1,}/ )
		{
			$colNum =~ s/[C|c]//; # get rid of the 'c' because it causes problems later.
			# We now allow other characters, and possibly ':' so split the line on the first one only.
			my @nameQualifier = ();
			if ( $colNum =~ m/:/ )
			{
				push @nameQualifier, $`;
				push @nameQualifier, $';
			}
			if ( scalar @nameQualifier != 2 )
			{
				print STDERR "*** Error missing qualifier '$colNum'. ***\n";
				usage();
			}
			push( @list, trim( $nameQualifier[0] ) );
			# Add the qualifier to the hash reference too for reference later.
			# The ',' char is a field delimiter and has to be escaped, but in regex it has a different meaning and has to be un-escaped.
			$nameQualifier[1] =~ s/\\,/,/g;
			$hash_ref->{$nameQualifier[0]} = trim( $nameQualifier[1] );
		}
		elsif ( $colNum =~ m/any/ and $is_allowed =~ m/($KEYWORD_ANY)/i )
		{
			my @nameQualifier = ();
			if ( $colNum =~ m/:/ )
			{
				push @nameQualifier, $`;
				push @nameQualifier, $';
			}
			if ( scalar @nameQualifier != 2 )
			{
				print STDERR "*** Error missing qualifier '$colNum'. ***\n";
				usage();
			}
			@list = ();
			push( @list, trim( $nameQualifier[0] ) );
			# Add the qualifier to the hash reference too for reference later.
			# The ',' char is a field delimiter and has to be escaped, but in regex it has a different meaning and has to be un-escaped.
			$nameQualifier[1] =~ s/\\,/,/g;
			$hash_ref->{$KEYWORD_ANY} = trim( $nameQualifier[1] );
			last;
		}
		else
		{
			print STDERR "** Warning: illegal column designation '$colNum', ignoring.\n";
		}
	}
	if ( scalar(@list) == 0 )
	{
		print STDERR "*** Error no valid columns selected. ***\n";
		usage();
	}
	print STDERR "columns requested: '@list'\n" if ( $opt{'D'} );
	return @list;
}

# Parses the ranges of lines requested by the user.
# parse the user's instructions and print out the lines selected.
# n = exactly the 'n'th line.
# n- = print from line 'n' on.
# +n = print the first 'n' lines.
# -n = print the last 'n' lines.
# n-m = exactly the range of lines from n to m.
# n,m-p = print n and range n-p (optional).
# param:  String that lists all of the ranges.
# return: <none>.
sub parse_line_ranges( $ )
{
	my $range_str = shift;
	if ( $range_str =~ m/^skip/ )
	{
		my $skip = $';
		if ( ! $skip or $skip !~ m/\d+/ )
		{
			printf STDERR "** error '-L' skip option takes an integer value greater than 0, supplied '%s'\n", $opt{'L'};
			exit;
		}
		$SKIP_LINE = $skip; # The integer value stored here will be used to modulus the line numbers in process_line().
		return;
	}
	$range_str    =~ s/\s+//g;
	my @r         = split ',', $range_str;
	my $ranges    = \@r;
	while ( @{ $ranges } )
	{
		my $range = shift @{ $ranges };
		# Clear the default of all lines, or else all lines will be considered.
		# Parse the ranges from the input strings.
		# Set the start (key) and end (value) to a specific value.
		if ( $range =~ m/^\-\d+$/ ) # parses from line 'n' to the end of the file. 
		{
			$READ_FULL = 1; # Set true to read the entire file before output as with -L'-n'.
			# get rid of the previous rule that outputs all lines.
			delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
			my $num = substr $range, 1;
			$LINE_RANGES->{ (0 -$num) } = $MAX_LINE;
			$KEEP_LINES  = $num; # Number of lines to keep in buffer if -L'-n' is used.
		}
		elsif ( $range =~ m/^\+\d+$/ ) # parses from beginning of file upto the given range. 
		{
			# The rule for line 1 is automatically over written.
			my $num = substr $range, 1;
			$LINE_RANGES->{ '1' } = $num;
		}
		elsif ( $range =~ m/^\d+\-\d+$/ ) # User has selected a range of lines from n-m.
		{
			# Remove the default rule for the entire range.
			delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
			my @v = split '-', $range;
			$LINE_RANGES->{ $v[ 0 ] } = $v[ 1 ];
		}
		elsif ( $range =~ m/^\d+\-$/ ) # Select all lines from 'n' on.
		{
			# Remove the default rule for the entire range.
			delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
			my $num = substr $range, 0, length( $range ) -1;
			$LINE_RANGES->{ $num } = $MAX_LINE;
		}
		elsif ( $range =~ m/^\d+$/ ) # Select a specific line number.
		{
			# Remove the default rule for the entire range.
			delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
			$LINE_RANGES->{ $range } = $range;
		}
		else
		{
			printf STDERR "** pipe syntax error in line number range definition: '%s'\n", $range_str;
			exit 1;
		}
	}
}

# Reads the values supplied on the command line and parses them out into the argument list.
# param:  command line string of requested columns.
# param:  command "any" if the caller is allowed to operate on any column without restriction.
# return: New array.
sub read_requested_columns( $$ )
{
	my $line       = shift;
	my $is_allowed = shift;
	my @list = ();
	# Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
	$line .= "," if ( $line !~ m/,/ );
	my @cols = split( ',', $line );
	foreach my $colNum ( @cols )
	{
		# Columns are designated with 'c' prefix to get over the problem of perl not recognizing
		# '0' as a legitimate column number.
		if ( $colNum =~ m/[C|c]\d{1,}/ )
		{
			$colNum =~ s/[C|c]//; # get rid of the 'c' because it causes problems later.
			push( @list, trim( $colNum ) );
		}
		elsif ( $colNum =~ m/^any$/ and $is_allowed =~ m/($KEYWORD_ANY)/i )
		{
			# Clear any other column selections the user may have already requested.
			@list = ();
			push( @list, $is_allowed );
			last; # don't allow user to add more.
		}
		else
		{
			print STDERR "** Warning: illegal column designation '$colNum', ignoring.\n";
		}
	}
	if ( scalar(@list) == 0 )
	{
		print STDERR "*** Error no valid columns selected. ***\n";
		usage();
	}
	print STDERR "columns requested: '@list'\n" if ( $opt{'D'} );
	return @list;
}

# Compression refers to removing white space and normalizing all
# alphabetic characters into upper case.
# param:  any string.
# return: input string with spaces removed and in upper case.
sub normalize( $ )
{
	my $line = shift;
	$line =~ s/\W+//g;
      if ( $opt{'I'} )
      {
            return $line;
      }
      else
      {
            return uc $line;
      }	
}

# Trim function to remove white space from the start and end of the string.
# param:  string to trim.
# return: string without leading or trailing spaces.
sub trim( $ )
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Prints the contents of the argument hash reference.
# param:  title of output.
# param:  hash reference of data.
# param:  List of columns requested by user.
# return: <none>
sub print_summary( $$$ )
{
	my $title    = shift;
	my $hash_ref = shift;
	my $columns  = shift;
	printf STDERR "== %9s\n", $title if ( $title );
	foreach my $column ( sort @{$columns} )
	{
		my $value = 0;
		$value = $hash_ref->{ 'c'.$column } if ( defined $hash_ref->{ 'c'.$column } );
		printf STDERR " %2s: %7s\n", 'c'.$column, get_number_format( $value, 0, $PRECISION );
	}
}

# Counts the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub count( $ )
{
	my $line = shift;
	foreach my $colIndex ( @COUNT_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] and @{ $line }[ $colIndex ] =~ m/\S/ )
		{
			$count_ref->{ "c$colIndex" }++;
		}
	}
}

# Sums the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub sum( $ )
{
	my $line = shift;
	foreach my $colIndex ( @SUM_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] and trim( @{ $line }[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
		{
			$sum_ref->{ "c$colIndex" } += trim( @{ $line }[ $colIndex ] );
		}
	}
}

# Computes the maximum and minimum width of all the data in the column.
# param:  line to pull out columns from.
# param:  line number.
# return: string line with requested columns removed.
sub width( $$ )
{
	my $line = shift;
	my $line_no = shift;
	foreach my $colIndex ( @WIDTH_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			my $length = length @{ $line }[ $colIndex ];
			printf STDERR "COL: '%s'::LEN '%d'\n", @{ $line }[ $colIndex ], $length if ( $opt{'D'} );
			if ( ! exists $width_min_ref->{ "c$colIndex" } or ! exists $width_max_ref->{ "c$colIndex" } )
			{
				$width_line_min_ref->{ "c$colIndex" } = $line_no;
				$width_line_max_ref->{ "c$colIndex" } = $line_no;
				$width_min_ref->{ "c$colIndex" } = $length;
				$width_max_ref->{ "c$colIndex" } = $length;
				next;
			}
			$width_line_min_ref->{ "c$colIndex" } = $line_no if ( $length < $width_min_ref->{ "c$colIndex" } );
			$width_line_max_ref->{ "c$colIndex" } = $line_no if ( $length > $width_max_ref->{ "c$colIndex" } );
			$width_min_ref->{ "c$colIndex" } = $length if ( $length < $width_min_ref->{ "c$colIndex" } );
			$width_max_ref->{ "c$colIndex" } = $length if ( $length > $width_max_ref->{ "c$colIndex" } );
		}
		else
		{
			if ( ! exists $width_min_ref->{ "c$colIndex" } or ! exists $width_max_ref->{ "c$colIndex" } )
			{
				$width_line_min_ref->{ "c$colIndex" } = 0;
				$width_line_max_ref->{ "c$colIndex" } = 0;
				$width_min_ref->{ "c$colIndex" } = 0;
				$width_max_ref->{ "c$colIndex" } = 0;
				next;
			}
			$width_line_min_ref->{ "c$colIndex" } = 0;
			$width_min_ref->{ "c$colIndex" } = 0;
		}
	}
	$WIDTHS_COLUMNS->{ @{ $line } } = $LINE_NUMBER;
}

# Average the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub average( $ )
{
	my $line = shift;
	foreach my $colIndex ( @AVG_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] and trim( @{ $line }[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
		{
			$avg_ref->{ "c$colIndex" } += trim( @{ $line }[ $colIndex ] );
			$avg_count->{ "c$colIndex" } = 0 if ( ! exists $avg_count->{ "c$colIndex" } );
			$avg_count->{ "c$colIndex" }++;
		}
	}
}

# Removes the white space from of specified columns.
# param:  line to pull out columns from.
# return: <none>.
sub trim_line( $ )
{
	my $line = shift;
	if ( $TRIM_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
	{
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			@{ $line }[ $colIndex ] = trim( @{ $line }[ $colIndex ] );
		}
		return;
	}
	foreach my $colIndex ( @TRIM_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] )
		{
			@{ $line }[ $colIndex ] = trim( @{ $line }[ $colIndex ] );
		}
	}
}

# Normalizes of specified columns, removing non-word characters.
# param:  line of columns of data.
# return: <none>.
sub normalize_line( $ )
{
	my $line = shift;
	if ( $NORMAL_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
	{
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			@{ $line }[ $colIndex ] = normalize( @{ $line }[ $colIndex ] );
		}
		return;
	}
	foreach my $colIndex ( @NORMAL_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] )
		{
			@{ $line }[ $colIndex ] = normalize( @{ $line }[ $colIndex ] );
		}
	}
}

# Places specified columns in a different order.
# param:  line to pull out columns from.
# return: <none>.
sub order_line( $ )
{
	my $line    = shift;
	my @newLine = ();
	foreach my $colIndex ( @ORDER_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			push @newLine, @{ $line }[ $colIndex ];
		}
	}
	@{ $line } = ();
	foreach my $v ( @newLine )
	{
		push @{ $line }, $v;
	}
}

# Returns the key composed of the selected fields.
# param:  string line of values from the input.
# param:  List of desired fields, or columns.
# return: string composed of each string selected as column pasted together without trailing spaces.
sub get_key( $$ )  # remove split
{
	my $line          = shift;
	my $wantedColumns = shift;
	my $key           = "";
	my @columns = split( '\|', $line );
	# If the line only has one column that is couldn't be split then return the entire line as
	# key. Duplicate lines will be removed only if they match entirely.
	if ( scalar( @columns ) < 2 )
	{
		return $line;
	}
	my @newLine = ();
	# Pull out the values from the line that will make up the key for storage in a hash table.
	for ( my $i = 0; $i < scalar( @{$wantedColumns} ); $i++ )
	{
		my $j = ${$wantedColumns}[ $i ];
		if ( defined $columns[ $j ] and exists $columns[ $j ] )
		{
			my $cols = $columns[ $j ];
			# Remove the sub delimiter if the user requested -W.
			$cols =~ s/($SUB_DELIMITER)/\|/g;
			$cols = lc( $cols ) if ( $opt{ 'I' } );
			# And new replace them since they may be used in another process.
			$cols =~ s/\|/$SUB_DELIMITER/g;
			push( @newLine, $cols );
		}
	}
	# it doesn't matter what we use as a delimiter as long as we are consistent.
	$key = join( '', @newLine );
	return $key;
}

# Test if argument is a number between 0-100.
# param:  number to test.
# return: 1 if the argument is a number between 0-100, and 0 otherwise.
sub is_between_zero_and_hundred( $ )
{
	my $testValue = shift;
	chomp $testValue;
	if ( $testValue =~ m/^\d{1,3}$/)
	{
		if ( 0 <= $testValue and $testValue <= 100 )
		{
			return 1;
		}
	}
	return 0;
}

# Sorts the ALL_LINES array using (O)1 space.
# param:  list of columns to sort on.
# return: <none> - reorders the ALL_LINES list.
sub sort_list( $ )
{
	my $all_list_ref  = {};
	my $wantedColumns = shift;
	my $count         = 1;
	while( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		chomp $line;
		my $key = get_key( $line, $wantedColumns );
		$key = normalize( $key ) if ( $opt{'N'} );
		# Make the value.00000001 to make each key unique. If value is a number, sort numeric works.
		# Where this breaks is if the values you want to sort are floats. In that case we should just
		# add more least significant digits.
		if ( trim( $key ) =~ m/^\d+\.\d+$/ )
		{
			$all_list_ref->{ $key . sprintf( "%.8d", $count ) } = $line;
		}
		else
		{
			$all_list_ref->{ $key . '.' . sprintf( "%.8d", $count ) } = $line;
		}
		$count++;
	}
	my @sortedKeysArray = ();
	my @tempKeys        = ( keys %$all_list_ref );
	# reverse sort?
	if ( $opt{'R'} )
	{
		if ( $opt{'U'} )
		{
			@sortedKeysArray = sort { $b <=> $a } @tempKeys;
		}
		else
		{
			@sortedKeysArray = sort { $b cmp $a } @tempKeys;
		}
	}
	else # Sort descending.
	{
		if ( $opt{'U'} )
		{
			@sortedKeysArray = sort { $a <=> $b } @tempKeys;
		}
		else
		{
			@sortedKeysArray = sort @tempKeys;
		}
	}
	# now remove the key from the start of the entry for each line in the array.
	while ( @sortedKeysArray )
	{
		my $key = shift @sortedKeysArray;
		print STDERR "\$key=$key\n" if ( $opt{'D'} );
		push @ALL_LINES, $all_list_ref->{ $key };
	}
}

# Outputs data from argument line as either HTML or WIKI.
# param:  String of line data - pipe-delimited.
# return: <none>.
sub prepare_table_data( $ )
{
	my $line = shift;
	my @newLine = ();
	if ( $TABLE_OUTPUT =~ m/HTML/i )
	{
		push @newLine, "  <tr><td>";
		foreach my $value ( @{ $line } )
		{
			push @newLine, $value;
			push @newLine, '</td><td>';
		}
		# remove the last '</td><td>'.
		pop @newLine;
		push @newLine, "</td></tr>";
	}
	elsif ( $TABLE_OUTPUT =~ m/WIKI/i )
	{
		push @newLine, "\n| ";
		foreach my $value ( @{ $line } )
		{
			push @newLine, $value;
			push @newLine, ' || ';
		}
		# remove the last ' || '.
		pop @newLine;
		push @newLine, "\n|-";
	}
	elsif ( $TABLE_OUTPUT =~ m/MD/i )
	{
		foreach my $value ( @{ $line } )
		{
			push @newLine, $value;
			push @newLine, ' | ';
		}
		# remove the last ' | '.
		pop @newLine;
		push @newLine, "\n";
	}
	elsif ( $TABLE_OUTPUT =~ m/CSV/i )
	{
		foreach my $value ( @{ $line } )
		{
			if ( $value =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
			{
				push @newLine, $value;
			}
			else
			{
				push @newLine, "\"".$value."\"";
			}
			push @newLine, ',';
		}
		# remove the last ','.
		pop @newLine;
		push @newLine, "\n";
	}
	@{ $line } = ();
	foreach my $v ( @newLine )
	{
		push @{ $line }, $v;
	}
}

# Applies the mask specified in argument 2 to string in argument 1.
# param:  String - target of masking operation.
# param:  String - mask specification.
# return: String modified by mask.
sub apply_mask( $$ )
{
	my @chars = split '', shift;
	my @mask  = split '', shift;
	my @word  = "";
	my $mask_char = '#'; # pre-load so if -m'c0:' will default output line.
	while ( @mask )
	{
		$mask_char = shift @mask if ( @mask );
		if ( $mask_char eq '\\' ) # Literal character '#' or '_'
		{
			push @word, shift @mask if ( @mask );
		}
		elsif ( $mask_char eq '_' )
		{
			shift @chars if ( @chars );
		}
		elsif ( $mask_char eq '#' )
		{
			push @word, shift @chars if ( @chars );
		}
		else
		{
			push @word, $mask_char;
		}
	}
	push @word, @chars if ( @chars and $mask_char eq '#' );
	return join '', @word;
}

# Outputs masked column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: <none>.
sub mask_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $mask_ref->{ $i } )
		{
			@{ $line }[ $i ] = apply_mask( @{ $line }[ $i ], $mask_ref->{ $i } );
		}
	}
}

# Outputs sub strings of column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: string with table formatting.
sub sub_string_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $subs_ref->{ $i } )
		{
			@{ $line }[ $i ] = sub_string( @{ $line }[ $i ], $subs_ref->{ $i } );
		}
	}
}

# Outputs sub strings of column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: string with table formatting.
sub sub_string( $ )
{
	my $input_string= shift;
	my @field       = split '', $input_string;
	my $instruction = shift;
	my @newField    = ();
	my @indexes     = ();
	printf STDERR "SUBSTR: '%s'.\n", $instruction if ( $opt{'D'} );
	# We will save all the indexes of characters we need. To do that we need to
	# convert '-' to ranges.
	my @subInstructions = split '\.', $instruction;
	while ( @subInstructions )
	{
		my $sub_instruction = shift @subInstructions;
		if ( $sub_instruction =~ m/^\s?\d+\s?$/ )
		{
			push @indexes, $&;
			next;
		}
		printf STDERR "got subinstruction string '%s' .\n", $sub_instruction if ( $opt{'D'} );
		my $last_n_chars_exp = '';
		if ( $sub_instruction =~ m/\(n\s?\-\s?\d{1,}\)$/i ) # does the expression end with '(n -int)'?
		{                                                                  # chop the -int number of characters.
			$last_n_chars_exp = $&;
			$sub_instruction  = $`;
			# Find how many characters to chop from the end of the line.
			$last_n_chars_exp =~ m/\d{1,}/;
			my $trailing_char_count = sprintf "%d", $&;
			$input_string = substr( $input_string, 0, (length($input_string) - $trailing_char_count ));
			printf STDERR "\$last_n_chars_exp='%s', \$input_string='%s'\n", $last_n_chars_exp, $input_string if ( $opt{'D'} );
		}
		if ( $sub_instruction =~ m/\-/ )
		{
			my $start = $`,
			my $end   = $';
			printf STDERR "got value '%s' and '%s'.\n", $start, $end if ( $opt{'D'} );
			# test end first, start depends on end in the case of a leading '-'.
			if ( $end =~ m/\d+/ )
			{
				$end = sprintf "%d", $&; # strips out just the number.
			}
			elsif ( $end eq '' ) # If the '-' was the trailing character. This will have precedence to select the rest of the string.
			{
				$end = length $input_string;
			}
			else
			{
				printf STDERR "*** error invalid end of range specification at '%s'.\n", $end;
				usage();
			}
			if ( $start =~ m/\d+/ )
			{
				$start = sprintf "%d", $&; # strips out just the number.
			}
			elsif ( $start eq '' ) # If the '-' was the leading character. This will indicate the last characters of the string.
			{
				$start = length( $input_string ) - $end;
				$end = $start + $end;
				# and if the user specified a value greater than the length of the string let's reset the start.
				$start = 0 if ( $start < 0 );
			}
			else
			{
				printf STDERR "*** error invalid start of range specification at '%s'.\n", $start;
				usage();
			}
			printf STDERR "computed start '%d'.\n", $start if ( $opt{'D'} );
			printf STDERR "computed end   '%d'.\n", $end if ( $opt{'D'} );
			# now pack the indices onto the array
			my $i = 0;
			if ( $start > $end )
			{
				for ( $i = $start; $i >= $end; $i-- ) # >= so we can specify the 0th element.
				{
					push @indexes, $i;
				}
			}
			else
			{
				for ( $i = $start; $i < $end; $i++ )
				{
					push @indexes, $i;
				}
			}
		}
		else # not expected format.
		{
			printf STDERR "*** error invalid range specification at '%s'.\n", $sub_instruction;
			usage();
		}
	}
	while ( @indexes )
	{
		my $index = shift @indexes;
		push @newField, $field[$index] if ( defined $field[$index] );
	}
	return join '', @newField;
}

# Greps specific columns for a given Perl pattern. See usage().
# param:  String of line data - pipe-delimited.
# param:  Hash reference of regular expressions.
# param:  List of columns to test.
# return: 1 if match found in column data and 0 otherwise.
sub is_match( $$$ )
{
	my $line           = shift;
	my $regex_hash_ref = shift;  # Can be -X or -Y reference of regular expressions.
	my $match_columns  = shift;
	my $matchCount     = 0;
	if ( @{ $match_columns }[0] =~ m/($KEYWORD_ANY)/i )
	{
		if ( $opt{'D'} )
		{
			if ( exists $regex_hash_ref->{ $KEYWORD_ANY } && $regex_hash_ref->{ $KEYWORD_ANY } )
			{
				printf STDERR "regex: '%s' \n", $regex_hash_ref->{ $KEYWORD_ANY };
			}
			else
			{
				printf STDERR "regex: '[unset]' \n";
			}
		}
		my $return_value = 0;
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			if ( $opt{'I'} ) # Ignore case on search
			{
				if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $KEYWORD_ANY })/i )
				{
					if ( $return_value > 0 and $opt{'5'} )
					{
						printf STDERR "%s%s", $DELIMITER, @{ $line }[ $colIndex ];
					}
					elsif ( $opt{'5'} )
					{
						printf STDERR "%s", @{ $line }[ $colIndex ];
					}
					$return_value = 1;
				}
			}
			else
			{
				if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $KEYWORD_ANY })/ )
				{
					if ( $return_value > 0 and $opt{'5'} ) # Add a pipe to the output if matched.
					{
						printf STDERR "%s%s", $DELIMITER, @{ $line }[ $colIndex ];
					}
					elsif ( $opt{'5'} )
					{
						printf STDERR "%s", @{ $line }[ $colIndex ];
					}
					$return_value = 1;
				}
			}
			# Quick exit if -g match and -5 not selected.
			# printf STDERR "%d", $return_value;
			last if ( $return_value and ! $opt{'5'} );
		}
		printf STDERR "\n" if ( $return_value > 0 and $opt{'5'} ); # print return because we found at least 1 match on this line.
		return $return_value;
	}
	foreach my $colIndex ( @{ $match_columns } )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			if ( $opt{'D'} )
			{
				if ( exists $regex_hash_ref->{ $colIndex } && $regex_hash_ref->{ $colIndex } )
				{
					printf STDERR "regex: '%s' \n", $regex_hash_ref->{ $colIndex };
				}
				else
				{
					printf STDERR "regex: '[unset]' \n";
				}
			}
			if ( $regex_hash_ref->{ $colIndex } )
			{
				if ( $opt{'I'} ) # Ignore case on search
				{
					$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $colIndex })/i );
				}
				else
				{
					$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $colIndex })/ );
				}
			}
			else ### If the regex is empty imply the first specified column regex should be tested on
			     ### this column's data.
			{
				if ( $regex_hash_ref->{ @{ $match_columns }[0] } )
				{
					if ( $opt{'I'} ) # Ignore case on search
					{
						$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ @{ $match_columns }[0] })/i );
					}
					else
					{
						$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ @{ $match_columns }[0] })/ );
					}
				}
				else ### If the first regex is empty then compare the defined columns value to the other columns.
				{
					if ( $opt{'I'} ) # Ignore case on search
					{
						$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/i );
					}
					else
					{
						$matchCount++ if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/ );
					}
				}
			}
		}
	}
	# This ensures an AND type operation, that all the requested columns matched. Remove test for count if you want OR.
	return 1 if ( $matchCount == scalar @{ $match_columns } and $matchCount > 0 ); # Count of matches should match count of column match requests.
	return 0;
}

# Inverse grep specific columns for a given Perl pattern. See usage().
# param:  String of line data - pipe-delimited.
# return: line if the pattern matched and nothing if it didn't.
sub is_not_match( $ )
{
	my $line = shift;
	if ( $NOT_MATCH_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
	{
		if ( $opt{'D'} )
		{
			if ( exists $not_match_ref->{ $KEYWORD_ANY } && $not_match_ref->{ $KEYWORD_ANY } )
			{
				printf STDERR "regex: '%s' \n", $not_match_ref->{ $KEYWORD_ANY };
			}
			else
			{
				printf STDERR "regex: '[unset]' \n";
			}
		}
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			if ( $opt{'I'} ) # Ignore case on search
			{
				return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $KEYWORD_ANY })/i );
			}
			else
			{
				return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $KEYWORD_ANY })/ );
			}
		}
		return 1;
	}
	foreach my $colIndex ( @NOT_MATCH_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			if ( $opt{'D'} )
			{
				if ( exists $not_match_ref->{ $colIndex } && $not_match_ref->{ $colIndex } )
				{
					printf STDERR "regex: '%s' \n", $not_match_ref->{ $colIndex };
				}
				else
				{
					printf STDERR "regex: '[unset]' \n";
				}
			}
			if ( $not_match_ref->{ $colIndex } )
			{
				if ( $opt{'I'} ) # Ignore case on search
				{
					return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $colIndex })/i );
				}
				else
				{
					return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $colIndex })/ );
				}
			}
			else ### If the regex is empty imply the first specified column regex should be tested on
			     ### this column's data.
			{
				if ( $not_match_ref->{ $NOT_MATCH_COLUMNS[0] } )
				{
					if ( $opt{'I'} ) # Ignore case on search
					{
						return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $NOT_MATCH_COLUMNS[0] })/i );
					}
					else
					{
						return 0 if ( @{ $line }[ $colIndex ] =~ m/($not_match_ref->{ $NOT_MATCH_COLUMNS[0] })/ );
					}
				}
				elsif ( $colIndex > 0 ) ### If the first regex is empty then compare the defined columns value to the other columns. But don't compare the first column with the first column because that always succeeds!
				{
					if ( $opt{'I'} ) # Ignore case on search
					{
						return 0 if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/i );
					}
					else
					{
						printf STDERR "-G '%s' CMP '%s'\n", @{ $line }[ $colIndex ], @{$line}[0]  if ( $opt{'D'} );
						return 0 if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/ );
					}
				}
			}
		}
	}
	return 1;
}

# Tests if a line is empty of content. Empty includes column doesn't exist and or is empty.
# param:  string (line) to test.
# return: 1 if there is a non-empty field, and 0 otherwise.
sub is_empty( $ )
{
	my $line = shift;
	printf STDERR "EMPTY_LINE: " if ( $opt{'D'} );
	foreach my $colIndex ( @EMPTY_COLUMNS )
	{
		return 1 if ( ! defined @{ $line }[ $colIndex ] );
		printf STDERR "'%s', ", @{ $line }[ $colIndex ] if ( $opt{'D'} );
		return 1 if ( trim( @{ $line }[ $colIndex ] ) =~ m/^$/ );
	}
	printf STDERR "\n" if ( $opt{'D'} );
	return 0;
}

# Tests if a line is empty of content. Empty includes column doesn't exist and or is empty.
# param:  string (line) to test.
# return: 1 if there is a empty field, and 0 otherwise.
sub is_not_empty( $ )
{
	my $line = shift;
	printf STDERR "SHOW_EMPTY_LINE: " if ( $opt{'D'} );
	foreach my $colIndex ( @SHOW_EMPTY_COLUMNS )
	{
		return 0 if ( ! defined @{ $line }[ $colIndex ] );
		printf STDERR "'%s', ", @{ $line }[ $colIndex ] if ( $opt{'D'} );
		return 0 if ( trim( @{ $line }[ $colIndex ] ) =~ m/^$/ );
	}
	printf STDERR "\n" if ( $opt{'D'} );
	return 1;
}

# Compares requested fields and returns line if they match.
# param:  string, pipe delimited line.
# param:  list of column indexes to compare on.
# return: 1 if the fields matched and 0 otherwise.
sub contain_same_value( $$ )
{
	my $line = shift;
	my $wantedColumns = shift;
	printf STDERR "CMP_LINE: " if ( $opt{'D'} );
	my $lastValue = '';
	my $matchCount = 0;
	foreach my $colIndex ( @{$wantedColumns} )
	{
		if ( ! $lastValue )
		{
			$lastValue = @{ $line }[ $colIndex ] if ( defined @{ $line }[ $colIndex ] && @{ $line }[ $colIndex ] );
			next;
		}
		printf STDERR "IS_MATCHED: '%s' cmp '%s' \n", $lastValue, @{ $line }[ $colIndex ] if ( $opt{'D'} );
		if ( $opt{'I'} )
		{
			return 0 if ( @{ $line }[ $colIndex ] !~ /^($lastValue)$/i );
		}
		else
		{
			return 0 if ( @{ $line }[ $colIndex ] !~ /^($lastValue)$/ );
		}
	}
	printf STDERR "IS_MATCHED: '%d'\n", $matchCount if ( $opt{'D'} );
	return 1;
}

# Applies padding to a given field.
# param:  string field to pad.
# param:  padding instructions.
# return: padded field.
sub apply_padding( $$ )
{
	my $field       = shift;
	my $instruction = shift;
	my @newField    = '';
	printf "PAD: '%s'.\n", $instruction if ( $opt{'D'} );
	my $count = 0;
	my $character = '';
	if ( $instruction =~ m/^[+|-]?\d{1,}/ )
	{
		$count = $&;
		$character = $';
		$character = ' ' if ( ! $character );
		printf STDERR "padding '$count' char '$character'\n" if ( $opt{'D'} );
	}
	else
	{
		print STDERR "*** syntax error in padding instruction.\n";
		usage();
	}
	return $field if ( abs($count) <= length $field );
	my @chars = split '', $field;
	if ( $count < 0 ) # Goes on end
	{
		$count = abs( $count );
		for ( my $i = 0; $i < $count; $i++ )
		{
			while ( @chars )
			{
				push @newField, shift @chars;
				$i++;
			}
			push @newField, $character;
		}
	}
	else # goes on front
	{
		@chars = reverse @chars;
		for ( my $i = 0; $i < $count; $i++ )
		{
			while ( @chars )
			{
				push @newField, shift @chars;
				$i++;
			}
			push @newField, $character;
		}
		@newField = reverse @newField;
	}
	return join '', @newField;
}

# Outputs padded column data as per specification. See usage().
# Syntax: n.c, where n is an integer (either + for leading, or - for trailing), '.' and character(s) to
# be used as padding.
# param:  String of line data - pipe-delimited.
# return: string with padded formatting.
sub pad_line( $ ) # remove split
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		# my $field = shift @line;
		if ( exists $pad_ref->{ $i } )
		{
			@{ $line }[ $i ] = apply_padding( @{ $line }[ $i ], $pad_ref->{ $i } );
		}
	}
}

# Tests and returns failure or success depending on expression value.
# param:  comparison operator (lt|gt|lt|eq|ge|le).
# param:  the value of comparison, what the data will be measured against.
# parma:  data from a column.
# return: 1 on success and 0 otherwise.
sub test_condition_cmp( $$$ )
{
	my $cmpOperator = shift;
	my $cmpValue    = shift;
	my $value       = shift;
	my $result      = 0;
	if ( $value =~ m/^[+|-]?\d{1,}\.?\d{1,}?$/ && $cmpValue =~ m/^[+|-]?\d{1,}\.?\d{1,}?$/ )
	{
		if ( $cmpOperator eq 'eq' )
		{
			$result = 1 if ( $value == $cmpValue );
		}
		elsif ( $cmpOperator eq 'lt' )
		{
			$result = 1 if ( $value < $cmpValue );
		}
		elsif ( $cmpOperator eq 'gt' )
		{
			$result = 1 if ( $value > $cmpValue );
		}
		elsif ( $cmpOperator eq 'le' )
		{
			$result = 1 if ( $value <= $cmpValue );
		}
		elsif ( $cmpOperator eq 'ge' )
		{
			$result = 1 if ( $value >= $cmpValue );
		}
	}
	else
	{
		if ( $opt{'U'} ) # request comparison on numbers 'U' only so ignore this one.
		{
			printf STDERR "* comparison fails on non-numeric value: '%s' and '%s' \n", $value, $cmpValue if ( $opt{'D'} );
			return 0;
		}
		if ( $cmpOperator eq 'eq' )
		{
			$result = 1 if ( $value eq $cmpValue );
		}
		elsif ( $cmpOperator eq 'lt' )
		{
			$result = 1 if ( $value lt $cmpValue );
		}
		elsif ( $cmpOperator eq 'gt' )
		{
			$result = 1 if ( $value gt $cmpValue );
		}
		elsif ( $cmpOperator eq 'le' )
		{
			$result = 1 if ( $value le $cmpValue );
		}
		elsif ( $cmpOperator eq 'ge' )
		{
			$result = 1 if ( $value ge $cmpValue );
		}
	}
	return $result;
}

# Tests the values in a given field using lt, gt, eq, le, ge.
# param:  String of line data - pipe-delimited.
# return: line if the specified condition was met and nothing if it didn't.
sub test_condition( $ )
{
	my $line = shift;
	my $result = 0;
	if ( $COND_CMP_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
	{
		printf STDERR "regex: '%s' \n", $cond_cmp_ref->{$KEYWORD_ANY} if ( $opt{'D'} );
		my $exp = lc $cond_cmp_ref->{$KEYWORD_ANY};
		# The first 2 characters determine the type of comparison.
		$exp =~ m/^(lt|gt|lt|eq|ge|le)/;
		if ( ! $& )
		{
			printf STDERR "*** error invalid comparison '%s'\n", $cond_cmp_ref->{$KEYWORD_ANY};
			usage();
		}
		my $cmpValue    = $';
		my $cmpOperator = $&;
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			return 1 if( test_condition_cmp( $cmpOperator, $cmpValue, @{ $line }[ $colIndex ] ) );
		}
		return $result;
	}
	foreach my $colIndex ( @COND_CMP_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] and exists $cond_cmp_ref->{ $colIndex } )
		{
			printf STDERR "regex: '%s' \n", $cond_cmp_ref->{$colIndex} if ( $opt{'D'} );
			my $exp = lc $cond_cmp_ref->{$colIndex};
			# The first 2 characters determine the type of comparison.
			$exp =~ m/^(lt|gt|lt|eq|ge|le)/;
			if ( ! $& )
			{
				printf STDERR "*** error invalid comparison '%s'\n", $cond_cmp_ref->{$colIndex};
				usage();
			}
			my $cmpValue    = $';
			my $cmpOperator = $&;
			$result += test_condition_cmp( $cmpOperator, $cmpValue, @{ $line }[ $colIndex ] );
		}
	}
	# All requested tests succeeded if the result count matches the number of test requests.
	return 1 if ( scalar( @COND_CMP_COLUMNS ) == $result );
	return 0;
}

# Switches casing based on values supplied.
# param:  String field to be modified.
# param:  casing string expression. Must be one of [mc|lc|uc].
# return: New string with changes if any.
sub apply_casing( $$ )
{
	my $field       = shift;
	my $instruction = shift;
	if ( $instruction eq "uc" )
	{
		$field = uc $field;
	}
	if ( $instruction eq "lc" )
	{
		$field = lc $field;
	}
	if ( $instruction eq "mc" )
	{
		$field =~ s/([\w']+)/\u\L$1/g;
	}
	if ( $instruction eq "us" )
	{
		$field =~ s/\s/_/g;
	}
	return $field;
}

# Modifies the case of a string.
# param:  line from file.
# return: <none>.
sub modify_case_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $case_ref->{ $i } )
		{
			printf STDERR "case specifier: '%s' \n", $case_ref->{ $i } if ( $opt{'D'} );
			my $exp = $case_ref->{ $i };
			# The first 2 characters determine the type of casing.
			$exp =~ m/^[uUlLmM][cCsS]/;
			if ( ! $& )
			{
				printf STDERR "*** error case specifier. Expected [uc|lc|mc|us] (ignoring case) but got '%s'.\n", $case_ref->{ $i };
				usage();
			}
			$exp = lc $exp;
			@{ $line }[ $i ] = apply_casing( @{ $line }[ $i ], $exp );
		}
	}
}

# Flips Flips an arbitrary but specific character Conditionally,
# where 'n' is the 0-based index of the target character. A '?' means
# test the character equals p before changing it to q, and optionally change
# to r if the test fails. Works like an if statement.
# Example: '0000' -f'c0:2' => '0020', '0100' -f'c0:1.A?1' => '0A00',
# '0001' -f'c0:3.B?0.c' => '000c'.
# param:  line from file.
# return: <none>.
sub flip_char_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $flip_ref->{ $i } )
		{
			printf STDERR "flip expression: '%s' \n", $flip_ref->{ $i } if ( $opt{'D'} );
			my $exp = $flip_ref->{ $i };
			my $target;
			my $replacement;
			my $condition;
			my $on_else;
			if ( $exp =~ m/\?/ )
			{
				$target = $`;
				( $condition, $replacement, $on_else ) = split( m/(?<!\\)\./, $' );
				$condition   =~ s/\\//g; # Strip off the '\' if the delimiter '.' is selected as a condition, replace or else character.
				$replacement =~ s/\\//g;
				$on_else     =~ s/\\//g if ( defined $on_else );
			}
			else # simple case of n.p
			{
				( $target, $replacement ) = split '\.', $exp;
			}
			if ( ! defined $target or ! defined $replacement )
			{
				printf STDERR "*** syntax error in -f, expected 'index.replacement' but got '%s'\n", $exp;
				usage();
			}
			if ( $opt{'D'} )
			{
				if ( defined $target )
				{
					printf STDERR " index='%s'", $target;
					if ( defined $condition )
					{
						printf STDERR " c='%s'", $condition;
						if ( defined $replacement )
						{
							printf STDERR " r='%s'", $replacement;
							printf STDERR " else='%s'", $on_else if ( defined $on_else );
						}
					}
					elsif ( defined $replacement ) # just an index and a replacement character.
					{
						printf STDERR " r='%s'", $replacement;
					}
				}
				printf STDERR "\n";
			}
			@{ $line }[ $i ] = apply_flip( @{ $line }[ $i ], $target, $replacement, $condition, $on_else );
		}
	}
}

# Flips the specified character to the provided alternate character.
# param:  String containing the site of the target character.
# param:  target integer of index into the string of the replacement site.
# param:  replacement character.
# param:  character condition to be met before replacing.
# param:  character replacement if condition not met.
# return: String with the specified modifications.
sub apply_flip
{
	my ( $field, $location, $replacement, $condition, $on_else ) = @_;
	# field, location and replacement must be defined, condition and on_else may not be.
	if ( $location !~ m/^\d{1,}$/ )
	{
		printf STDERR "*** syntax error in -f, expected integer index but got '%s'\n", $location;
		usage();
	}
	my @f = split //, $field;
	return $field if ( $location >= @f ); # if the location site is past the end of the field just return it untouched.
	my $site = $f[ $location ];
	if ( defined $condition )
	{
		if ( $opt{'I'} )
		{
			$condition = lc $condition;
			$site = lc $site;
		}
		if ( $condition eq $site )
		{
			$f[ $location ] = $replacement;
		}
		elsif ( defined $on_else )
		{
			$f[ $location ] = $on_else;
		}
	}
	else # Unconditionally change the site's character.
	{
		$f[ $location ] = $replacement;
	}
	printf STDERR "* '%s', '%s', '%s'\n", $location, $f[ $location ], $replacement if ( $opt{'D'} );
	return join '', @f;
}

# Replaces one string for another.
# param:  line from file.
# return: <none>.
sub replace_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $replace_ref->{ $i } )
		{
			printf STDERR "replace expression: '%s' \n", $replace_ref->{ $i } if ( $opt{'D'} );
			my $exp = $replace_ref->{ $i };
			my $replacement;
			my $condition;
			my $on_else;
			if ( $exp =~ m/\?/ )
			{
				( $condition, $replacement, $on_else ) = split( m/(?<!\\)\./, $' );
				$condition	 =~ s/\\//g; # Strip off the '\' if the delimiter '.' is selected as a condition, replace or else character.
				$replacement =~ s/\\//g;
				$on_else     =~ s/\\//g if ( defined $on_else );
			}
			else # simple case of 'n.p'
			{
				$replacement = $exp;
			}
			if ( ! defined $replacement )
			{
				printf STDERR "*** syntax error in -E, expected replacement string but got '%s'\n", $exp;
				usage();
			}
			if ( $opt{'D'} )
			{
				if ( defined $condition )
				{
					printf STDERR " condition='%s'", $condition;
					if ( defined $replacement )
					{
						printf STDERR " replacement='%s'", $replacement;
						printf STDERR " else='%s'", $on_else if ( defined $on_else );
					}
				}
				elsif ( defined $replacement ) # just an index and a replacement character.
				{
					printf STDERR " replacement='%s'", $replacement;
				}
				printf STDERR "\n";
			}
			@{ $line }[ $i ] = replace( @{ $line }[ $i ], $replacement, $condition, $on_else );
		}
	}
}

# Applies a translation to specified column(s).
# param:  line of pipe delimited columns.
# return: <none>.
sub translate_line( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( exists $trans_ref->{ $i } )
		{
			printf STDERR "translate expression: '%s' \n", $trans_ref->{ $i } if ( $opt{'D'} );
			my $exp = $trans_ref->{ $i };
			my ( $token, $replacement ) = split( m/(?<!\\)\./, $exp );
			# The $replacement string should be stripped of escaping characters.
			$replacement =~ s/\\//g;
			@{ $line }[ $i ] =~ s/($token)/$replacement/g;
		}
	}
}

# This function fixes lines that have trailing empty pipe columns. If it is not used
# lines are truncated after the last content-filled column.
# param:  original line sent to the calling function.
# param:  line after any modification.
# param:  line number for reporting.
# return: modified line with additional pipes if required.
sub validate( $$$ )
{
	my ( $original, $modified, $line_no ) = @_;
	my $count       = ( $original =~ tr/\|// );
	my $final_count = ( $modified =~ tr/\|// );
	printf STDERR "original: %d, modified: %d fields at line number %s.\n", $count, $final_count, $line_no if ( $opt{'D'} );
	# if ( $opt{'V'} ) # Original
	if ( $opt{'o'} ) # If you select -o this doesn't get done or extra fields are added even if you select 'V'
	{
		# But pad to the width of the columns selected -1, because pipe doesn't add a terminal pipe by default.
		$count = scalar @ORDER_COLUMNS -1 if ( $count > scalar @ORDER_COLUMNS -1 );
	}
	if ( $final_count < $count )
	{
		my $iterations = $count - $final_count;
		my $i = 0;
		for ( $i = 0; $i < $iterations; $i++ )
		{
			$modified .= '|';
		}
	}
	return $modified;
}

# Replaces a string conditionally.
# param:  target string of the replacement.
# param:  String to replace the target.
# param:  condition to test target string.
# param:  replacement string on failure of conditional testing.
# return: resultant string.
sub replace( $$$$ )
{
	my ( $field, $replacement, $condition, $on_else ) = @_;
	if ( defined $condition )
	{
		if ( $condition eq $field or ( $opt{'I'} and lc( $condition ) eq lc( $field ) ) )
		{
			printf STDERR "* '%s'\n", $replacement if ( $opt{'D'} );
			return $replacement;
		}
		elsif ( defined $on_else )
		{
			printf STDERR "* '%s'\n", $on_else if ( $opt{'D'} );
			return $on_else;
		}
		else
		{
			printf STDERR "* '%s'\n", $field if ( $opt{'D'} );
			return $field;
		}
	}
	# Unconditionally change the site's character.
	printf STDERR "* '%s'\n", $replacement if ( $opt{'D'} );
	return $replacement;
}

# Applies format to requested string.
# param:  String for conversion.
# param:  Conversion type 'b', 'h', 'd'.
# return: String with the specified modifications.
sub convert_format( $$ )
{
	my ( $field, $format ) = @_;
	if ( $field =~ m/^\d+$/ )
	{
		if ( $format eq 'b' )
		{
			return sprintf( "%0.8b ", $field );
		}
		elsif ( $format eq 'h' )
		{
			return sprintf( "%0.2x ", $field );
		}
		elsif ( $format eq 'd' )
		{
			return sprintf( "%d ", $field );
		}
		else
		{
			printf STDERR "** error unsupported option: '%s' \n", $format;
			usage();
		}
	}
	my @characters = ();
	my @newString  = ();
	@characters = split //, $field;
	while ( @characters )
	{
		my $c = shift @characters;
		if ( $format eq 'b' )
		{
			push @newString, sprintf( "%0.8b ", ord( $c ) );
		}
		elsif ( $format eq 'h' )
		{
			push @newString, sprintf( "%0.2x ", ord( $c ) );
		}
		elsif ( $format eq 'd' )
		{
			push @newString, sprintf( "%d ", ord( $c ) );
		}
		else
		{
			printf STDERR "** error unsupported option: '%s' \n", $format;
			usage();
		}
	}
	chomp @newString;
	return join '', @newString;
}

# Formats the specified column to the desired base type.
# param:  Original line input.
# return: <none>.
sub format_radix( $ )
{
	my $line = shift;
	my $i    = 0;
	for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
	{
		if ( defined $FORMAT_COLUMNS[ $i ] and exists $format_ref->{ $i } )
		{
			printf STDERR "format expression: '%s' \n", $flip_ref->{$i} if ( $opt{'D'} );
			@{ $line }[ $i ] = convert_format( @{ $line }[ $i ], lc ( $format_ref->{ $i } ) );
		}
	}
}

# Executes script listed in '-k'.
# param:  line input.
# return: <none>.
# throws: exits on syntax error.
sub execute_script_line( $ )
{
	if ( $ALLOW_SCRIPTING == $FALSE )
	{
		printf STDERR "* warning scripting not allowed, ask an administrator for assistance.\n";
		exit( 99 );
	}
	my $line = shift;
	foreach my $colIndex ( @SCRIPT_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			if ( $script_ref->{ $colIndex } !~ m/(rm|unlink|erase|del)/i )
			{
				my $value = @{ $line }[ $colIndex ]; # Reference name for the executing script.
				printf STDERR "\$value = '%s', script: '%s'\n", $value, $script_ref->{ $colIndex } if ( $opt{'D'} );
				eval $script_ref->{ $colIndex };
				if ( $@ )
				{
					print "Warning: error during evaluation, no changes made. $@";
				}
				else
				{
					@{ $line }[ $colIndex ] = $value;
					printf STDERR "\@{ \$line }[ \$colIndex ] = '%s'\n", @{ $line }[ $colIndex ] if ( $opt{'D'} );
				}
			}
			else
			{
				printf STDERR "* warning refusing to execute: '%s'\n", $script_ref->{ $colIndex };
			}
		}
	}
}

# Increments values in column data.
# param:  Array reference of line's columns.
# return: string with table formatting.
sub inc_line( $ )
{
	my $line = shift;
	foreach my $colIndex ( @INCR_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			@{ $line }[ $colIndex ]++;
		}
	}
}

# Increments values in column data by a given step.
# param:  Array reference of line's columns.
# return: <none>
sub inc_line_by_value( $ )
{
	my $line    = shift;
	foreach my $colIndex ( @INCR3_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			if ( $increment_ref->{ $colIndex } =~ m/^(\-)?\d+(\.\d+)?$/ )
			{
				@{ $line }[ $colIndex ] += $increment_ref->{ $colIndex };
			}
			else
			{
				printf STDERR "* warning invalid increment value: '%s'\n", $increment_ref->{ $colIndex } if ( $opt{'D'} );
			}
		}
	}
}

# Computes the difference between this line and the previous and outputs that difference.
# param:  Array reference of line's columns.
# return: <none>
sub delta_previous_line( $ )
{
	# my @DELTA4_COLUMNS    = (); my $delta_cols_ref= {};
	my $line    = shift;
	foreach my $colIndex ( @DELTA4_COLUMNS )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			# Guard against values that can't be subtracted.
			if ( @{ $line }[ $colIndex ] !~ m/^(\-)?\d+(\.\d+)?$/ )
			{
				printf STDERR "* warning can't use '%s' for computation.\n", @{ $line }[ $colIndex ] if ( $opt{'D'} );
				next;
			}
			# Save the first value 
			if ( ! exists $delta_cols_ref->{ $colIndex } )
			{
				$delta_cols_ref->{ $colIndex } = @{ $line }[ $colIndex ];
				next;
			}
			# But if the '-R' reverse switch is used subtract this value from the previous line.
			if ( $opt{'R'} )
			{
				# Save this rows orginial value in this row for the next row's calculation.
				my $tmp = @{ $line }[ $colIndex ];
				# Compute the new value for this row.
				@{ $line }[ $colIndex ] = $delta_cols_ref->{ $colIndex } - @{ $line }[ $colIndex ];
				$delta_cols_ref->{ $colIndex } = $tmp;
			}
			else
			{
				# Save this rows orginial value in this row for the next row's calculation.
				my $tmp = @{ $line }[ $colIndex ];
				# Compute the new value for this row.
				@{ $line }[ $colIndex ] = @{ $line }[ $colIndex ] - $delta_cols_ref->{ $colIndex };
				$delta_cols_ref->{ $colIndex } = $tmp;
			} 
		}
	}
}

# Adds an auto-incremented field to the output line in the column position specified.
# param:  Array reference of line's columns.
# return: string with table formatting.
sub add_auto_increment( $ )
{
	my $line = shift;
	my $size = scalar( @{ $line } );
	if ( $AUTO_INCR_COLUMN >= $size )
	{
		push @{ $line }, $AUTO_INCR_SEED++;
	}
	else
	{
		splice @{ $line }, $AUTO_INCR_COLUMN, 0, $AUTO_INCR_SEED++;
	}
	# The start and end range are inclusive, so we have to increment the AUTO_INCR_RESET by 1 with the post increment
	# code above.
	if ( $AUTO_INCR_RESET =~ m/^\d+$/ && $AUTO_INCR_SEED =~ m/^\d+$/ )
	{
		$AUTO_INCR_SEED = $AUTO_INCR_ORIG_VALUE if ( $AUTO_INCR_RESET && $AUTO_INCR_SEED >= $AUTO_INCR_RESET + 1 );
	}
	else
	{
		$AUTO_INCR_SEED = $AUTO_INCR_ORIG_VALUE if ( $AUTO_INCR_RESET && $AUTO_INCR_SEED gt $AUTO_INCR_RESET );
	}
}

# Shows histogram of columns value.
# param:  Array reference of line's columns.
# return: character(s) to be used for graphing.
sub histogram( $ )
{
	my $line = shift; 
	foreach my $colIndex ( @HISTOGRAM_COLUMN )
	{
		if ( defined @{ $line }[ $colIndex ] )
		{
			printf STDERR "stored column:%s\n", @{ $line }[ $colIndex ] if ( $opt{'D'} );
			my $range_whole_number = read_whole_number( @{ $line }[ $colIndex ] );
			my @new_string = ();
			foreach my $i ( 1..$range_whole_number )
			{
				push @new_string, $hist_ref->{ $colIndex };
			}
			@{ $line }[ $colIndex ] = join '', @new_string;
		}
	}
}

# Computes and returns a value based on whether -A (count) or -J (sum) is used.
# param:  column to select within line. Like 'c2'.
# param:  line of input.
# return: numerical value to be added to the running total.
sub get_column_value( $$ )
{
	my $wantedColumn  = shift;
	my $line          = shift;
	$wantedColumn     =~ s/c//i;
	# Make sure the user entered a '[c|C]n'
	if ( $wantedColumn !~ m/^\d{1,}$/ )
	{
		printf STDERR "** invalid column selection for summation over groups: '%s'.\n", $wantedColumn;
		exit;
	}
	my @columns = split( '\|', $line );
	if ( defined $columns[ $wantedColumn ] )
	{
		# The user may have requested -W so there may be SUB_DELIMITERs in string.
		$columns[ $wantedColumn ] =~ s/($SUB_DELIMITER)/\|/g;
		if ( $columns[ $wantedColumn ] =~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ )
		{
			return $columns[ $wantedColumn ];
		}
		else
		{
			printf STDERR "* warning value in column not numeric: '%s'.\n", $columns[ $wantedColumn ] if ( $opt{'D'} );
		}
	}
	
	return 0;
}

# Formats a value into a string suitable for display. In the case of a float it provides 
# 2 decimal place precision, and if the value is an integer, no decimals places are added.
# param:  value, which is tested against various number formats and returns a string
#         version of the argument value.
# param:  Expected values 0=any, 1=whole number (optional).
# param:  Precision of decimal places in floating values (optional).
# return: Formatted string value of the argument.
sub get_number_format
{
	my $input       = shift @_;
	my $number_type = shift @_ if ( @_ );
	my $precision   = shift @_ if ( @_ );
	my $summary     = '';
	if ( $number_type )
	{
		if ( $input && $input =~ /^[+]?\d+\z/ ){ $summary = sprintf "%d", $input; }
	}	
	elsif ( $input =~ /^[+-]?\d+\z/ )   { $summary = sprintf "%d", $input; }
	elsif ( $input =~ /^-?\d+\.?\d*\z/ || $input =~ /^-?(?:\d+(?:\.\d*)?&\.\d+)\z/ )
	{ $summary = eval("sprintf \"%.".$precision."f\", $input"); }
	elsif ( $input =~ /^([+-]?)(?=\d&\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z/ ){ $summary = $input; }
	else { $summary = "NaN"; }
	return $summary;
}

# Dedups the ALL_LINES array using (O)1 space.
# param:  list of columns to sort on.
# return: <none> - removes duplicate values from the ALL_LINES list.
sub dedup_list( $ )
{
	my $wantedColumns = shift;
	my $count         = {};
	while( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		chomp $line;
		my $key = get_key( $line, $wantedColumns );
		$key = normalize( $key ) if ( $opt{'N'} );
		$ddup_ref->{ $key } = $line;
		if ( $opt{ 'A' } )
		{
			$count->{ $key } = 0 if ( ! exists $count->{ $key } );
			$count->{ $key }++;
		}
		elsif ( $opt{ 'J' } )
		{
			$count->{ $key } = 0 if ( ! exists $count->{ $key } );
			$count->{ $key } += get_column_value( $opt{ 'J' }, $line );
		}
		print STDERR "\$key=$key, \$value=$line\n" if ( $opt{'D'} );
	}
	my @tmp = ();
	if ( $opt{'R'} )
	{
		if ( $opt{'U'} )
		{
			@tmp = sort { $b <=> $a } keys %{$ddup_ref};
		}
		else
		{
			@tmp = sort { $b cmp $a } keys %{$ddup_ref};
		}
	}
	else
	{
		if ( $opt{'U'} )
		{
			@tmp = sort { $a <=> $b } keys %{$ddup_ref};
		}
		else
		{
			@tmp = sort { $a cmp $b } keys %{$ddup_ref};
		}
	}
	while ( @tmp )
	{
		my $key = shift @tmp;
		if ( $opt{ 'A' } or $opt{ 'J' } )
		{
			my $summary = '';
			if ( $opt{'P'} )
			{
				$summary = sprintf "%s|", get_number_format( $count->{ $key } );
			}
			else
			{
				$summary = sprintf " %3s ", get_number_format( $count->{ $key } );
			}
			push @ALL_LINES, $summary . $ddup_ref->{ $key };
		}
		else
		{
			push @ALL_LINES, $ddup_ref->{ $key };
		}
		delete $ddup_ref->{ $key };
	}
}

# Randomizes the entire list of input lines.
# param:  <none>
# return: <none>
sub randomize_list()
{
	# Convert the user requested number to a percent lines of the file.
	my $count = int( ( $opt{ 'r' } / 100.0 ) * scalar @ALL_LINES ); # is already tested for valid percent in init().
	$count = 1 if ( $count < 1 );
	my $randomHash = {};
	my $i = 0;
	# Generate all the random numbers needed as indexes.
	while ( $i != $count )
	{
		my $r = int( rand( scalar @ALL_LINES ) );
		print "\$r=$r\n" if ( $opt{'D'} );
		$randomHash->{ $r } = 1;
		$i = scalar keys %$randomHash;
	}
	my @row_selection = keys %$randomHash;
	my @new_array = ();
	# Grab the values stored on the ALL_LINES array, but don't splice because
	# that will change the size and indexes will miss.
	while ( @row_selection )
	{
		my $index = shift @row_selection;
		if ( defined $ALL_LINES[ $index ] )
		{
			chomp $ALL_LINES[ $index ];
			push @new_array, $ALL_LINES[ $index ];
		}
	}
	# Empty original list.
	while ( @ALL_LINES )
	{
		shift @ALL_LINES;
	}
	# Place the randomized values back onto the @ALL_LINES array.
	while ( @new_array )
	{
		my $value = shift @new_array;
		push @ALL_LINES, $value;
	}
}

# After you have finished reading and processing all lines in the input file
# this function will manage the output.
# param:  <none>
# return: <none>
sub finalize_full_read_functions()
{
	if ( $opt{'d'} )
	{
		dedup_list( \@DDUP_COLUMNS );
	}
	if ( $opt{'r'} ) # select 'n'% of file at random for output.
	{
		randomize_list();
	}
	if ( $opt{'s'} )# Sort the items from STDIN.
	{
		# We have a list of lines. We will split them creating a key that we append to the start with a delimiter of ''
		# When it comes time to sort use the default sort in perl and then remove the prefix.
		sort_list( \@SORT_COLUMNS );
	}
	if ( $opt{'v'} ) # Compute averages now we have read the entire input.
	{
		foreach my $column ( keys %{$avg_ref} )
		{
			if ( exists $avg_count->{ $column } and $avg_count->{ $column } != 0 )
			{
				my $result = sprintf "%.3f", ( $avg_ref->{ $column } / $avg_count->{ $column } );
				# replace the previous column sum with the average.
				$avg_ref->{ $column } = $result;
			}
		}
	}
}

# Tests if this is a line that the user requested to be output.
# param:  integer line number.
# param:  Line read in.
# return: 1 if this line is requested by the user and 0 otherwise.
sub is_printable_range( $$ )
{
	# The key is the start range the value the end of the range.
	my $line_num = shift;
	my $max_line_so_far = 0;
	my $ret_value= 0;
	foreach my $key ( keys %$LINE_RANGES )
	{
		$max_line_so_far = $LINE_RANGES->{ $key } if ( $max_line_so_far <= $LINE_RANGES->{ $key } );
		# are we talking about the end of the file? If so the the key will be negative and full read set true.
		if ( $READ_FULL and $key < 0 )
		{
			push @LINE_BUFF, shift;
			shift @LINE_BUFF if ( scalar @LINE_BUFF > $KEEP_LINES );
			next;
		}
		# printf STDERR "testing if %d is >= %d and <= %d\n", $line_num, $key, $LINE_RANGES->{ $key };
		if ( $line_num >= $key and $line_num <= $LINE_RANGES->{ $key } )
		{
			$ret_value = 1;
		}
	}
	$FAST_FORWARD = 1 if ( $line_num >= $max_line_so_far );
	return $ret_value;
}

# Takes a string and encodes it with URL-safe characters.
# param:  string.
# return: encoded string.
sub map_url_characters( $ )
{
	my @characters = split '', shift;
	my @newString  = ();
	while ( @characters )
	{
		my $c = shift @characters;
		next if ( ! defined $c );
		if ( exists $url_characters->{ ord $c } )
		{
			push @newString, $url_characters->{ ord $c };
			next;
		}
		push @newString, $c;
	}
	return join '', @newString;
}

# Performs URL encoding of given columns.
# param:  line from input.
# return: <none>.
sub url_encode_line( $ )
{
	my $line = shift;
	if ( $U_ENCODE_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
	{
		foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
		{
			@{ $line }[ $colIndex ] = map_url_characters( @{ $line }[ $colIndex ] ) if ( @{ $line }[ $colIndex ] );
		}
		return;
	}
	foreach my $colIndex ( @U_ENCODE_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined @{ $line }[ $colIndex ] )
		{
			@{ $line }[ $colIndex ] = map_url_characters( @{ $line }[ $colIndex ] );
		}
	}
}

# Builds a map of URL characters to URL encoded values.
# param:  <none>
# return: <none>
sub build_encoding_table()
{
	$url_characters->{ord ' '} = '%20'; $url_characters->{ord '!'} = '%21';  $url_characters->{ord '"'} = '%22';
	$url_characters->{ord '#'} = '%23'; $url_characters->{ord '$'} = '%24';  $url_characters->{ord '%'} = '%25';
	$url_characters->{ord '&'} = '%26'; $url_characters->{ord '\''} = '%27'; $url_characters->{ord '('} = '%28';
	$url_characters->{ord ')'} = '%29'; $url_characters->{ord '*'} = '%2A';  $url_characters->{ord '+'} = '%2B';
	$url_characters->{ord ','} = '%2C'; $url_characters->{ord '-'} = '%2D';  $url_characters->{ord '.'} = '%2E';
	$url_characters->{ord '/'} = '%2F'; $url_characters->{ord ':'} = '%3A';  $url_characters->{ord ';'} = '%3B';
	$url_characters->{ord '<'} = '%3C'; $url_characters->{ord '='} = '%3D';  $url_characters->{ord '>'} = '%3E';
	$url_characters->{ord '?'} = '%3F'; $url_characters->{ord '@'} = '%40';  $url_characters->{ord '{'} = '%7B';
	$url_characters->{ord '|'} = '%7C'; $url_characters->{ord '}'} = '%7D';  $url_characters->{ord '~'} = '%7E';
	$url_characters->{ord '['} = '%5B'; $url_characters->{ord '\\'} = '%5C'; $url_characters->{ord ']'} = '%5D';
	$url_characters->{ord '^'} = '%5E'; $url_characters->{ord '_'} = '%5F';  $url_characters->{ord '`'} = '%60';
}

# Outputs table header or footer, depending on argument string.
# param:  String of either 'HEAD' or 'FOOT'.
# return: <none>
sub table_output( $ )
{
	my $placement = shift;
	if ( $TABLE_OUTPUT =~ m/HTML/ )
	{
		if ( $placement =~ m/HEAD/ )
		{
			printf "<table%s>\n  <tbody>\n", $TABLE_ATTR;
		}
		else
		{
			printf "  </tbody>\n</table>\n";
		}
	}
	elsif ( $TABLE_OUTPUT =~ m/WIKI/ )
	{
		if ( $placement =~ m/HEAD/ )
		{
			printf "{| class='wikitable'%s", $TABLE_ATTR;
		}
		else
		{
			printf "|-\n|}\n";
		}
	}
	elsif ( $TABLE_OUTPUT =~ m/MD/ )
	{
		if ( $placement =~ m/HEAD/ )
		{
			printf "%s", $TABLE_ATTR;
		}
		# No footer for MarkDown.
	}
	elsif ( $TABLE_OUTPUT =~ m/CSV/ )
	{
		if ( $placement =~ m/HEAD/ )
		{
			my @titles = split ',', $TABLE_ATTR;
			my $out_string = "";
			for my $title ( @titles )
			{
				$out_string .= sprintf "\"%s\",", trim( $title );
			}
			chop( $out_string ); # Take the last ',' off the end of the string.
			printf "%s\n", $out_string;
		}
		# No footer for CSV.
	}
}

# Merges other columns' data into a specific column.
# param:  Original line input.
# return: <none>.
sub merge_line( $ )
{
	my $line = shift;
	my $i    = 0;
	if ( $MERGE_COLUMNS[ 0 ] =~ m/($KEYWORD_ANY)/i )
	{
		printf STDERR "merge: '%s' \n", $KEYWORD_ANY if ( $opt{'D'} );
		@{ $line }[ 0 ] = join '', @{ $line };
		return;
	}
	if ( ! defined $MERGE_COLUMNS[ 0 ] or ! defined @{ $line }[ $MERGE_COLUMNS[ 0 ] ] ) 
	{
		printf STDERR "** warning: merge target 'c%s' doesn't exist in line '%s...'.\n", $MERGE_COLUMNS[ 0 ], @{ $line }[0] if ( $opt{'D'} );
	}
	# The rest of the columns are to be appended to @{ $line }[ $MERGE_COLUMNS[ 0 ] ]
	for ( $i = 1; $i < scalar( @{ $line } ); $i++ )
	{
		if ( defined $MERGE_COLUMNS[ $i ] and defined @{ $line }[ $MERGE_COLUMNS[ $i ] ] )
		{
			printf STDERR "merge: '%s' \n", @{ $line }[ $MERGE_COLUMNS[ $i ] ] if ( $opt{'D'} );
			@{ $line }[ $MERGE_COLUMNS[ 0 ] ] .= @{ $line }[ $MERGE_COLUMNS[ $i ] ];
		}
	}
}

# Tests if argument is a whole number and returns it if is, and exits if not.
# param:  string value of a numeric value.
# param:  do not exit if defined.
# return: number, or exits with warning if the value isn't a whole number.
sub read_whole_number( $ )
{
	my $input = shift;
	my $value = get_number_format( $input, 1 );
	printf STDERR "argument to read_whole_number()='%s' \n", $value if ( $opt{'D'} );
	return $value if ( $value );
	printf STDERR "*** error: invalid argument, expected a whole number, but got '%s' \n", $input;
	exit( -1 );
}

# This function abstracts all line operations for line by line operations.
# param:  line from file.
# return: Modified line.
sub process_line( $ )
{
	# Always output if -g or -G match or not, but if matches additional processing will be done.
	# We turn it on by default so if -g or -G not used the line will get processed as normal.
	my $continue_to_process_match = 1; 
	my $line = shift;
	chomp $line;
	# With -W the line will look like this; '11|abc{_PIPE_}def'
	my @columns = split '\|', $line;
	if ( $opt{'W'} )
	{
		foreach my $col ( @columns )
		{
			# Replace the sub delimiter to preserve the default pipe delimiter when using -W.
			$col =~ s/($SUB_DELIMITER)/\|/g;
		}
	}
	if ( $opt{'X'} )
	{
		# If IS_X_MATCH is turned on we found the anchor now test for the -Y.
        if ( $IS_X_MATCH )
        {
			if ( $opt{'Y'} )
			{
				if ( ! is_match( \@columns, $match_y_ref, \@MATCH_Y_COLUMNS ) )
				{
					if ( ! $X_UNTIL_Y )
					{
						return '';
					}
				}
				else # Turn off continuous search -- we found the 'Y' search.
				{
					$X_UNTIL_Y = 0;
				}
			}
        }
        # if not '-Y', then once we match on '-X', start outputting lines from there on.
        # But if no match found, try and turn it on by matching this line if no match, suppress output.
        if ( ! $IS_X_MATCH )
        {
            $IS_X_MATCH = is_match( \@columns, $match_start_ref, \@MATCH_START_COLS );
			printf STDERR "Setting X match '%d' ", $IS_X_MATCH if ( $opt{'D'} );
			# Retest b/c you didn't match to get here but do we match now, if we do it's the first match
			# which we want to display which lets the line fall through to the following processes. 
			# If it is not a match return nothing.
			return '' if ( ! $IS_X_MATCH );
        }
	}
	# if the line isn't to be selected for output by '-L skip' return early.
	return '' if ( $SKIP_LINE > 0 and $LINE_NUMBER % $SKIP_LINE != 0 );
	# This function allows the line by line operations to work with operations
	# that require the entire file to be read before working (like sort and dedup).
	# Each operation specified by a different flag.
	if ( $opt{'g'} or $opt{'G'} )
	{
		if ( $opt{'Q'} and $IS_A_POST_MATCH ) # There was a match so dump the buffer if we have been filling it.
		{
			printf STDERR "=>%s\n", $line;
			$IS_A_POST_MATCH = 0;
		}
		# Grep comes first because it assumes that non-matching lines don't require additional operations.
		if ( $opt{'g'} and $opt{'G'} )
		{
			$PREVIOUS_LINE = $line;
			if ( ! ( is_match( \@columns, $match_ref, \@MATCH_COLUMNS ) and is_not_match( \@columns ) ) )
			{
				if ( $opt{'i'} )
				{
					$continue_to_process_match = 0; # let the line contents through but additional processing will be done.
				}
				else
				{
					return '';
				}
			}
		}
		elsif ( $opt{'g'} and ! is_match( \@columns, $match_ref, \@MATCH_COLUMNS ) )
		{
			$PREVIOUS_LINE = $line;
			if ( $opt{'i'} )
			{
				$continue_to_process_match = 0;
			}
			else
			{
				return '';
			}
		}
		elsif ( $opt{'G'} and ! is_not_match( \@columns ) )
		{
			$PREVIOUS_LINE = $line;
			if ( $opt{'i'} )
			{
				$continue_to_process_match = 0;
			}
			else
			{
				return '';
			}
		}
		else # One of the above conditions matched.
		{
			$MATCH_COUNT++;
			if ( $opt{'Q'} ) # There was a match so dump the buffer if we have been filling it.
			{
				printf STDERR "<=%s\n", $PREVIOUS_LINE;
				$IS_A_POST_MATCH = 1;
			}
		}
	}
	if ( $continue_to_process_match )
	{
		if ( $opt{'C'} and ! test_condition( \@columns ) )
		{
			return '';
		}
		inc_line( \@columns  )              if ( $opt{'1'} );
		inc_line_by_value( \@columns )      if ( $opt{'3'} );
		delta_previous_line( \@columns )    if ( $opt{'4'} );
		execute_script_line( \@columns  )   if ( $opt{'k'} );
		modify_case_line( \@columns  )      if ( $opt{'e'} );
		replace_line( \@columns )           if ( $opt{'E'} );
		flip_char_line( \@columns )         if ( $opt{'f'} );
		format_radix( \@columns )           if ( $opt{'F'} );
		url_encode_line( \@columns )        if ( $opt{'u'} );
		translate_line( \@columns )         if ( $opt{'l'} );
		mask_line( \@columns )              if ( $opt{'m'} );
		sub_string_line( \@columns )        if ( $opt{'S'} );
		normalize_line( \@columns )         if ( $opt{'n'} );
		trim_line( \@columns )              if ( $opt{'t'} );
		pad_line( \@columns )               if ( $opt{'p'} );
		# Stop processing lines if the requested column(s) test empty.
		return ''                           if ( $opt{'b'} and ! contain_same_value( \@columns, \@COMPARE_COLUMNS ) );
		return ''                           if ( $opt{'B'} and   contain_same_value( \@columns, \@NO_COMPARE_COLUMNS ) );
		return ''                           if ( $opt{'z'} and is_empty( \@columns ) );
		return ''                           if ( $opt{'Z'} and is_not_empty( \@columns ) );
		width( \@columns, $LINE_NUMBER )    if ( $opt{'w'} );
		sum( \@columns )                    if ( $opt{'a'} );
		count( \@columns )                  if ( $opt{'c'} );
		average( \@columns )                if ( $opt{'v'} );
		merge_line( \@columns )             if ( $opt{'O'} );
		order_line( \@columns )             if ( $opt{'o'} );
		add_auto_increment( \@columns )     if ( $opt{'2'} );
		histogram( \@columns )              if ( $opt{'6'} );
	}
	my $modified_line = '';
	if ( $TABLE_OUTPUT )
	{
		prepare_table_data( \@columns );
		$modified_line = join '', @columns;
		return $modified_line; # The rest of the computation is not relavent to tables.
	}
	if ( $opt{'W'} )
	{
		foreach my $col ( @columns )
		{
			# Replace the sub delimiter to preserve the default pipe delimiter when using -W.
			$col =~ s/\|/$SUB_DELIMITER/g;
		}
	}
	$modified_line = join '|', @columns;
	$line = validate( $line, $modified_line, $LINE_NUMBER );
	chomp $line;
	$line =~ s/\|/\n/g if ( $opt{'K'} );
	# Don't add a delimiter on the last line if not -j and not the last line.
	$line .= '|' if ( trim( $line ) !~ m/\|$/ and $opt{'P'} );
	chop $line if ( $opt{'j'} and $LAST_LINE and $opt{'P'} );
	$line =~ s/\|/$DELIMITER/g if ( $opt{'h'} );
	# Replace the sub delimiter to preserve the default pipe delimiter when using -W.
	$line =~ s/($SUB_DELIMITER)/\|/g if ( $opt{'W'} );
	$PREVIOUS_LINE = $line;
	# Output line numbering, but if -d selected, output dedup'ed counts instead.
	if ( ( $opt{'A'} or $opt{'J'} ) and ! $opt{'d'} )
	{
		return sprintf "%3d %s\n", $LINE_NUMBER, $line;
	}
	if ( $opt{'H'} )
	{
		if ( $opt{'q'} && $LINE_NUMBER % $JOIN_COUNT == 0 ) # Join lines until -q number of lines is emitted.
		{
			return $line . "\n";
		}
		return $line;
	}
	return $line . "\n";
}

# Kicks off the setting of various switches.
# param:
# return:
sub init
{
	my $opt_string = '0:1:2:3:4:56:7:a:Ab:B:c:C:d:De:E:f:F:g:G:h:HiIjJ:k:Kl:L:m:MNn:o:O:p:Pq:Qr:Rs:S:t:T:Uu:v:Vw:W:xX:y:Y:z:Z:';
	getopts( "$opt_string", \%opt ) or usage();
	usage() if ( $opt{'x'} );
	$PRECISION         = read_whole_number( $opt{'y'} ) if ( $opt{'y'} );
	$MATCH_LIMIT       = read_whole_number( $opt{'7'} ) if ( $opt{'7'} );
	$DELIMITER         = $opt{'h'} if ( $opt{'h'} );
	$X_UNTIL_Y         = 1 if ( $opt{'M'} ); # Set continuous output if X and Y are set.
	$JOIN_COUNT        = read_whole_number( $opt{'q'} ) if ( $opt{'q'} );
	@INCR_COLUMNS      = read_requested_columns( $opt{'1'}, 0 ) if ( $opt{'1'} );
	@INCR3_COLUMNS     = read_requested_qualified_columns( $opt{'3'}, $increment_ref, 0 )      if ( $opt{'3'} );
	@DELTA4_COLUMNS    = read_requested_columns( $opt{'4'}, 0 ) if ( $opt{'4'} );
	@SUM_COLUMNS       = read_requested_columns( $opt{'a'}, 0 ) if ( $opt{'a'} );
	@COUNT_COLUMNS     = read_requested_columns( $opt{'c'}, 0 ) if ( $opt{'c'} );
	@EMPTY_COLUMNS     = read_requested_columns( $opt{'z'}, 0 ) if ( $opt{'z'} );
	@SHOW_EMPTY_COLUMNS= read_requested_columns( $opt{'Z'}, 0 ) if ( $opt{'Z'} );
	if ( $opt{'u'} )
	{
		build_encoding_table();
		@U_ENCODE_COLUMNS = read_requested_columns( $opt{'u'}, $KEYWORD_ANY );
	}
	@COND_CMP_COLUMNS  = read_requested_qualified_columns( $opt{'C'}, $cond_cmp_ref, $KEYWORD_ANY )    if ( $opt{'C'} );
	@CASE_COLUMNS      = read_requested_qualified_columns( $opt{'e'}, $case_ref, 0 )        if ( $opt{'e'} );
	@REPLACE_COLUMNS   = read_requested_qualified_columns( $opt{'E'}, $replace_ref, 0 )     if ( $opt{'E'} );
	@NOT_MATCH_COLUMNS = read_requested_qualified_columns( $opt{'G'}, $not_match_ref, $KEYWORD_ANY )   if ( $opt{'G'} );
	@MATCH_COLUMNS     = read_requested_qualified_columns( $opt{'g'}, $match_ref, $KEYWORD_ANY )       if ( $opt{'g'} );
	@MATCH_START_COLS  = read_requested_qualified_columns( $opt{'X'}, $match_start_ref, $KEYWORD_ANY ) if ( $opt{'X'} );
	@MATCH_Y_COLUMNS   = read_requested_qualified_columns( $opt{'Y'}, $match_y_ref, $KEYWORD_ANY )    if ( $opt{'Y'} );
	@SCRIPT_COLUMNS    = read_requested_qualified_columns( $opt{'k'}, $script_ref, 0 )      if ( $opt{'k'} );
	@MASK_COLUMNS      = read_requested_qualified_columns( $opt{'m'}, $mask_ref, 0 )        if ( $opt{'m'} );
	@SUBS_COLUMNS      = read_requested_qualified_columns( $opt{'S'}, $subs_ref, 0 )        if ( $opt{'S'} );
	@TRANSLATE_COLUMNS = read_requested_qualified_columns( $opt{'l'}, $trans_ref, 0 )       if ( $opt{'l'} );
	@PAD_COLUMNS       = read_requested_qualified_columns( $opt{'p'}, $pad_ref, 0 )         if ( $opt{'p'} );
	@FLIP_COLUMNS      = read_requested_qualified_columns( $opt{'f'}, $flip_ref, 0 )        if ( $opt{'f'} );
	@FORMAT_COLUMNS    = read_requested_qualified_columns( $opt{'F'}, $format_ref, 0 )      if ( $opt{'F'} );
	@COMPARE_COLUMNS   = read_requested_columns( $opt{'b'}, 0 )                             if ( $opt{'b'} );
	@NO_COMPARE_COLUMNS= read_requested_columns( $opt{'B'}, 0 )                             if ( $opt{'B'} );
	@NORMAL_COLUMNS    = read_requested_columns( $opt{'n'}, $KEYWORD_ANY )                  if ( $opt{'n'} );
	@MERGE_COLUMNS     = read_requested_columns( $opt{'O'}, $KEYWORD_ANY )                  if ( $opt{'O'} );
	@ORDER_COLUMNS     = read_requested_columns( $opt{'o'}, 0 )                             if ( $opt{'o'} );
	@TRIM_COLUMNS      = read_requested_columns( $opt{'t'}, $KEYWORD_ANY )                  if ( $opt{'t'} );
	if ( $opt{'2'} )
	{
		($AUTO_INCR_COLUMN, $AUTO_INCR_SEED, $AUTO_INCR_RESET) = parse_single_column_single_argument( $opt{'2'} );
		$AUTO_INCR_ORIG_VALUE = $AUTO_INCR_SEED;
	}
	@HISTOGRAM_COLUMN  = read_requested_qualified_columns( $opt{'6'}, $hist_ref, 0 )        if ( $opt{'6'} );
	if ( $opt{'v'} )
	{
		@AVG_COLUMNS   = read_requested_columns( $opt{'v'}, 0 ) if ( $opt{'v'} );
		$READ_FULL = 1;
	}
	if ( $opt{'d'} )
	{
		@DDUP_COLUMNS  = read_requested_columns( $opt{'d'}, 0 );
		$READ_FULL = 1;
	}
	# Output specific lines.
	if ( $opt{'L'} )
	{
		parse_line_ranges( $opt{'L'} );
		if ( $opt{'D'} )
		{
			foreach ( my ( $start, $end ) = each %$LINE_RANGES )
			{
				printf STDERR "line selection range %d to %d\n", $start, $end;
			}
		}
	}
	if ( $opt{'r'} )
	{
		$READ_FULL = 1;
		if ( ! is_between_zero_and_hundred( $opt{'r'} ) )
		{
			print STDERR "** error, invalid random percentage selection.\n";
			usage();
		}
	}
	if ( $opt{'s'} )
	{
		@SORT_COLUMNS  = read_requested_columns( $opt{'s'}, 0 );
		$READ_FULL = 1;
	}
	if ( $opt{'w'} )
	{
		@WIDTH_COLUMNS  = read_requested_columns( $opt{'w'}, 0 );
		$READ_FULL = 1;
	}
	if ( $opt{'T'} )
	{
		my @attrs     = split ':', $opt{'T'};
		shift @attrs; 
		# Shift of 'HTML' or 'WIKI' and re-join the rest of the string to account for ':' separators in both CSS AND Wiki attributes.
		$TABLE_ATTR   = ' ' . join ':', @attrs if ( scalar( @attrs ) > 0 );
		if ( $opt{'T'} =~ m/HTML/i )
		{
			$TABLE_OUTPUT = "HTML";
		}
		elsif ( $opt{'T'} =~ m/WIKI/i )
		{
			$TABLE_OUTPUT = "WIKI";
		}
		elsif ( $opt{'T'} =~ m/MD/i )
		{
			$TABLE_OUTPUT = "MD";
		}
		elsif ( $opt{'T'} =~ m/CSV/i )
		{
			$TABLE_OUTPUT = "CSV";
		}
		else
		{
			printf STDERR "** error, unsupported table type '%s'\n", $opt{'T'};
			exit( 0 );
		}
	}
}

init();
table_output("HEAD") if ( $TABLE_OUTPUT );
my $ifh;
my $is_stdin = 0;
if ( defined $opt{'0'} )
{
	open $ifh, "<", $opt{'0'} or die $!;
}
else
{
	$ifh = *STDIN;
	$is_stdin++;
}
while (<$ifh>)
{
	my $line = $_;
	$LINE_NUMBER++;
	if ( is_printable_range( $LINE_NUMBER, $line ) )
	{
		# remove leading trailing white space to avoid initial empty pipe fields.
		# Also gracefully handles Windows' EOL handling.
		$line = trim( $line );
		if ( $opt{'W'} )
		{
			# Replace delimiter selection with '|' pipe.
			$line =~ s/\|/$SUB_DELIMITER/g; # _PIPE_
			# Now replace the user selected delimiter with a pipe.
			$line =~ s/($opt{'W'})/\|/g;
		}
		push @ALL_LINES, $line;
	}
	last if ( $FAST_FORWARD );
}
close $ifh;
push @ALL_LINES, @LINE_BUFF;
# Print out all results now we have fully read the entire input file and processed it.
finalize_full_read_functions() if ( $READ_FULL );
$LINE_NUMBER = 0;
while ( @ALL_LINES )
{
	$LINE_NUMBER++;
	my $line = shift @ALL_LINES;
	$LAST_LINE = 1 if ( scalar( @ALL_LINES ) == 0 ); # last line of report.
	printf "%s", process_line( $line );
	last if ( $opt{'7'} && $MATCH_COUNT >= $MATCH_LIMIT );
}
if ( $opt{'Q'} and $IS_A_POST_MATCH ) # There was a match so dump the buffer, but we got to the EOF, there is no next line to view.
{
	printf STDERR "=>EOF\n";
	$IS_A_POST_MATCH = 0;
}
table_output("FOOT") if ( $TABLE_OUTPUT );
# Summary section.
print_summary( "count", $count_ref, \@COUNT_COLUMNS ) if ( $opt{'c'} );
print_summary( "sum", $sum_ref, \@SUM_COLUMNS)        if ( $opt{'a'} );
if ( $opt{'v'} )
{
	# compute average for each column.
	foreach my $key ( keys %{ $avg_ref } )
	{
		if ( exists $avg_count->{ $key } and $avg_count->{ $key } > 0 )
		{
			$avg_ref->{ $key } = $avg_ref->{ $key } / $avg_count->{ $key };
		}
		else
		{
			$avg_ref->{ $key } = 0.0;
		}
	}
	print_summary( "average", $avg_ref, \@AVG_COLUMNS );
}
if ( $opt{'w'} )
{
	printf STDERR "== width\n";
	foreach my $column ( sort @WIDTH_COLUMNS )
	{
		if ( defined $width_max_ref->{ 'c'.$column } )
		{
			printf STDERR " %2s: min: %2d at line %d, max: %2d at line %d, mid: %2.1f\n",
			'c'.$column,
			$width_min_ref->{ 'c'.$column },
			$width_line_min_ref->{ 'c'.$column },
			$width_max_ref->{ 'c'.$column },
			$width_line_max_ref->{ 'c'.$column },
			($width_max_ref->{ 'c'.$column } + $width_min_ref->{ 'c'.$column }) / 2;
		}
		else
		{
			printf STDERR " %2s: min: %2d at line -, max: %2d at line -, mid: %2.1f\n",
			'c'.$column, 0, 0, 0;
		}
	}
	if ( %{$WIDTHS_COLUMNS} )
	{
		my @keys   = sort { $a <=> $b } keys %{$WIDTHS_COLUMNS};
		my $metric = shift @keys;
		my $min    = $metric;
		unshift @keys, $metric;
		$metric = pop @keys;
		push @keys, $metric;
		if ( $min == $metric )
		{
			printf STDERR " number of columns: min, max: %d, ", $metric;
			printf STDERR "variance: %d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
		}
		else
		{
			printf STDERR " number of columns:  min: %d at line: %d, ", $min, $WIDTHS_COLUMNS->{ $min };
			printf STDERR "max: %d at line: %d, ", $metric, $WIDTHS_COLUMNS->{ $metric };
			printf STDERR "variance: %d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
		}
	}
}
# EOF
