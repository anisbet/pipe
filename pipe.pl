#!/usr/bin/perl -w
########################################################################
#
# Perl source file for project pipe 
# Purpose:
# Method:
#
# Pipe performs handy functions on pipe delimited files.
#    Copyright (C) 2015  Andrew Nisbet
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
#          0.8 - Add -p to pad fields.
#          0.8 - Add -b, -B to compare fields are same or different.
#          0.7 - Changed -e to -u, use -e to suppress on empty field.
#                Count only if none empty value in selected field.
#          0.6.3 - Add -E to suppress empty lines on output.
#          0.6.2 - Extend -m to continue outputting mask if not '#' or '_' after line consumed.
#          0.6.1_02 - Bug fix in average display.
#          0.6.1_01 - Documentation update.
#          0.6.1 - Fixed bug in avg function.
#          0.6.0_02 - Added more error reporting with invalid use of -L.
#          0.6.0_01 - Cleaned up usage().
#          0.6 - Pipe changes use of '#'<=>'@', and '_'<=>'-' for easier use in system calls.
#          0.5.18_03 - Fix URL encoding of '0'.
#          0.5.18_02 - Standardized function-naming conventions.
#          0.5.18_01 - Fixed: missing characters in URL encoding.
#          0.5.18 - Added -e URL encode a specific column.
#          0.5.17_01 - Added -G to invert the regex used with -g on a specific column.
#          0.5.17 - Added -g to grep a regex on a specific column.
#          0.5.16_06a - Fixed -m to allow all escaped '-' and '@' characters to be output.
#          0.5.16_06 - Fixed -m to allow all non-'@|-' characters to be output.
#          0.5.16_05 - Fix bug in -L tail function.
#          0.5.16_04 - Modified mask function to allow insert of arbitrary characters.
#          0.5.16_03 - Added -P to add a trailing delimiter before each end of line character.
#          0.5.16_02 - Output line numbers, but if -d is selected outputs duplicate counts instead.
#          0.5.16_01 - Fix bug that was ordering before dedup operation causing confusing output.
#          0.5.16 - Implemented averages. Beefed-up number detection for sum and average.
#          0.5.15_01 - Allow -A On dedup. Outputs like uniq -c. 
#          0.5.15 - Allow -U to sort numerically. 
#          0.5.14_02 - Fix so -m allow all other fields to output unmolested. 
#          0.5.14_01 - Fix usage(). 
#          0.5.14 - Add -m mask on columns. Format -m"c0:--@@@@@@-,c3:@@--@", 
#                  where '-' means suppress and '@' means output.
#          0.5.13_01 - Bug fix for -W.
#          0.5.13 - Introduced new flag function for -W to allow an arbitrary delimiter.
#          0.5.12_01 - Fixed bug that output table headers and footers for invalid table types.
#          0.5.12 - Output tables -T"HTML|WIKI".
#          0.5.11 - Bug fix for -L.
#          0.5.10 - Add -L, line number [+n] head, [n] exact, [-n] tail [n-m] range.
#          0.5.9 - Columns can be designated with [C|c], warning emitted if incorrect.
#          0.5.8 - Make output of summaries better.
#          0.5.7 - Add -W to work on white space instead of just pipes.
#          0.5.6 - Fix bug in summation.
#          0.5.5 - Fix so sort always occurs last.
#          0.5.4 - Fix sum to work on fields with digits only.
#          0.5.3 - Clarified -r usage messaging.
#          0.5.2 - Fix formatting, flag error in usage.
#          0.5.1 - Fix spelling mistakes. 
#          0.5 - Normalize modifier options to UCase, add -r randomize flag. 
#          0.4 - Implemented dedup with normalization option. 
#          0.3.1 - Implemented reverse sort. 
#          0.3 - Implemented sort. 
#          0.2 - Implemented trim, order, sum, and count. 
#          0.1 - Implemented trim, order, sum, and count. 
#          0.0 - Dev. 
#
#######################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;
### Globals
my $VERSION    = qq{0.9};
# Flag means that the entire file must be read for an operation like sort to work.
my $FULL_READ  = 0;
my @ALL_LINES  = ();
# For every requested operation we need an array that can hold the columns
# for that operation; in that way we can have multiple operations on different
# columns working at the same time. We store different columns totals on a hash ref.
my @COUNT_COLUMNS     = (); my $count_ref = {};
my @SUM_COLUMNS       = (); my $sum_ref   = {};
my @AVG_COLUMNS       = (); my $avg_ref   = {}; my $avg_count = {};
my @DDUP_COLUMNS      = (); my $ddup_ref  = {};
my @TRIM_COLUMNS      = ();
my @ORDER_COLUMNS     = ();
my @NORMAL_COLUMNS    = ();
my @SORT_COLUMNS      = ();
my @MASK_COLUMNS      = (); my $mask_ref  = {}; # Stores the masks by column number.
my @PAD_COLUMNS       = (); my $pad_ref   = {}; # Stores the pad instructions by column number.
my @MATCH_COLUMNS     = (); my $match_ref = {}; # Stores regular expressions.
my @NOT_MATCH_COLUMNS = (); my $not_match_ref = {}; # Stores regular expressions for -G.
my @U_ENCODE_COLUMNS  = (); my $url_characters= {}; # Stores the character mappings.
my @EMPTY_COLUMNS     = (); # empty column number checks.
my @COMPARE_COLUMNS   = (); # Compare all collected columns and report if equal.
my @NO_COMPARE_COLUMNS= (); # ! Compare all collected columns and report if equal.
my $LINE_NUMBER       = 0;
my $START_OUTPUT      = 0;
my $END_OUTPUT        = 0;
my $TAIL_OUTPUT       = 0; # Is this a request for the tail of the file.
my $TABLE_OUTPUT      = 0; # Does the user want to output to a table.

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

    usage: cat file | pipe.pl [-ADxLTUW<delimiter>] 
       [-bBcnotuvz<c0,c1,...,cn>] 
       [-ds[-IRN]<c0,c1,...,cn>] 
       [-m'cn:[_|#]*,...']
       [-p'cn:[+|-]countChar+,...]
       [-gG<cn:regex,...>]
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
                  Example data: 1481241, -g"c0:241$" produces '1481241'. Use 
                  escaped commas specify a ',' in a regular expression because comma
                  is the column definition delimiter. See also '-m' mask.
 -G[c0:regex,...]: Inverse of '-g', and can be used together to perform AND operation as
                  return true if match on column 1, and column 2 not match. 
 -I             : Ignore case on operations (-d and -s) dedup and sort.
 -L[[+|-]?n-?m?]: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Line output
                  is suppressed if the entered value is greater than lines read on STDIN.
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
 -W[delimiter]  : Break on specified delimiter instead of '|' pipes, ie: "\^", and " ".
 -x             : This (help) message.
 -z[c0,c1,...cn]: Suppress line if the specified column(s) are empty, or don't exist.
 
The order of operations is as follows:
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
  -T - Output in table form.

Version: $VERSION
EOF
    exit;
}

