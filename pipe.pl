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
#          0.1 - Implemented trim, order, sum, and count. 
#          0.0 - Dev. 
#
#######################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;
### Globals
my $VERSION    = qq{0.1};
# For every requested operation we need an array that can hold the columns
# for that operation; in that way we can have multiple operations on different
# columns working at the same time. We store different columns totals on a hash ref.
my @COUNT_COLUMNS  = (); my $count_ref = {};
my @SUM_COLUMNS    = (); my $sum_ref = {};
my @TRIM_COLUMNS   = ();
my @ORDER_COLUMNS  = ();
my @NORMAL_COLUMNS = ();

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: $0 [-dx] [-cnost<c0,c1,...,cn>]
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
 -d             : Debug switch.
 -n[c0,c1,...cn]: Normalize the selected columns, that is, make upper case and remove white space.
 -o[c0,c1,...cn]: Order the columns in a different order. Only the specified columns are output.
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
	print STDERR "columns requested from first file: '@list'\n" if ( $opt{'d'} );
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

# Pulls the desired column values from an input line, based on the 
# requested columns listed in the argument array of columns, ie.
# input: 'a|b|c|' and columns c0, c2, returns a|c
# input: 'a|b|c|' and columns c0, c5, returns a|
# param:  line to pull out columns from.
# param:  columns wanted array, array of columns that are required.
# return: string line with requested columns removed.
# sub getColumns
# {
	# my $line = shift;
	# my @wantedColumns = @_;
	# my @columns = split( '\|', $line );
	# return $line if ( scalar( @columns ) < 2 );
	# my @newLine = ();
	# foreach my $i ( @wantedColumns )
	# {
		# push( @newLine, $columns[ $i ] ) if ( defined $columns[ $i ] and exists $columns[ $i ] );
	# }
	# $line = join( '|', @newLine );
	# $line .= "|" if ( $opt{'t'} );
	# print STDERR ">$line<, " if ( $opt{'d'} );
	# return $line;
# }

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

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
    my $opt_string = 'a:c:dn:o:t:x';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
	@COUNT_COLUMNS = readRequestedColumns( $opt{'c'} ) if ( $opt{'c'} );
	@SUM_COLUMNS   = readRequestedColumns( $opt{'a'} ) if ( $opt{'a'} );
	@NORMAL_COLUMNS= readRequestedColumns( $opt{'n'} ) if ( $opt{'n'} );
	@ORDER_COLUMNS = readRequestedColumns( $opt{'o'} ) if ( $opt{'o'} );
	@TRIM_COLUMNS  = readRequestedColumns( $opt{'t'} ) if ( $opt{'t'} );
}

init();

# Only takes input on STDIN. All output is to STDOUT with the exception of errors.
while (<>)
{
	# Each operation specified by a different flag.
	count( $_ ) if ( $opt{'c'} );
	sum( $_ ) if ( $opt{'a'} );
	my $line = $_;
	# This takes a new line because it gets trimmed during processing.
	$line = normalize_line( $line )  if ( $opt{'n'} );
	$line = order_line( $line )."\n" if ( $opt{'o'} );
	$line = trim_line( $line )       if ( $opt{'t'} );
	print "$line";
}

# Summary section.
printSummary( "count", $count_ref ) if ( $opt{'c'} );
printSummary( "sum", $sum_ref ) if ( $opt{'a'} );

# EOF
