#!/usr/bin/env perl

# concat_alignments.pl v0.1.0
# Author: MH Seabolt
# Last updated: 2-23-2023

# SYNOPSIS
# Concatenates FASTA alignments into a super-alignment.

##################################################################################
# The MIT License
#
# Copyright (c) 2023 Matthew H. Seabolt
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

# Required input parameters
my $ali;
my $outfmt;
my $output = "--";
my $fix_headers;
my $match_ends;
my $inputlist;
my $randsample = 1;
my $v;

sub usage {
	my $usage = "concat_alignments.pl\n
	PURPOSE: 	Concatenates FASTA alignments into a super-alignment. 
				*** Note: Fasta sequences must have the same names in order to be concatenated!\n
	USAGE:	concat_alignments.pl -i ali1.fasta,ali2.fasta,ali3.fasta -o superAliOut -f nexus
	-i		input FASTA alignment files in comma separated list
	-il 		input list of FASTA alignment files, one per line (cannot be used in conjunction with --input)
	-f		output file format (fasta (Default) or nexus)
	-c		INT flag; correct headers? (Default OFF)
	-e		INT flag; ends must match (pads the end of truncated alignments with gaps; Default OFF)?
	-r 		INT; randomly subsample INT alignments from the given set of alignments (Default OFF)
	-o		output file name (no extensions!)\n";
	print $usage;
}

GetOptions(	'input|i=s' => \$ali,
			'list|il=s' => \$inputlist,
			'out|o=s' => \$output,
			'random|r=i' => \$randsample,
			'verbose|v' => \$v,
) or die usage();

# Set default outfmt unless specified
$output = ($output && $output ne "--" || $output ne "stdout")? $output : "--";
$randsample =  ($randsample && $randsample <= 1 )? 1 : $randsample;
$v = defined($v)? 1 : 0;

# Read in the list if a list is given
my @alis;
if ( $inputlist && -e $inputlist )		{
	open LIST, $inputlist or die "$!\n";
		@alis = <LIST>;
	close LIST;
	
	chomp $_ foreach ( @alis );
}
# Elsewise, split the csv input
else		{
	@alis = split",", $ali;
}

# If we want to randomly subsample the list of alignments, randomly choose the requested number of alignment files
# and concatenate those.  Write out the partitions file as well.
# This routine only does this procedure ONCE -- if you want to generate multiple random subsamples, run the concat_alignments script inside a for loop.
my @randalns;
if ( $randsample >= 2 )	{
	while ( scalar @randalns < $randsample )	{
		my $rand = rand( scalar @alis );		# A randomly chosen array index	
		push @randalns, $alis[$rand];
		splice(@alis, $rand, 1);
	}
	@alis = @randalns;
}

# Store the first FASTA sequences in a hash
my $fasta = shift @alis;
$/ = ">";
open DATA, $fasta or die "Something is wrong with your input $fasta file.  $!\n";
	my @fasta = <DATA>;
	my $trash = shift @fasta;	# Get rid of the first element, which will be a lone ">" symbol
close DATA;
$/ = "\n";

my %Alignment = ();
foreach my $record ( @fasta )	{
	my ($header, @seq) = split "\n", $record;
	my $seq = join '', @seq;
	$seq =~ s/>//g;						# Remove any lingering ">" symbols
	$seq = uc $seq;						# Convert everything to uppercase 
		
	# Store the sequences as a hash
	$Alignment{$header} = $seq;
}	

# Write out the first partition to a text file
open PART, ">", "$output.partitions.tab" or warn;
my $i = 1;
my $partition = get_longest_hash_value(\%Alignment);
print PART "Partition$i\t$fasta\t1\t$partition\n";
my $partition_i = $partition;			# Initialize the subsequent partition end points --> we will update this value as we go
$i++;