# Reads the values supplied on the command line and parses them out into the argument list, 
# and populates the appropriate hash reference of column qualifiers hash-reference.
# param:  command line string of requested columns.
# param:  hash reference of column names and qualifiers.
# return: New array.
sub read_requested_qualified_columns( $$ )
{
	my $line     = shift;
	my @list     = ();
	my $hash_ref = shift;
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
			$hash_ref->{$nameQualifier[0]} = trim( $nameQualifier[1] );
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

# Reads the values supplied on the command line and parses them out into the argument list.
# param:  command line string of requested columns.
# return: New array.
sub read_requested_columns( $ )
{
	my $line = shift;
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
	$line =~ s/\s+//g;
	$line = uc $line;
	return $line;
}

#
# Trim function to remove white space from the start and end of the string.
# This version also will normalize the string if '-n' flag is selected.
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
	printf STDERR "== %5s\n", $title;
	foreach my $column ( sort @{$columns} )
	{
		if ( defined $hash_ref->{ 'c'.$column } )
		{
			printf STDERR " %2s: %7d\n", 'c'.$column, $hash_ref->{ 'c'.$column };
		}
		else
		{
			printf STDERR " %2s: %7d\n", 'c'.$column, 0;
		}
	}
}

# Prints the contents of the argument hash reference as float values.
# param:  title of output.
# param:  hash reference of data.
# param:  List of columns requested by user.
# return: <none>
sub print_float_summary( $$$ )
{
	my $title    = shift;
	my $hash_ref = shift;
	my $columns  = shift;
	printf STDERR "== %5s\n", $title;
	foreach my $column ( sort @{$columns} )
	{
		if ( defined $hash_ref->{ 'c'.$column } and keys( %{$hash_ref} ) > 0 )
		{
			printf STDERR " %2s: %7.2f\n", 'c'.$column, $hash_ref->{ 'c'.$column };
		}
		else
		{
			printf STDERR " %2s: %7.2f\n", 'c'.$column, 0;
		}
	}
}

