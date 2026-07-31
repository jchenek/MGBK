#!/usr/bin/perl -w
use warnings;
#Usage:
#perl .pl <IN bin_dir> <IN number_of_threads> <IN path_to_GUNC_dmnd>
#this script needs checkm2 env (conda cerate -n checkm2) and gunc env (conda cerate -n gunc)

($dir, $cpu, $db) = @ARGV;

open OU2, ">./s5_check_bin_quality";
print OU2 "#!/bin/bash\n";
print OU2 "source ~/miniconda3/etc/profile.d/conda.sh\n";

#checkm2
print OU2 "conda activate checkm2 \n";
print OU2 "echo \"########running checkm2########\"\n";
print OU2 "checkm2 predict --threads $cpu --input $dir -x fa --output-directory s5_checkm2_out/ \n";

#gunc
print OU2 "conda activate gunc \n";
print OU2 "echo \"########running gunc########\"\n";
print OU2 "gunc run -t $cpu --input_dir $dir --db_file $db -o s5_gunc_out \n";

system ("bash s5_check_bin_quality");