#### Foreach subsequent alignment file in @alis, read it in as a hash
my $num_alis = scalar @alis;
my $f = 0;
while ( scalar @alis > 0 )	{
	my $fasta = shift @alis;
	$f++;
	print STDERR " === Adding $fasta to the concatenated alignment ( $f / $num_alis ) === \n" if ( $v == 1 );
	
	$/ = ">";
	open DATA, $fasta or die "Something is wrong with your input fasta file.  $!\n";
		my @fasta = <DATA>;
		my $trash = shift @fasta;	# Get rid of the first element, which will be a lone ">" symbol
	close DATA;
	$/ = "\n";
	
	foreach my $record ( @fasta )	{
		my ($header, @seq) = split "\n", $record;
		my $seq = join '', @seq;
		$seq =~ s/>//g;						# Remove any lingering ">" symbols
		$seq = uc $seq;						# Convert everything to uppercase 
		
		# If the fasta header key already exists in the alignment (and it should...), append the new data to the existing value
		if ( exists $Alignment{$header} )	{
			# Check that the current length of the sequence for this header is equal to the longest sequence in the concat alignment thus far
			# If it is, great. We are happy.  If not, then pad the end with gaps.
			if ( length( $Alignment{$header} ) < $partition_i )	{
				my $front_pad = ("-" x ( $partition_i - length($Alignment{$header})));
				$Alignment{$header} .= $front_pad;
			}
			my $gaps = get_longest_hash_value(\%Alignment);
			my $gapseq = $seq . ("-" x ($gaps - length($seq)));		# Fill in any wonky end parts with placehold gap chars
			$Alignment{$header} .= $seq;
			$Alignment{$header} =~ s/\s+//g;
		}
		# If it doesnt exist (probably due to a naming error), then add in the appropriate number of gap chars and append the seq on the end.
		else	{
			my $gaps = get_longest_hash_value(\%Alignment);
			my $gapseq = "-" x $gaps;
			$gapseq .= $seq;								# Prepends the sequence with gaps at the beginning
			$gapseq .= ("-" x ($gaps - length($seq)));		# Fill in any wonky end parts with placehold gap chars
			$Alignment{$header} = $gapseq;
			$Alignment{$header} =~ s/\s+//g;
		}
	}
	# Update and write the latest partition to the PART file
	$partition += 1;
	$partition_i = get_longest_hash_value(\%Alignment);
	print PART "Partition$i\t$fasta\t$partition\t$partition_i\n";
	$i++;
	$partition = $partition_i;
}

# Open the output filehandle
my $succout = open( OUT, ">", "$output" ) if $output ne "--";
my $fhout;
if ( $succout )		{	$fhout = *OUT;		}
else				{	$fhout = *STDOUT;	}

# Write the final output
my $nchar = get_longest_hash_value(\%Alignment);
foreach my $entry ( sort keys %Alignment )	{
	my $seq = $Alignment{$entry};
	my $endgaps = ( $nchar - length($Alignment{$entry}) > 0 )? sprintf("-" x ($nchar - length($Alignment{$entry}))) : '';
	my $sequence .= $Alignment{$entry} . $endgaps;
	$seq = $sequence;
	$seq =~ s/\s+//g;
	print $fhout ">$entry\n$seq\n";	
}
close $fhout if ( $succout );
close PART;
exit;

########################## SUBROUTINES  ##################################

# Get the longest VALUE in a hash
# Accepts a hash reference as input, returns the LENGTH of the longest value as an integer
sub get_longest_hash_value	{
	my ( $hash ) = @_;
	my %Hash = %{$hash};
	my $longest = (sort values %Hash)[0];
	
	foreach my $value ( values %Hash )	{
		$longest = length($longest) > length($value)? length($longest) : length($value);
	}
	return($longest);	# - 1
}

# Corrects lengthy fasta headers that are often generated by automatic programs -- ie. find_core_genome.pl // core_genome_reads.pl
# Returns a hash reference with corrected headers
sub fix_headers	{
	my $hash = shift;
	my %Hash = %{$hash};
	
	my %NewHash = ();
	foreach my $header ( sort keys %Hash )	{
		my $seq = $Hash{$header};
		my $new_header = $header;
		$new_header =~ s/\.fasta.*$//g;		
		$NewHash{$new_header} = $seq;
	}
	
	return \%NewHash;

}
