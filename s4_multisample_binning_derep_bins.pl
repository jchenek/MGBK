#!/usr/bin/perl -w
use warnings;
#Usage:
#run this scripts in the same path with s1_multisample_binning_2_assembly_PE_megahit.pl
#this scripts will detect s1_assemblies_res dir and metawrap refined bins (from s3_multisample_binning_run_binners.pl) in the sub dirs
#perl .pl <IN assembly_design (same with s1_multisample_binning_2_assembly_PE_megahit.pl)> <IN number_of_threads>
#this script needs drep env (conda cerate -n drep)

($assembly_design, $cpu) = @ARGV;

open IN3, "$assembly_design";
while(<IN3>){
chomp;
$fq1 = (split /\t/,$_)[0];
$name = $fq1;
$name =~ s/_1.fastq.gz$//;

#go to final bins, rename, and copy
chdir("./s1_assemblies_res/$name\_assembly/s3_binning") or die "cannot detect ./s1_assemblies_res/$name\_assembly dir: $!";

$dir = "./metawrap_refinement/round_final/metawrap_50_10_bins";
system("mkdir s4_drep");
system("mkdir -p s4_drep/all_bins");
system("mkdir -p s3_binning/metawrap_refinement/round_final/metawrap_50_10_bins");

my$DIR_PATH = $dir;
opendir DIR, ${DIR_PATH} or die "can not open dir \"$DIR_PATH\"\n";
my@filelist = readdir DIR;

foreach my$file (@filelist) {
	if($file =~ m/.fa/){
	system("cp $dir/$file ./s4_drep/all_bins/$name\_$file");
	}
}

#go back
chdir("../../../") or die "cannot go back: $!";
}
close IN3;

#go to s3_binning
chdir("./s1_assemblies_res/$name\_assembly/s3_binning/") or die "cannot detect ./s1_assemblies_res/$name\_assembly dir: $!";

open OU2, ">./s4_drep_bins";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";
print OU2 "conda activate drep\n";
print OU2 "echo \"########running drep########\"\n";
print OU2 "cd s4_drep\n";
print OU2 "dRep dereplicate drep_output -p $cpu -comp 50 -con 10 --P_ani 0.9 --S_ani 0.98 -nc 0.75 -g all_bins/*.fa \n";
print OU2 "cd ../ \n";
system ("bash s4_drep_bins");

#go back
chdir("../../../") or die "cannot go back: $!";