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
# Rev: 
# Rev: 
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
my $VERSION    = qq{0.5.12_01};
# Flag means that the entire file must be read for an operation like sort to work.
my $FULL_READ  = 0;
my @ALL_LINES  = ();
# For every requested operation we need an array that can hold the columns
# for that operation; in that way we can have multiple operations on different
# columns working at the same time. We store different columns totals on a hash ref.
my @COUNT_COLUMNS  = (); my $count_ref = {};
my @SUM_COLUMNS    = (); my $sum_ref   = {};
my @DDUP_COLUMNS   = (); my $ddup_ref  = {};
my @TRIM_COLUMNS   = ();
my @ORDER_COLUMNS  = ();
my @NORMAL_COLUMNS = ();
my @SORT_COLUMNS   = ();
my $LINE_NUMBER    = 0;
my $START_OUTPUT   = 0;
my $END_OUTPUT     = 0;
my $TAIL_OUTPUT    = 0; # Is this a request for the tail of the file.
my $TABLE_OUTPUT   = 0; # Does the user want to output to a table.

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: cat file | $0 [-DxL] [-cnot<c0,c1,...,cn>] [-ds[-IRN]<c0,c1,...,cn>]
Usage notes for $0. This application is a accumulation of helpful scripts that
performs common tasks on pipe-delimited files. The count function (-c), for
example counts the number of non-empty values in the specified columns. Other
functions work similarly. Stacked functions are operated on in alphabetical 
order by flag letter, that is, if you elect to order columns and trim columns, 
the columns are first ordered, then the columns are trimmed, because -o comes
before -t.

Example: cat file.lst | $0 -c"c0"

$0 only takes input on STDIN. All output is to STDOUT. Errors go to STDERR.
All column references are 0 based.

 -a[c0,c1,...cn]: Sum the non-empty values in given column(s).
 -c[c0,c1,...cn]: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -d[c0,c1,...cn]: Dedups file by creating a key from specified column values 
                  which is then over written with lines that produce
                  the same key, thus keeping the most recent match. Respects (-r).
 -D             : Debug switch.
 -I             : Ignore case on operations (-d and -s) dedup and sort.
 -N             : Normalize keys before comparison when using (-d and -s) dedup and sort.
                  Makes the keys upper case and remove white space before comparison.
                  Output is not normalized. For that see (-n).
                  See also (-I) for case insensitive comparisons.
 -L[[+|-]?n-?m?]: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Line output
                  is suppressed if the entered value is greater than lines read on STDIN.
 -n[c0,c1,...cn]: Normalize the selected columns, that is, make upper case and remove white space.
 -o[c0,c1,...cn]: Order the columns in a different order. Only the specified columns are output.
 -r<percent>    : Output a random percentage of records, ie: -r100 output all lines in random
                  order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
 -R             : Reverse sort (-d and -s).
 -s[c0,c1,...cn]: Sort on the specified columns in the specified order.
 -t[c0,c1,...cn]: Trim the specified columns of white space front and back.
 -T[HTML|WIKI]  : Output as a Wiki table or an HTML table.
 -W             : Break on word spaces instead of '|' pipes.
 -x             : This (help) message.
 
A note on usage; because of the way this script works it is quite possible to produce
mystifying results. For example, failing to remember that ordering comes before trimming
may produce perplexing results. You can do multiple transformations, but if you are not sure
you can pipe output from one process to another pipe process. If you  
order column so that column 1 is output then column 0, but column 0 needs to be trimmed
you would have to write:
 cat file | $0 -o"c1,c0" -t"c1"
because -o will first order the row, so the value you want trimmed is now c1. If that is
too radical to contemplate then:
 cat file | $0 -t"c0" | $0 -o"c1,c0"

Version: $VERSION
EOF
    exit;
}

