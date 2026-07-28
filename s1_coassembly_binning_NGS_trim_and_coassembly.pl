#!/usr/bin/perl -w
use warnings;
#Usage: 
#perl .pl <IN number_of_threads> <IN a_txt_containning_path_of_PE_fq> <IN ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa>
#README:
#the list of path looks like this (default three fq input):
#"A_id\tA_PATH_1.fq\tA_PATH_2.fq\nB_id\tB_PATH_1.fq\tB_PATH_2.fq\nC_id\tC_PATH_1.fq\tC_PATH_2.fq\n"
#this script needs trimmomatic env (conda create -n trimmomatic) and megahit env (conda create -n megahit)

($cpu, $fq_list, $adaptor) = @ARGV;

#trimmomatic module
open OU2, ">./s1_trim_and_coassembly";
open OU1, ">./fq_list_trim";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";
print OU2 "echo \"########trimmomatic module########\"\n";
print OU2 "conda activate trimmomatic\n";
print OU2 "mkdir s1_trim_fq\n";

$curr_path = $ENV{'PWD'};
open IN2, "$fq_list";
while(<IN2>){
	chomp;
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU1 "$id\_trim\t$curr_path\/s1_trim_fq/$id\_1.fastq.gz\t$curr_path\/s1_trim_fq/$id\_2.fastq.gz\n";
	print OU2 "trimmomatic PE -threads $cpu -phred33 $PE1 $PE2 -baseout s1_trim_fq/$id ILLUMINACLIP:$adaptor:2:30:10 LEADING:10 TRAILING:10 SLIDINGWINDOW:4:20 MINLEN:50 TOPHRED33\n";
	print OU2 "mv $curr_path\/s1_trim_fq/$id\_1P $curr_path\/s1_trim_fq/$id\_1.fastq\n";
	print OU2 "mv $curr_path\/s1_trim_fq/$id\_2P $curr_path\/s1_trim_fq/$id\_2.fastq\n";
	print OU2 "rm $curr_path\/s1_trim_fq/$id\_[12]U\n";
}
close IN2;

#megahit module
print OU2 "echo \"########coassembly module########\"\n";
print OU2 "conda activate megahit\n";
print OU2 "echo \"########merging fq########\"\n";
print OU2 "cat s1_trim_fq/*_1.fastq > s1_trim_fq/merged_1.fq &\n";
print OU2 "cat s1_trim_fq/*_2.fastq > s1_trim_fq/merged_2.fq &\n";
print OU2 "wait\n";
print OU2 "echo \"########running megahit########\"\n";
print OU2 "megahit -1 s1_trim_fq/merged_1.fq -2 s1_trim_fq/merged_2.fq --k-min 27 --k-max 147 --k-step 12 -t $cpu -o s1_coassembly\n";

#gzip module
print OU2 "echo \"########gzip module########\"\n";
print OU2 "gzip s1_trim_fq/*\n";

close OU1;
close OU2;

system ("bash s1_trim_and_coassembly");

