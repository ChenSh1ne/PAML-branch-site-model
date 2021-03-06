#!/usr/bin/perl -w
use strict;

#用法：perl 程序.pl all.pep.fasta all.cds.fasta 1_1_1_group_sorted.txt
#读所有物种的序列；
# yexinhai, yexinhai@zju.edu.cn;

sub Usage(){
	print STDERR "
	positive_selection_codeml.pl <all.pep.fasta> <all.cds.fasta> <1_1_1_group_sorted.txt>
	\n";
	exit(1);
}
&Usage() unless $#ARGV==2;


my $genename;
my %hash_1;

open my $fasta1, "<", $ARGV[0] or die "Can't open file!";
while (<$fasta1>) {
	chomp();
	if (/^>(.*)$/){
		$genename = $1;
	} else {
		$hash_1{$genename} .= $_;
	}
}
close $fasta1;

my $cds_id;
my %hash_cds;

open my $fasta2, "<", $ARGV[1] or die "Can't open cds file!\n";
while (<$fasta2>) {
	chomp();
	if (/^>(\S+)/) {
		$cds_id = $1;
	} else {
		$hash_cds{$cds_id} .= $_;
	}
}
close $fasta2;

`mkdir paml_result`;

open my $Group, "<", $ARGV[2] or die "Cant't open group file!";
while (<$Group>) {
	chomp();
	my @array1 = split /\t/, $_;
	my $group_nogood = shift @array1;
	my @array2 = split /:/, $group_nogood;
	my $group = $array2[0];
	`mkdir $group`;
	open OUT1, ">","$group\.pep.fasta";
	foreach (@array1) {
		print OUT1 ">".$_."\n".$hash_1{$_}."\n";
	}
	close OUT1;
	open OUT2, ">","$group\.cds.fasta";
	foreach (@array1) {
		print OUT2 ">".$_."\n".$hash_cds{$_}."\n";
	}
	close OUT2;
	`mv $group\.pep.fasta $group`;
	`mv $group\.cds.fasta $group`;
	`mafft --auto $group/$group\.pep.fasta >$group\/$group\.pep.mafft.fasta`;
	`mkdir $group\/for_paml`;
	`perl ../pal2nal.pl $group\/$group\.pep.mafft.fasta $group\/$group\.cds.fasta -output paml -nogap >$group\/for_paml/test.codon`;
	open my $codon_ala, "<", "$group\/for_paml/test.codon" or die "can't open test.codon in $group !\n";
	open OUT3, ">", "$group\/for_paml/test.codon.changename";
	while (<$codon_ala>) {
		chomp();
		if (/^(\w+)\|.*/) {
			print OUT3 $1."\n";
		} else {
			print OUT3 $_."\n";
		}
	}
	close $codon_ala;
	close OUT3;
	`cp ..\/faw.tree $group\/for_paml`;
	`mkdir $group\/for_paml\/null`;
	`cp ..\/Null.ctl $group\/for_paml\/null`;
	`mkdir $group\/for_paml\/alter`;
	`cp ..\/Alter.ctl $group\/for_paml\/alter`;
	chdir "$group\/for_paml\/null";
	print "$group\:Start PAML for Null!\n";
	`codeml Null.ctl`;
	print "$group\:PAML for Null DONE!\n";
	open my $null_mlc, "<", "mlc" or die "can't open null mlc file in $group !\n";
	open OUT4, ">", "$group\.null.result";
	while (<$null_mlc>) {
		chomp();
		if (/^lnL.*np:\s(\d+)\):\s+(\S+).*/) {
			print OUT4 $group."\t".$1."\t".$2."\t";
		} 
	}
	close OUT4;
	`cp $group\.null.result ..\/..\/..\/paml_result`;
	chdir "..\/alter";
	print "$group\:Start PAML for Alter!\n";
	`codeml Alter.ctl`;
	print "$group\:PAML for Alter DONE!\n";
	open my $alter_mlc, "<", "mlc" or die "can't open alter mlc file in $group!\n";
	open OUT5, ">", "$group\.alter.result";
	while (<$alter_mlc>) {
		chomp();
		if (/^lnL.*np:\s(\d+)\):\s+(\S+).*/) {
			print OUT5 $group."\t".$1."\t".$2."\n";
		} 
	}
	close OUT5;
	`cp $group\.alter.result ..\/..\/..\/paml_result`;
	print "where is next!?\n";
	chdir "..\/..\/..\/";
}
close $Group;