# Reads the values supplied on the command line and parses them out into the argument list.
# param:  command line string of requested columns.
# return: New array.
sub readRequestedColumns( $ )
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
	print STDERR "columns requested from first file: '@list'\n" if ( $opt{'D'} );
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
sub printSummary( $$$ )
{
	my $title    = shift;
	my $hash_ref = shift;
	my $columns  = shift;
	printf STDERR "== %5s\n", $title;
	foreach my $column ( @{$columns} )
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

# Counts the non-empty values of specified columns. 
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub count( $ )
{
	my @line = split '\|', shift;
	foreach my $colIndex ( @COUNT_COLUMNS )
	{
		# print STDERR "$colIndex\n";
		if ( defined $line[ $colIndex ] and $line[ $colIndex ] )
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
		if ( defined $line[ $colIndex ] and trim( $line[ $colIndex ] ) =~ m/^\.?\d{1,}(\.\d+)?$/ )
		{
			$sum_ref->{ "c$colIndex" } += trim( $line[ $colIndex ] );
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
sub getKey( $$ )
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
	$key = join( ' ', @newLine );
	return $key;
}

# Test if argument is a number between 0-100.
# param:  number to test.
# return: 1 if the argument is a number between 0-100, and 0 otherwise.
sub isBetweenZeroAndHundred( $ )
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
	my @tempArray = ();
	my $wantedColumns = shift;
	while( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		chomp $line;
		my $key = getKey( $line, $wantedColumns );
		$key = normalize( $key ) if ( $opt{'N'} );
		# The key will now always be the first value in the pipe delimited line.
		push @tempArray, $key . '|' . $line;
	}
	my @nextArray = ();
	# reverse sort?
	if ( $opt{'R'} )
	{
		@nextArray = sort { $b cmp $a } @tempArray;
	}
	else # Sort lexically.
	{
		@nextArray = sort @tempArray;
	}
	# now remove the key from the start of the entry for each line in the array.
	while ( @nextArray )
	{
		my $value = shift @nextArray;
		# chop off the first value and push back to @ALL_LINES
		my @line = split '\|', $value;
		# Toss away the key.
		shift @line;
		my $ln = join '|', @line;
		print STDERR "\$ln=$ln\n" if ( $opt{'D'} );
		push @ALL_LINES, $ln;
	}
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
	count( $line ) if ( $opt{'c'} );
	sum( $line )   if ( $opt{'a'} );
	# This takes a new line because it gets trimmed during processing.
	$line = normalize_line( $line )     if ( $opt{'n'} );
	$line = order_line( $line )         if ( $opt{'o'} );
	$line = trim_line( $line )          if ( $opt{'t'} );
	$line = prepare_table_data( $line ) if ( $TABLE_OUTPUT );
	return $line;
}

# Dedups the ALL_LINES array using (O)1 space.
# param:  list of columns to sort on.
# return: <none> - removes duplicate values from the ALL_LINES list.
sub dedup_list( $ )
{
	my $wantedColumns = shift;
	while( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		chomp $line;
		my $key = getKey( $line, $wantedColumns );
		$key = normalize( $key ) if ( $opt{'N'} );
		$ddup_ref->{ $key } = $line;
		print STDERR "\$key=$key, \$value=$line\n" if ( $opt{'D'} );
	}
	my @tmp = ();
	if ( $opt{'R'} )
	{
		@tmp = sort { $b cmp $a } keys %{$ddup_ref};
	}
	else
	{
		@tmp = sort { $a cmp $b } keys %{$ddup_ref};
	}
	while ( @tmp ) 
	{
		my $key = shift @tmp;
		push @ALL_LINES, $ddup_ref->{ $key };
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
}

# Tests if a line number is to be output or not.
# param:  <none>
# return: 0 if the line is to be output and 1 otherwise.
sub isPrintableRange()
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

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
	my $opt_string = 'a:c:d:DIL:Nn:o:Rr:s:t:T:Wx';
	getopts( "$opt_string", \%opt ) or usage();
	usage() if ( $opt{'x'} );
	@SUM_COLUMNS   = readRequestedColumns( $opt{'a'} ) if ( $opt{'a'} );
	@COUNT_COLUMNS = readRequestedColumns( $opt{'c'} ) if ( $opt{'c'} );
	@NORMAL_COLUMNS= readRequestedColumns( $opt{'n'} ) if ( $opt{'n'} );
	@ORDER_COLUMNS = readRequestedColumns( $opt{'o'} ) if ( $opt{'o'} );
	@TRIM_COLUMNS  = readRequestedColumns( $opt{'t'} ) if ( $opt{'t'} );
	if ( $opt{'d'} )
	{
		@DDUP_COLUMNS  = readRequestedColumns( $opt{'d'} );
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
			$FULL_READ = 1;           # we need to compute when to start output.
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
			print STDERR "** error, invalid range value: '" . $opt{'L'} . "'\n";
			usage();
		}
		print STDERR "\$START_OUTPUT=$START_OUTPUT, \$END_OUTPUT=$END_OUTPUT\n" if ( $opt{'D'} );
	}
	if ( $opt{'r'} )
	{
		$FULL_READ = 1;
		if ( ! isBetweenZeroAndHundred( $opt{'r'} ) )
		{
			print STDERR "** error, invalid random percentage selection.\n";
			usage();
		}
	}
	if ( $opt{'s'} )
	{
		@SORT_COLUMNS  = readRequestedColumns( $opt{'s'} );
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
		$line =~ s/\s{1,}/\|/g;
	}
	if ( $FULL_READ )
	{
		push @ALL_LINES, process_line( $line );
		next;
	}
	$LINE_NUMBER++;
	print process_line( $line ) . "\n" if ( isPrintableRange() );
}

# Print out all results now we have fully read the entire input file and processed it.
if ( $FULL_READ )
{
	finalize_full_read_functions();
	# Did the user wanted the last lines but we didn't know how many lines there are until now?
	$END_OUTPUT = scalar @ALL_LINES if ( $END_OUTPUT == 0 );
	$START_OUTPUT = scalar @ALL_LINES - $START_OUTPUT if ( $TAIL_OUTPUT == 1 );
	while ( @ALL_LINES )
	{
		$LINE_NUMBER++;
		my $line = shift @ALL_LINES;
		print $line . "\n" if ( isPrintableRange() );
	}
}
table_output("FOOT") if ( $TABLE_OUTPUT );
# Summary section.
printSummary( "count", $count_ref, \@COUNT_COLUMNS ) if ( $opt{'c'} );
printSummary( "sum", $sum_ref, \@SUM_COLUMNS)        if ( $opt{'a'} );

# EOF
