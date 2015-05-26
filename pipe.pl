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
my $VERSION    = qq{0.4};
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

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: cat file | $0 [-Dx] [-cnot<c0,c1,...,cn>] [-ds[-irN]<c0,c1,...,cn>]
Usage notes for $0. This application is a cumulation of helpful scripts that
performs common tasks on pipe-delimited files. The count function (-c), for
example counts the number of non-empty values in the specified columns. Other
functions work similarly. Stacked functions are operated on in alphabetical 
order by flag letter, that is, if you elect to order columns and trim colums 
the columns are first ordered, then the columns are trimmed, because -o comes
before -t.

Example: cat file.lst | $0 -c"c0"

$0 only takes input on STDIN. All output is to STDOUT. Errors go to STDERR.

 -a[c0,c1,...cn]: Sum the non-empty values in given column(s).
 -c[c0,c1,...cn]: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -d[c0,c1,...cn]: Dedups file by creating a key from specified column values 
                  which is then over written with lines that produce
                  the same key, thus keeping the most recent match. Respects (-r).
 -D             : Debug switch.
 -i             : Ignore case on operations (-d and -s) dedup and sort.
 -N             : Normalize keys before comparison when using (-d and -s) dedup and sort.
                  Makes the keys upper case and remove white space before comparison.
                  Output is not normalized. For that see (-n).
                  See also (-i) for case insensitive comparisons.
 -n[c0,c1,...cn]: Normalize the selected columns, that is, make upper case and remove white space.
 -o[c0,c1,...cn]: Order the columns in a different order. Only the specified columns are output.
 -r             : Reverse sort (-d and -s).
 -s[c0,c1,...cn]: Sort on the specified columns in the specified order.
 -t[c0,c1,...cn]: Trim the specified columns of white space front and back.
 -x             : This (help) message.

example: $0 -x
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
		if ( $colNum =~ m/c\d{1,}/ )
		{
			$colNum =~ s/c//; # get rid of the 'c' because it causes problems later.
			push( @list, trim($colNum) );
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
	$string = normalize( $string ) if ( $opt{'n'} );
	return $string;
}

# Prints the contents of the argument hash reference.
# param:  title of output.
# param:  hash reference.
# return: <none>
sub printSummary( $$ )
{
	my $title = shift;
	my $lhs   = shift;
	print "=== $title ===\n";
	while( my ($key, $v) = each %$lhs )
	{
		printf STDERR " %s = %d,", $key, $v if ( defined $lhs->{$key} );
	}
	print "\n";
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
		if ( defined $line[$colIndex] and $line[$colIndex] )
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
		if ( defined $line[$colIndex] and $line[$colIndex] )
		{
			$sum_ref->{ "c$colIndex" } += $line[$colIndex];
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
		if ( defined $line[$colIndex] )
		{
			$line[$colIndex] = trim( $line[$colIndex] );
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
		if ( defined $line[$colIndex] )
		{
			$line[$colIndex] = normalize( $line[$colIndex] );
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
		# print STDERR "$colIndex\n";
		if ( defined $line[$colIndex] )
		{
			push @newLine, $line[$colIndex];
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
	for ( my $i = 0; $i < scalar(@{$wantedColumns}); $i++ )
	{
		my $j = ${$wantedColumns}[$i];
		if ( defined $columns[ $j ] and exists $columns[ $j ] )
		{
			my $cols = $columns[ $j ];
			$cols = lc( $columns[ $j ] ) if ( $opt{ 'i' } );
			push( @newLine, $cols );
		}
	}
	# it doesn't matter what we use as a delimiter as long as we are consistent.
	$key = join( ' ', @newLine );
	return $key;
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
	if ( $opt{'r'} )
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

# This function abstracts all line operations for line by line operations.
# param:  line from file.
# return: Modified line.
sub process_line( $ )
{
	my $line = shift;
	# This function allows the line by line operations to work with operations
	# that require the entire file to be read before working (like sort and dedup).
	# Each operation specified by a different flag.
	count( $line ) if ( $opt{'c'} );
	sum( $line ) if ( $opt{'a'} );
	# This takes a new line because it gets trimmed during processing.
	$line = normalize_line( $line )  if ( $opt{'n'} );
	$line = order_line( $line )."\n" if ( $opt{'o'} );
	$line = trim_line( $line )       if ( $opt{'t'} );
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
	if ( $opt{'r'} )
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
		push @ALL_LINES, $ddup_ref->{$key};
		delete $ddup_ref->{$key};
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
	# Sort the items from STDIN.
	if ( $opt{'s'} )
	{
		# We have a list of lines. We will split them creating a key that we append to the start with a delimiter of ''
		# When it comes time to sort use the default sort in perl and then remove the prefix.
		sort_list( \@SORT_COLUMNS );
	}
}

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
    my $opt_string = 'a:c:d:DiNn:o:rs:t:x';
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
	if ( $opt{'s'} )
	{
		@SORT_COLUMNS  = readRequestedColumns( $opt{'s'} );
		$FULL_READ = 1;
	}
}

init();

# Only takes input on STDIN. All output is to STDOUT with the exception of errors.
while (<>)
{
	if ( $FULL_READ )
	{
		push @ALL_LINES, $_;
		next;
	}
	my $line = process_line( $_ );
	print "$line";
}

# Print out all results now we have fully read the entire input file and processed it.
if ( $FULL_READ )
{
	finalize_full_read_functions();
	while ( @ALL_LINES )
	{
		my $line = shift @ALL_LINES;
		print process_line( $line ) . "\n";
	}
}

# Summary section.
printSummary( "count", $count_ref ) if ( $opt{'c'} );
printSummary( "sum", $sum_ref ) if ( $opt{'a'} );

# EOF
