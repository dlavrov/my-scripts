#!/usr/bin/perl

use strict;
use warnings;
use Bio::SeqIO;

foreach my $file (@ARGV){
	my $io = Bio::SeqIO->new(-file => $file, -format => 'fasta');
	
	my $count = 0;
	my @lens;
	my $size = 0;
	while(my $seq = $io->next_seq){
		$count++;
		my $len = $seq->length;
		push @lens, $len;
		$size += $len;
	}
	
	my $runningTotal = 0;
	my $N50 = 0;
	foreach my $len (sort {$a <=> $b} @lens){
		$N50 = $len;
		$runningTotal += $len;
		last if $runningTotal > $size/2;
	}
	
	print "$N50";
}
