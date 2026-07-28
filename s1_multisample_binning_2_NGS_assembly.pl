#!/usr/bin/perl -w
use warnings;
#Usage: 
#perl .pl <IN number_of_threads> <IN assembly_design>
#README:
#assembly_design looks like this:
#A_1.fastq.gz\tS1_1.fastq.gz S2_1.fastq.gz S3_1.fastq.gz\tA_2.fastq.gz\tS1_2.fastq.gz S2_2.fastq.gz S3_2.fastq.gz\n
#B_1.fastq.gz\tS4_1.fastq.gz S5_1.fastq.gz S6_1.fastq.gz\tB_2.fastq.gz\tS4_2.fastq.gz S5_2.fastq.gz S6_2.fastq.gz\n
#please not that the files should be ended by _[12].fastq.gz
#this script needs megahit env (conda create -n megahit)

($cpu, $assembly_design) = @ARGV;

open OU2, ">./s1.2_NGS_assembly";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";
print OU2 "mkdir s1_assemblies_fq\n";
print OU2 "mkdir s1_assemblies_res\n";
print OU2 "conda activate megahit\n";

open IN2, "$assembly_design";
while(<IN2>){
	chomp;
	$fq1 = (split /\t/,$_)[0];
	$fqs1 = (split /\t/,$_)[1];
	$fq2 = (split /\t/,$_)[2];
	$fqs2 = (split /\t/,$_)[3];
	$name = $fq1;
	$name =~ s/_1.fastq.gz$//;
	print OU2 "echo \"########merging $fqs1 > $fq1########\"\n";
	print OU2 "echo \"########merging $fqs2 > $fq2########\"\n";
	print OU2 "cat $fqs1 > s1_assemblies_fq/$fq1 &\n";
	print OU2 "cat $fqs2 > s1_assemblies_fq/$fq2 &\n";
	print OU2 "wait\n";
	print OU2 "echo \"########running $name megahit########\"\n";
	print OU2 "megahit -1 s1_assemblies_fq/$fq1 -2 s1_assemblies_fq/$fq2 --k-min 27 --k-max 147 --k-step 12 -t $cpu -o s1_assemblies_res/$name\_assembly\n";
}
close IN2;
close OU2;

system ("bash s1.2_NGS_assembly");