# Counts the non-empty values of specified columns. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub count( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @COUNT_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] and $line[ $colIndex ] =~ m/\S/ )
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
	my @line = split '\|', shift;
	foreach my $colIndex ( @SUM_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] and trim( $line[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
		{
			$sum_ref->{ "c$colIndex" } += trim( $line[ $colIndex ] );
		}
	}
}

# Average the non-empty values of specified columns. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub average( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @AVG_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] and trim( $line[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
		{
			$avg_ref->{ "c$colIndex" } += trim( $line[ $colIndex ] );
			$avg_count->{ "c$colIndex" } = 0 if ( ! exists $avg_count->{ "c$colIndex" } );
			$avg_count->{ "c$colIndex" }++;
		}
	}
}

# Removes the white space from of specified columns. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub trim_line( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @TRIM_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] )
		{
			$line[ $colIndex ] = trim( $line[ $colIndex ] );
		}
	}
	return join '|', @line;
}

# Normalizes of specified columns, removing white space
# and changing lower case letters to upper case. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub normalize_line( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @NORMAL_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] )
		{
			$line[ $colIndex ] = normalize( $line[ $colIndex ] );
		}
	}
	return join '|', @line;
}

# Places specified columns in a different order. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub order_line( $ )
{
	my @line = split '\|', shift;
	my @newLine = ();
	foreach my $colIndex ( @ORDER_COLUMNS )
	{
		if ( defined $line[ $colIndex ] )
		{
			push @newLine, $line[ $colIndex ];
		}
	}
	return join '|', @newLine;
}

# Returns the key composed of the selected fields.
# param:  string line of values from the input.
# param:  List of desired fields, or columns.
# return: string composed of each string selected as column pasted together without trailing spaces.
sub get_key( $$ )
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
			$cols = lc( $columns[ $j ] ) if ( $opt{ 'I' } );
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
	my @tempArray     = ();
	my $wantedColumns = shift;
	my @tempKeys      = ();
	while( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		chomp $line;
		my $key = get_key( $line, $wantedColumns );
		$key = normalize( $key ) if ( $opt{'N'} );
		# The key will now always be the first value in the pipe delimited line.
		push @tempArray, $key . '|' . $line;
		push @tempKeys, $key;
	}
	my @sortedKeysArray = ();
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
	@tempKeys = ();
	# now remove the key from the start of the entry for each line in the array.
	while ( @sortedKeysArray )
	{
		my $key = shift @sortedKeysArray;
		# Grep the key from the arrays of lines, it is the first element on each line.
		# The next line gets the indexes of all the matches, but just need the first.
		# All subsequent key matches will match on remainder of elements on the next
		# iteration. If you try and process all the indexes now you end up with a 
		# complicated index value computation when trying to splice the array.
		# http://stackoverflow.com/questions/174292/what-is-the-best-way-to-delete-a-value-from-an-array-in-perl
		my @indexes = grep { $tempArray[ $_ ] =~ m/^($key)\|/ } 0..$#tempArray;
		print STDERR "\$key=$key\n" if ( $opt{'D'} );
		# chop off the first key and push back to @ALL_LINES
		if ( defined $indexes[ 0 ] )
		{
			my @line = split '\|', $tempArray[ $indexes[ 0 ] ];
			# Toss away the key.
			shift @line;
			my $ln = join '|', @line;
			print STDERR "::\$ln=$ln\n" if ( $opt{'D'} );
			push @ALL_LINES, $ln;
			splice( @tempArray, $indexes[ 0 ], 1 );
		}
	}
	@tempArray = ();
}

