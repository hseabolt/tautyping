#!/usr/bin/env perl

# postproc_fastani.pl v1.0
# Author: MH Seabolt
# Last Updated: 2-14-2023

# SYNOPSIS:
# Corrects a naming convention from FastANI to use a given sample ID provided in a tabular mapping file.
# Note: This script was originally created as a pipeline-specific processing step for Tau-Typing NF pipeline (but it can totally be used in other cases... at user's own risk/discretion).

##################################################################################
# The MIT License
#
# Copyright (c) 2021 Matthew H. Seabolt
#
# Permission is hereby granted, free of charge, 
# to any person obtaining a copy of this software and 
# associated documentation files (the "Software"), to 
# deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom 
# the Software is furnished to do so, 
# subject to the following conditions:
#
# The above copyright notice and this permission notice 
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##################################################################################

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

# Declare variables
my $fastani = "--";
my $output = "--";
my $map;

my $usage = "postproc_fastani.pl\n
PURPOSE: Corrects a naming convention from FastANI to use a given sample ID provided in a tabular mapping file.\n
USAGE:	postproc_fastani.pl -i <fastani-raw.txt> -o <fastani-corrected.txt> -m <genome-mapping>
-i		FastANI .txt file to correct
-o 		Output .txt file name
-m 		generate metadata TAB file from sequence headers? (splits headers on '<' symbol)
\n";

GetOptions(	'in|i=s' => \$fastani,
			'out|o=s' => \$output,
			'map|m=s' => \$map,
) or die "$usage";
$output = ($output && $output ne "--" || $output ne "stdout")? $output : "--";

# Open and read the genomes basename mapping, save the names to a hash
# Note that we are storing both the forward and reverse orientation of these K-V pairs for reversable lookups
my %Map = ();
open(MAP, "$map") or die "$!\n";
while ( <MAP> )		{
	chomp $_;
	my @line = split("\t", $_);
	foreach ( @line ) {
		$_ =~ s/\s+//;
		$_ =~ s/\.fa[s][t][a]$//;
	}
	$Map{$line[0]} = $line[1];
	$Map{$line[1]} = $line[0];
}
close MAP;

# Set output filehandles
my $succout = open( OUT, ">", "$output" ) if $output ne "--";
my $fhout;
if ( $succout )		{	$fhout = *OUT;		}
else				{	$fhout = *STDOUT;	}

# Open the FastANI table and fix the names to use the IDs and not the filepaths
my $fh = *STDIN;
my $succin = open(FASTANI, "<", "$fastani") if ( $fastani ne "--" && -e $fastani );
$fh = *FASTANI if ( $succin ); 
while ( <$fh> )		{
	chomp $_;
	my @ani = split("\t", $_);
	( $ani[0], $ani[1] ) = ( $Map{$ani[0]}, $Map{$ani[1]} );
	print $fhout join("\t", @ani), "\n";
}
close $fh if ( $succin );
close $fhout if ( $succout );

exit;