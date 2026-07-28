#!/usr/bin/perl -w
use warnings;
#Usage: 
#perl .pl <IN .fa> <IN min_contig_length> <IN number_of_threads> <IN a_txt_containning_path_of_PE_fq>
#README:
#the list of path looks like this (default three fq input):
#"A_id\tA_PATH_1.fq\tA_PATH_2.fq\nB_id\tB_PATH_1.fq\tB_PATH_2.fq\nC_id\tC_PATH_1.fq\tC_PATH_2.fq\n"
#this script needs seqkit env (conda cerate -n seqkit), minibwa env (conda cerate -n minibwa), and samtools env (conda cerate -n samtools)

($assembly, $min_len, $cpu, $fq_list) = @ARGV;

#reformating assembly
print "reformating assembly ...\n";
open IN, "$assembly";
open OU1, ">./tem.reformated";
while(<IN>){
	s/\r//g;
	chomp;
	if(m/>/){
	s/>//;
	my$ID = (split /\s+/,$_)[0];
	print OU1 ">$ID";
	print OU1 "cjwfengecjw\n";
	}else{
	s/ //g;
	print OU1 "$_\n";
	}
}
close IN;
close OU1;

open IN, "./tem.reformated";
open OU1, ">./binning_PE_assembly.fa";
open OU2, ">./binning_PE_assembly.id";
$/=">";<IN>;
while (<IN>) {
	chomp;
	s/\n//g;
	$id=(split /cjwfengecjw/,$_)[0];
	$seq=(split /cjwfengecjw/,$_)[1];
	print OU1 ">$id\n$seq\n";
	print OU2 "$id\n";
}
unlink './tem.reformated';
$/="\n";<IN>;
close IN;
close OU1;
print "finish reformating\n";

open OU2, ">./s2_mapping";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";

#length trimming
print OU2 "echo \"########seqkit module########\"\n";
print OU2 "echo \"########only keep length > $min_len contigs########\"\n";
print OU2 "conda activate seqkit\n";
print OU2 "seqkit seq -m $min_len binning_PE_assembly.fa > binning_PE_assembly_$min_len\.fa\n";


#minibwa module
print OU2 "echo \"########minibwa module########\"\n";
print OU2 "echo \"########running minibwa index########\"\n";
print OU2 "conda activate minibwa\n";
print OU2 "minibwa index -t $cpu binning_PE_assembly_$min_len\.fa\n";

open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "echo \"########running $id alignment########\"\n";
	print OU2 "minibwa map -t $cpu binning_PE_assembly_$min_len\.fa $PE1 $PE2 -o $id.sam\n";
}
close IN2;

#samtools module
$com_num = 1;
print OU2 "echo \"########samtools module########\"\n";
print OU2 "echo \"########making bam files########\"\n";
print OU2 "conda activate samtools\n";
open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "samtools view -b -S $id.sam > $id.bam &\n";
	$com_num = $com_num + 1;
	if($com_num > 5){
		print OU2 "wait\n";
		$com_num = 1;
	}
}
print OU2 "wait\n";
close IN2;

$com_num = 1;
print OU2 "echo \"########removing needless original sam files########\"\n";
open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "rm $id.sam &\n";
	$com_num = $com_num + 1;
	if($com_num > 5){
		print OU2 "wait\n";
		$com_num = 1;
	}
}
print OU2 "wait\n";
close IN2;

$com_num = 1;
print OU2 "echo \"########sorting bam files########\"\n";
open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "samtools sort --thread $cpu $id.bam > $id.sorted.bam &\n";
	$com_num = $com_num + 1;
	if($com_num > 5){
		print OU2 "wait\n";
		$com_num = 1;
	}
}
print OU2 "wait\n";
close IN2;

$com_num = 1;
print OU2 "echo \"########removing needless original bam files########\"\n";
open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "rm $id.bam &\n";
	$com_num = $com_num + 1;
	if($com_num > 5){
		print OU2 "wait\n";
		$com_num = 1;
	}
}
print OU2 "wait\n";
close IN2;

$com_num = 1;
print OU2 "echo \"########indexing bam files and counting coverage########\"\n";
open IN2, "$fq_list";
while(<IN2>){
	chomp();
	$id = (split /\t/,$_)[0];
	$PE1 = (split /\t/,$_)[1];
	$PE2 = (split /\t/,$_)[2];
	print OU2 "samtools index $id.sorted.bam $id.sorted.bai &\n";
	$com_num = $com_num + 1;
	if($com_num > 5){
		print OU2 "wait\n";
		$com_num = 1;
	}
}
print OU2 "wait\n";

#get depth file
print OU2 "jgi_summarize_bam_contig_depths --outputDepth depth.txt ./\*sorted.bam \n";

close IN2;

system ("bash s2_mapping");