# Outputs data from argument line as either HTML or WIKI.
# param:  String of line data - pipe-delimited.
# return: string with table formatting.
sub prepare_table_data( $ )
{
	my $line = shift;
	my @fields = split '\|', $line;
	if ( $TABLE_OUTPUT =~ m/HTML/i )
	{
		$line = join '</td><td>', @fields;
		$line = "  <tr><td>" . $line . "</td></tr>";
	}
	elsif ( $TABLE_OUTPUT =~ m/WIKI/i )
	{
		$line = join ' || ', @fields;
		$line = "|-\n| " . $line ;
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
# return: string with table formatting.
sub mask_line( $ )
{
	my @line = split '\|', shift;
	my @newLine = ();
	my $colIndex= 0;
	while ( @line )
	{
		my $field = shift @line;
		if ( exists $mask_ref->{ $colIndex } )
		{
			push @newLine, apply_mask( $field, $mask_ref->{ $colIndex } );
		}
		else
		{
			push @newLine, $field;
		}
		$colIndex++;
	}
	return join '|', @newLine;
}

# Greps specific columns for a given Perl pattern. See usage().
# param:  String of line data - pipe-delimited.
# return: line if the pattern matched and nothing if it didn't.
sub is_match( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @MATCH_COLUMNS )
	{
		if ( defined $line[ $colIndex ] and exists $match_ref->{ $colIndex } )
		{
			printf STDERR "regex: '%s' \n", $match_ref->{$colIndex} if ( $opt{'D'} );
			return 1 if ( $line[ $colIndex ] =~ m/($match_ref->{$colIndex})/ );
		}
	} 
	return 0;
}

# Inverse grep specific columns for a given Perl pattern. See usage().
# param:  String of line data - pipe-delimited.
# return: line if the pattern matched and nothing if it didn't.
sub is_not_match( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @NOT_MATCH_COLUMNS )
	{
		if ( defined $line[ $colIndex ] and exists $not_match_ref->{ $colIndex } )
		{
			printf STDERR "regex: '%s' \n", $not_match_ref->{$colIndex} if ( $opt{'D'} );
			return 0 if ( $line[ $colIndex ] =~ m/($not_match_ref->{$colIndex})/ );
		}
	} 
	return 1;
}

# Tests if a line is empty of content. Empty includes column doesn't exist and or is empty.
# param:  string (line) to test.
# return: 1 if there is a non-empty field, and 0 otherwise.
sub is_empty( $ )
{
	my @line = split '\|', shift;
	printf STDERR "EMPTY_LINE: " if ( $opt{'D'} );
	foreach my $colIndex ( @EMPTY_COLUMNS )
	{
		return 1 if ( ! defined $line[ $colIndex ] );
		printf STDERR "'%s', ", $line[ $colIndex ] if ( $opt{'D'} );
		return 1 if ( $line[ $colIndex ] =~ m/^\s{1,}?$/ );
	}
	printf STDERR "\n" if ( $opt{'D'} );
	return 0;
}

