#!/usr/bin/perl -w
use warnings;
#Usage: 
#perl .pl <IN contig.fa> <IN min_length_of_contig> <IN number_of_threads> <IN path_to_bam_dir>
#this script needs metawrap env (conda cerate -n metawrap), metabat2 env (conda cerate -n metabat2), concoct env (conda cerate -n concoct), SemiBin env (conda cerate -n SemiBin), metabinner_env env (conda cerate -n metabinner_env), and comebin env (conda cerate -n comebin)
#make sure ~/MetaBinner is available

($assembly, $min_length, $cpu, $bam_dir) = @ARGV;
open OU2, ">./s3_run_binners";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";

#metabat2
print OU2 "conda activate metabat2\n";
print OU2 "echo \"########running metabat2########\"\n";
print OU2 "mkdir metabat2_1500\n";
print OU2 "jgi_summarize_bam_contig_depths --outputDepth metabat2_1500/depth.txt $bam_dir/\*sorted.bam \n";
print OU2 "metabat2 -i $assembly -a ./metabat2_1500/depth.txt -o ./metabat2_1500/bins/bin -t $cpu -m 1500\n";
print OU2 "rm ./metabat2_1500/bins/*txt \n";
print OU2 "echo \$(date) > ./metabat2_1500/done\n";
print OU2 "echo \"########metabat2 finished########\"\n";

#concoct
print OU2 "conda activate concoct\n";
print OU2 "echo \"########running concoct########\"\n";
print OU2 "mkdir concoct_$min_length\n";
print OU2 "cut_up_fasta.py $assembly -c 10000 -o 0 --merge_last -b concoct_$min_length/contigs_10k.bed > concoct_$min_length/contigs_10k.fa\n";
print OU2 "concoct_coverage_table.py concoct_$min_length/contigs_10k.bed $bam_dir/\*sorted.bam > concoct_$min_length/coverage_table.tsv \n";
print OU2 "concoct --coverage_file concoct_$min_length/coverage_table.tsv --composition_file concoct_$min_length/contigs_10k.fa -b concoct_$min_length/ -l $min_length -t $cpu\n";
print OU2 "merge_cutup_clustering.py concoct_$min_length/clustering_gt$min_length.csv > concoct_$min_length/clustering_merged.csv\n";
print OU2 "mkdir concoct_$min_length/bins\n";
print OU2 "extract_fasta_bins.py $assembly concoct_$min_length/clustering_merged.csv --output_path concoct_$min_length/bins\n";
print OU2 "echo \$(date) > ./concoct_$min_length/done\n";
print OU2 "echo \"########concoct finished########\"\n";

#SemiBin2
print OU2 "echo \"########running SemiBin2########\"\n";
print OU2 "conda activate SemiBin\n";
$cpu2 = int($cpu/2);
print OU2 "SemiBin2 single_easy_bin -i $assembly -b $bam_dir/\*sorted.bam -o SemiBin2_$min_length -m $min_length -t $cpu2\n";
print OU2 "gzip -d SemiBin2_$min_length/output_bins/*gz\n";
print OU2 "echo \$(date) > ./SemiBin2_$min_length/done\n";
print OU2 "echo \"########SemiBin2 finished########\"\n";

#MetaBinner
print OU2 "echo \"########running MetaBinner########\"\n";
print OU2 "conda activate metabinner_env\n";
print OU2 "mkdir MetaBinner_$min_length\n";
print OU2 "ln -s \$(readlink -f $assembly) ./MetaBinner_$min_length/metabinner_contigs.fa\n";
print OU2 "cd MetaBinner_$min_length\n";
print OU2 "cat ../metabat2_1500/depth.txt \| awk \'\{if \(\$2>$min_length\) print \$0 \}\' \| cut -f -1,4- > coverage_profile.tsv\n";
print OU2 "python ~/MetaBinner/scripts/gen_kmer.py metabinner_contigs.fa $min_length 4 \n";
print OU2 "bash \$(readlink -f ~/MetaBinner/run_metabinner.sh) -a \$(readlink -f metabinner_contigs.fa) -o \$(readlink -f ./) -d \$(readlink -f ./coverage_profile.tsv) -k \$(readlink -f ./metabinner_contigs_kmer_4_f$min_length.csv) -p \$(readlink -f ~/MetaBinner) -t $cpu \n";
print OU2 "python ~/MetaBinner/scripts/gen_bins_from_tsv.py -f metabinner_contigs.fa -r ./metabinner_res/metabinner_result.tsv -o ./bins \n";
print OU2 "cd ../\n";
print OU2 "echo \$(date) > ./MetaBinner_$min_length/done\n";
print OU2 "echo \"########MetaBinner finished########\"\n";

#COMEBin
print OU2 "echo \"########running COMEBin########\"\n";
print OU2 "conda activate comebin\n";
print OU2 "mkdir COMEBin_$min_length\n";
print OU2 "run_comebin.sh -a $assembly -o COMEBin_$min_length -p $bam_dir -t $cpu \n";
print OU2 "echo \$(date) > ./COMEBin_$min_length/done\n";
print OU2 "echo \"########COMEBin finished########\"\n";

#metawrap refinement
print OU2 "echo \"########running metawrap refinement########\"\n";
print OU2 "conda activate metawrap\n";
print OU2 "mkdir metawrap_refinement\n";
print OU2 "cd metawrap_refinement\n";
print OU2 "mkdir -p ../concoct_$min_length/bins/\n";
print OU2 "mkdir -p ../metabat2_1500/bins/\n";
print OU2 "metawrap bin_refinement -o round_1 -t $cpu -c 50 -A ../concoct_$min_length/bins/ -B ../metabat2_1500/bins/ \n";
print OU2 "mkdir -p round_1/metawrap_50_10_bins/ \n";
print OU2 "mkdir -p ../SemiBin2_$min_length/output_bins/ \n";
print OU2 "mkdir -p ../COMEBin_$min_length/comebin_res/comebin_res_bins/ \n";
print OU2 "mv round_1/metawrap_50_10_bins/ round_1/r1_metawrap_50_10_bins/ \n";
print OU2 "metawrap bin_refinement -o round_2 -t $cpu -c 50 -A ../SemiBin2_$min_length/output_bins/ -B ../COMEBin_$min_length/comebin_res/comebin_res_bins/ \n";
print OU2 "mkdir -p round_2/metawrap_50_10_bins/ \n";
print OU2 "mkdir -p ../MetaBinner_$min_length/bins/ \n";
print OU2 "mv round_2/metawrap_50_10_bins/ round_2/r2_metawrap_50_10_bins/ \n";
print OU2 "metawrap bin_refinement -o round_3_final -t $cpu -c 50 -A round_1/r1_metawrap_50_10_bins -B round_2/r2_metawrap_50_10_bins/ -C ../MetaBinner_$min_length/bins/ \n";
print OU2 "cd ../ \n";

system ("bash s3_run_binners");