# Compares requested fields and returns line if they match.
# param:  string, pipe delimited line.
# param:  list of column indexes to compare on.
# return: 1 if the fields matched and 0 otherwise.
sub contain_same_value( $$ )
{
	my @line = split '\|', shift;
	my $wantedColumns = shift;
	printf STDERR "CMP_LINE: " if ( $opt{'D'} );
	my $lastValue = '';
	my $matchCount = 0;
	my $isInitialLoop = 1;
	foreach my $colIndex ( @{$wantedColumns} )
	{
		next if ( ! defined $line[ $colIndex ] );
		printf STDERR "'%s', ", $line[ $colIndex ] if ( $opt{'D'} );
		if ( $isInitialLoop )
		{
			$lastValue = $line[ $colIndex ];
			$isInitialLoop = 0;
			$matchCount++; # If there is only one column selected it matches.
			next;
		}
		$matchCount++ if ( $line[ $colIndex ] =~ m/^($lastValue)$/ );
	}
	printf STDERR "MATCHES: '%d'\n", $matchCount if ( $opt{'D'} );
	return $matchCount == scalar( @{$wantedColumns} );
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
sub pad_line( $ )
{
	my @line = split '\|', shift;
	my @newLine = ();
	my $colIndex= 0;
	while ( @line )
	{
		my $field = shift @line;
		if ( exists $pad_ref->{ $colIndex } )
		{
			push @newLine, apply_padding( $field, $pad_ref->{ $colIndex } );
		}
		else
		{
			push @newLine, $field;
		}
		$colIndex++;
	}
	return join '|', @newLine;
}

# This function abstracts all line operations for line by line operations.
# param:  line from file.
# return: Modified line.
sub process_line( $ )
{
	my $line = shift;
	chomp $line;
	# This function allows the line by line operations to work with operations
	# that require the entire file to be read before working (like sort and dedup).
	# Each operation specified by a different flag.
	# Grep comes first because it assumes that non-matching lines don't require additional operations.
	if ( $opt{'g'} and $opt{'G'} )
	{
		return '' if ( ! ( is_match( $line ) and is_not_match( $line ) ) );
	}
	elsif ( $opt{'g'} and ! is_match( $line ) )
	{
		return '';
	}
	elsif ( $opt{'G'} and ! is_not_match( $line ) )
	{
		return '';
	}
	sum( $line )       if ( $opt{'a'} );
	count( $line )     if ( $opt{'c'} );
	average( $line )   if ( $opt{'v'} );
	$line = url_encode_line( $line )    if ( $opt{'u'} );
	$line = mask_line( $line )          if ( $opt{'m'} );
	$line = normalize_line( $line )     if ( $opt{'n'} );
	$line = order_line( $line )         if ( $opt{'o'} );
	$line = trim_line( $line )          if ( $opt{'t'} );
	$line = pad_line( $line )           if ( $opt{'p'} );
	# Stop processing lines if the requested column(s) test empty.
	return '' if ( $opt{'b'} and ! contain_same_value( $line, \@COMPARE_COLUMNS ) );
	return '' if ( $opt{'B'} and   contain_same_value( $line, \@NO_COMPARE_COLUMNS ) );
	return '' if ( $opt{'z'} and is_empty( $line ));
	$line = prepare_table_data( $line ) if ( $TABLE_OUTPUT );
	if ( $opt{'P'} )
	{
		chomp $line;
		$line .= "|";
	}
	# Output line numbering, but if -d selected, output dedup'ed counts instead.
	if ( $opt{'A'} and ! $opt{'d'} )
	{
		return sprintf "%3d %s\n", $LINE_NUMBER, $line;
	}
	return $line . "\n";
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
		if ( $opt{ 'A' } )
		{
			my $summary = sprintf " %3d ", $count->{ $key };
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

# Tests if a line number is to be output or not.
# param:  <none>
# return: 0 if the line is to be output and 1 otherwise.
sub is_printable_range()
{
	if ( $opt{'L'} )
	{
		if ( $LINE_NUMBER <= $END_OUTPUT )
		{
			if ( $LINE_NUMBER >= $START_OUTPUT )
			{
				return 1;
			}
			return 0;
		}
		return 0;
	}
	return 1;
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
# return: line with requested columns encoded as URL.
sub url_encode_line( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @U_ENCODE_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] )
		{
			$line[ $colIndex ] = map_url_characters( $line[ $colIndex ] );
		}
	}
	return join '|', @line;
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

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
	my $opt_string = 'a:Ab:B:c:d:Dg:G:IL:Nn:m:o:p:PRr:s:t:T:Uu:v:W:xz:';
	getopts( "$opt_string", \%opt ) or usage();
	usage() if ( $opt{'x'} );
	@SUM_COLUMNS       = read_requested_columns( $opt{'a'} ) if ( $opt{'a'} );
	@COUNT_COLUMNS     = read_requested_columns( $opt{'c'} ) if ( $opt{'c'} );
	@EMPTY_COLUMNS     = read_requested_columns( $opt{'z'} ) if ( $opt{'z'} );
	if ( $opt{'u'} )
	{
		build_encoding_table();
		@U_ENCODE_COLUMNS  = read_requested_columns( $opt{'u'} );
	}
	@NOT_MATCH_COLUMNS = read_requested_qualified_columns( $opt{'G'}, $not_match_ref ) if ( $opt{'G'} );
	@MATCH_COLUMNS     = read_requested_qualified_columns( $opt{'g'}, $match_ref ) if ( $opt{'g'} );
	@MASK_COLUMNS      = read_requested_qualified_columns( $opt{'m'}, $mask_ref ) if ( $opt{'m'} );
	@PAD_COLUMNS       = read_requested_qualified_columns( $opt{'p'}, $pad_ref ) if ( $opt{'p'} );
	@COMPARE_COLUMNS   = read_requested_columns( $opt{'b'} ) if ( $opt{'b'} );
	@NO_COMPARE_COLUMNS= read_requested_columns( $opt{'B'} ) if ( $opt{'B'} );
	@NORMAL_COLUMNS    = read_requested_columns( $opt{'n'} ) if ( $opt{'n'} );
	@ORDER_COLUMNS     = read_requested_columns( $opt{'o'} ) if ( $opt{'o'} );
	@TRIM_COLUMNS      = read_requested_columns( $opt{'t'} ) if ( $opt{'t'} );
	if ( $opt{'v'} )
	{
		@AVG_COLUMNS   = read_requested_columns( $opt{'v'} ) if ( $opt{'v'} );
		$FULL_READ = 1;
	}
	if ( $opt{'d'} )
	{
		@DDUP_COLUMNS  = read_requested_columns( $opt{'d'} );
		$FULL_READ = 1;
	}
	# Output specific lines.
	if ( $opt{'L'} ) 
	{
		# Line requests can look like this '+n', '-n', 'n-m', or 'n'.
		# Case '+n'
		if ( $opt{'L'} =~ m/^\+\d{1,}$/ )
		{
			$END_OUTPUT = $opt{'L'};
			$END_OUTPUT =~ s/^\+//; # equiv of head n lines
		}
		# Case 'n'
		elsif ( $opt{'L'} =~ m/^\d{1,}$/ )
		{
			$START_OUTPUT = $opt{'L'};
			$END_OUTPUT   = $opt{'L'};
		}
		# Case '-n'
		elsif ( $opt{'L'} =~ m/^\-\d{1,}$/ )
		{
			$START_OUTPUT = $opt{'L'};
			$START_OUTPUT =~ s/^\-//; # equiv of tail n lines
			$FULL_READ    = 1;        # we need to compute when to start output.
			$TAIL_OUTPUT  = 1;        # Reading from the end of the input.
		}
		# Case 'n-m' and 'n-'
		elsif ( $opt{'L'} =~ m/\-/ )
		{
			# The easiest is if it is a range because we can just split on the dash and set start and end.
			my @testRange = split '-', $opt{'L'};
			if ( defined $testRange[1] and $testRange[1] =~ m/\d{1,}/ )
			{
				$END_OUTPUT = $testRange[1]; 
			}
			if ( defined $testRange[0] and $testRange[0] =~ m/\d{1,}/ )
			{
				$START_OUTPUT = $testRange[0];
				$TAIL_OUTPUT = 1 if ( $END_OUTPUT == 0 );
			}
			$FULL_READ = 1 if ( $END_OUTPUT == 0 ); # we are going to have find just how many lines there are for 'n-'
		}
		else
		{
			if ( ! exists $opt{'L'} )
			{
				printf STDERR "** error, no range supplied with '-L'\n";
			}
			else
			{
				printf STDERR "** error, invalid range value: '%s'\n", $opt{'L'};
			}
			usage();
		}
		print STDERR "\$START_OUTPUT=$START_OUTPUT, \$END_OUTPUT=$END_OUTPUT\n" if ( $opt{'D'} );
	}
	if ( $opt{'r'} )
	{
		$FULL_READ = 1;
		if ( ! is_between_zero_and_hundred( $opt{'r'} ) )
		{
			print STDERR "** error, invalid random percentage selection.\n";
			usage();
		}
	}
	if ( $opt{'s'} )
	{
		@SORT_COLUMNS  = read_requested_columns( $opt{'s'} );
		$FULL_READ = 1;
	}
	if ( $opt{'T'} )
	{
		if ( $opt{'T'} =~ m/HTML/i )
		{
			$TABLE_OUTPUT = "HTML";
		}
		if ( $opt{'T'} =~ m/WIKI/i )
		{
			$TABLE_OUTPUT = "WIKI";
		}
	}
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
			print "<table>\n  <tbody>\n";
		}
		else
		{
			print "  </tbody>\n</table>\n";
		}
	}
	if ( $TABLE_OUTPUT =~ m/WIKI/ )
	{
		if ( $placement =~ m/HEAD/ )
		{
			print "{| class='wikitable'\n";
		}
		else
		{
			print "|-\n|}\n";
		}
	}
}

init();
table_output("HEAD") if ( $TABLE_OUTPUT );
# Only takes input on STDIN. All output is to STDOUT with the exception of errors.
while (<>)
{
	my $line = $_;
	if ( $opt{'W'} )
	{
		$line = trim( $line ); # remove leading trailing white space to avoid initial empty pipe fields.
		# Replace delimiter selection with '|' pipe.
		$line =~ s/($opt{'W'})/\|/g;
	}
	if ( $FULL_READ )
	{
		push @ALL_LINES, $line;
		next;
	}
	$LINE_NUMBER++;
	print process_line( $line ) if ( is_printable_range() );
}

# Print out all results now we have fully read the entire input file and processed it.
if ( $FULL_READ )
{
	finalize_full_read_functions();
	# Did the user wanted the last lines but we didn't know how many lines there are until now?
	$END_OUTPUT = scalar @ALL_LINES if ( $END_OUTPUT == 0 );
	# if the input is 5 lines long, we want the last 2, we need 5 - 2 + 1
	$START_OUTPUT = scalar @ALL_LINES - $START_OUTPUT + 1 if ( $TAIL_OUTPUT == 1 );
	while ( @ALL_LINES )
	{
		$LINE_NUMBER++;
		my $line = shift @ALL_LINES;
		print process_line( $line ) if ( is_printable_range() );
	}
}
table_output("FOOT") if ( $TABLE_OUTPUT );
# Summary section.
print_summary( "count", $count_ref, \@COUNT_COLUMNS )    if ( $opt{'c'} );
print_summary( "sum", $sum_ref, \@SUM_COLUMNS)           if ( $opt{'a'} );
if ( $opt{'v'} )
{
	# compute average for each column.
	foreach my $key ( keys %{$avg_ref} )
	{
		if ( exists $avg_count->{$key} and $avg_count->{$key} > 0 )
		{
			$avg_ref->{$key} = $avg_ref->{$key} / $avg_count->{$key};
		}
		else
		{
			$avg_ref->{$key} = 0.0;
		}
	}
	print_float_summary( "average", $avg_ref, \@AVG_COLUMNS );
}
# EOF
