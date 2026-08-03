MGBK (MetaGenomic Binning Kit)
=======

MGBK is a metagenomic binning pipeline that processes raw fastq data into refined bins, built on two benchmarks published in Nature Communications:
- `Kim, J., Kim, N., Cha, J. H., Ma, J., & Lee, I. (2026). Comprehensive benchmarking of metagenomic binning tools reveals key factors for improved genome recovery. Nature Communications, 17(1), 3467. https://doi.org/10.1038/s41467-026-71521-w`
- `Han, H., Wang, Z., & Zhu, S. (2025). Benchmarking metagenomic binning tools on real datasets across sequencing platforms and binning modes. Nature Communications, 16(1), 2865. https://doi.org/10.1038/s41467-025-57957-6`


Before binning, make sure you know the meaning of `Single-sample binning`, `Co-assembly binning`, and `Multi-sample binning`. You can briefly learn it from [SemiBin2 docs](https://semibin.readthedocs.io/en/latest/usage/).

Installation
---------------
Before installing MGBK, please ensure `miniconda` and `mamba` are properly installed in your local system.
- `latest miniconda` [https://www.anaconda.com/docs/getting-started/miniconda/install/](https://www.anaconda.com/docs/getting-started/miniconda/install/)
- `latest mamba` [https://anaconda.org/channels/conda-forge/packages/mamba/overview](https://anaconda.org/channels/conda-forge/packages/mamba/overview)

```sh
#if you are using old Linux system, you can try old-version conda
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-x86_64.sh
#type 'yes' twice
sh Miniconda3-py310_23.10.0-1-Linux-x86_64.sh

#if you are using old Linux system, you can try old-version mamba
conda install conda-forge::mamba=1.5.6 -y
```

Create conda environments for MGBK.
```sh
conda update conda -y
conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels ursky
conda config --set channel_priority flexible

# install trimmomatic env
mamba create -n trimmomatic trimmomatic=0.39 -y

# install megahit env
mamba create -n megahit -c bioconda megahit -y

# install seqkit
mamba create -n seqkit -c bioconda seqkit -y

# install minibwa
mamba create -n minibwa minibwa -y

# install samtools
# metabat2 was also installed in this env for the command 'jgi_summarize_bam_contig_depths'
mamba create -n samtools -c bioconda metabat2 samtools -y

# install metawrap (simplified)
# This metawrap env is only used for bin_refinement
cd ~
git clone https://github.com/bxlab/metaWRAP.git
# add ~/metaWRAP/bin to environment variable
echo 'export PATH=~/metaWRAP/bin/:$PATH' >> ~/.bashrc
source ~/.bashrc
mamba create -y -n metawrap python=2.7
conda activate metawrap
mamba install biopython=1.68 bioconda::checkm-genome=1.0.18 -y
cd ~/metaWRAP/
# manually download checkm database:
mkdir MY_CHECKM_FOLDER
cd MY_CHECKM_FOLDER
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xvf *.tar.gz
rm *.gz
echo $(readlink -f ~/metaWRAP/MY_CHECKM_FOLDER/) #check path
checkm data setRoot $(readlink -f ~/metaWRAP/MY_CHECKM_FOLDER/)
conda deactivate

# install metabat2
mamba create -n metabat2 -c bioconda metabat2 -y

# install concoct
mamba create -n concoct -c bioconda concoct -y

# install SemiBin2
mamba create -n SemiBin -c conda-forge -c bioconda semibin -y

# install MetaBinner
cd ~
git clone https://github.com/ziyewang/MetaBinner.git
cd MetaBinner
mamba env create -f metabinner_env.yaml -y

# install COMEBin (cpu version)
mamba create -n comebin -c conda-forge -c bioconda comebin -y
conda activate comebin
# remember to set your checkm database
checkm data setRoot $(readlink -f ~/metaWRAP/MY_CHECKM_FOLDER/)
conda deactivate

# install drep
conda create -n drep -y
conda activate drep
mamba install bioconda::drep -y
# remember to set your checkm database
checkm data setRoot $(readlink -f ~/metaWRAP/MY_CHECKM_FOLDER/)
conda deactivate

# install checkm2
conda create -n checkm2 -y
conda activate checkm2
mamba install bioconda::checkm2 -y
checkm2 database --download --path /path/to/your/checkm2_db/
conda deactivate

# install gunc
conda create -n gunc -y
conda activate gunc
mamba install -c bioconda gunc -y
# Download GUNC DB
mkdir -p /path/to/your/gunc_db/progenomes3/
gunc download_db /path/to/your/gunc_db/progenomes3/ -db progenomes_3
conda deactivate
```

Download or clone the MGBK repository
```sh
cd ~
git clone https://github.com/jchenek/MGBK.git
```

Users' Guide
---------------
Before starting this tutorial, please [download](https://figshare.com/articles/online_resource/example_NGS_metaG_fq/33101945) the example NGS dataset from Figshare.


Move the downloaded file `33101945.zip` to the ~/MGBK_example directory.

```sh
cd ~
mkdir MGBK_example
cd MGBK_example
# move the the file '33101945.zip' to ~/MGBK_example
# you will see dir 'example_NGS_metaG_fq_from_cold_seep' after unzip
unzip 33101945.zip
cd example_NGS_metaG_fq_from_cold_seep/
# prepare a fq_list file for further analysis
perl ~/MGBK/scripts/get_fq_list_from_gz.pl
```
`fq_list`: This is a tsv file that looks like this: "A_id`\t`A_PATH_1.fq`\t`A_PATH_2.fq`\n`B_id`\t`B_PATH_1.fq`\t`B_PATH_2.fq`\n`C_id`\t`C_PATH_1.fq`\t`C_PATH_2.fq`\n`". You can obtain this file using ~/MGBK/scripts/get_fq_list_from_gz.pl or create one using any text editor you like.


`~/MGBK/scripts/get_fq_list_from_gz.pl`: This script will detect all files under the current path, extract those ending with "gz", and create a fq_list.

Step 1. trim and assembly
---------------
We use trimmomatic and megahit to trim and assemble short-read metagenomic data, respectively. (Scripts for long sequencing & NGS hybrid assembly are coming soon)

- `coassembly binning` Run 's1_coassembly_binning_NGS_trim_and_coassembly.pl' to trim and assemble.
- `$cpu`: number of threads
- `$fq_list`: the fq_list of raw data
```sh
# step 1 of coassembly binning
cd ~/MGBK_example
mkdir coassembly_binning
cd coassembly_binning
# usage: perl ~/MGBK/s1_coassembly_binning_NGS_trim_and_coassembly.pl $cpu $fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
perl ~/MGBK/s1_coassembly_binning_NGS_trim_and_coassembly.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
```


- `multiple binning` First, run 's1_multisample_binning_1_NGS_trim.pl' to trim all metaG data. Then, edit the TSV file 'multisample_binning_assembly_design' and run 's1_multisample_binning_2_NGS_assembly.pl'
```sh
# step 1 of multisample binning
cd ~/MGBK_example
mkdir multisample_binning
cd multisample_binning
# usage: perl ~/MGBK/s1_multisample_binning_1_NGS_trim.pl $cpu $fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
perl ~/MGBK/s1_multisample_binning_1_NGS_trim.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
# usage: perl ~/MGBK/s1_multisample_binning_2_NGS_assembly.pl $cpu multisample_binning_assembly_design
cp ~/MGBK/multisample_binning_assembly_design ./
perl ~/MGBK/s1_multisample_binning_2_NGS_assembly.pl 80 multisample_binning_assembly_design
```

`multisample_binning_assembly_design` tells the scripts how many assemblies to be generated using which fastq file(s). For each assembly, it can be constructed from a single sample or multiple samples (concatenated). This tsv file looks like this:


"Name_of_single_assembly_1.fastq.gz`\t`path_to_raw_1.fastq.gz`\t`Name_of_single_assembly_2.fastq.gz`\t`path_to_raw_2.fastq.gz`\n`" # Here one `assembly` called 'Name_of_single_assembly' will be generated using the PE reads 'path_to_raw_1.fastq.gz' and 'path_to_raw_2.fastq.gz'


"Name_of_multiple_assembly_1.fastq.gz`\t`path_to_raw1_1.fastq.gz` `path_to_raw2_1.fastq.gz` `path_to_raw3_1.fastq.gz`\t`Name_of_multiple_assembly_2.fastq.gz`\t`path_to_raw1_2.fastq.gz` `path_to_raw2_2.fastq.gz` `path_to_raw3_2.fastq.gz`\n`" # Here one `co-assembly` called 'Name_of_single_assembly' will be generated using the concatenated PE reads 'path_to_raw_1.fastq.gz & path_to_raw2_1.fastq.gz & path_to_raw3_1.fastq.gz' and 'path_to_raw1_2.fastq.gz & path_to_raw2_2.fastq.gz & path_to_raw3_2.fastq.gz'.


An example of the `multisample_binning_assembly_design` file can be found in `~/MGBK/multisample_binning_assembly_design`.

Step 2. alignment
---------------
We use minibwa to align short reads against reference genomes.

- `coassembly binning` Run 's2_coassembly_binning_align_fq_for_bam_and_depth.pl' to align trimmed fq against the co-assembled genome.
- `$assembly`: the co-assembled genome from step1
- `$min_length`: the minimum length of contig for binning
- `$fq_list_trim`: the fq_list of clean data from step1
```sh
# step 2 of coassembly binning
cd ~/MGBK_example/coassembly_binning
mkdir s2_alignment
cd s2_alignment
# usage: perl ~/MGBK/s2_coassembly_binning_align_fq_for_bam_and_depth.pl $assembly $min_length $cpu $fq_list_trim
perl ~/MGBK/s2_coassembly_binning_align_fq_for_bam_and_depth.pl ~/MGBK_example/coassembly_binning/s1_coassembly/final.contigs.fa 1500 80 ~/MGBK_example/coassembly_binning/fq_list_trim
```


- `multisample binning` Run 's2_multisample_binning_align_fq_for_bam_and_depth.pl' to align all trimmed fq against all assemblies.
```sh
# step 2 of multisample binning
# MUST be run in the same path as 's1_multisample_binning_2_assembly_PE_megahit.pl'
cd ~/MGBK_example/multisample_binning
# usage: perl ~/MGBK/s2_multisample_binning_align_fq_for_bam_and_depth.pl multisample_binning_assembly_design $min_length $cpu $fq_list_trim
# this script will detect s1_assemblies_res dir and map clean read to each assemblies
# assembly_design used here is the same as the one used for 's1_multisample_binning_2_assembly_PE_megahit.pl'
perl ~/MGBK/s2_multisample_binning_align_fq_for_bam_and_depth.pl multisample_binning_assembly_design 1500 80 fq_list_trim
```

-----
### Step 3. binning
Based on the two benchmarks, binny and COMEBin consistently performed very well. However, due to installation issues with binny and to facilitate running this pipeline across multiple platforms, I will not include binny in my pipeline.


In MGBK, 5 `binning softwares` are included, classified into 4 categories based on their algorithms (Kim et al., 2026):

- `Projection-based integration`: CONCOCT
- `Probabilistic Modeling`: MetaBAT2
- `Neural Networks`: COMEBin, SemiBin2
- `Ensembled-based integration`: MetaBinner


Since COMEBin takes an extremely long time to run, a "no-COMEBin" version is provided as an alternative.


For `refinement`, there are 3 options available: metaWRAP, MAGScoT, and DASTool. Although metaWRAP takes the longest time and consumes the most resources, it yields genomes with lower contamination and fewer chimeric genomes (Kim et at., 2026). Therefore, I use metaWRAP for refinement in MGBK.


metaWRAP can only refine 3 d of bins at a time, I split the 5 sets of bins and run metaWRAP 3 times in total:


`r1`: CONCOCT, MetaBAT2; `r2`: COMEBin, SemiBin2; `r3`: r1, r2, MetaBinner


If without COMEBin, I split the 4 sets of bins and run metaWRAP 2 times in total:


`r1`: CONCOCT, MetaBAT2; `r2`: r1, SemiBin2, MetaBinner



- `coassembly binning` Run 's3_coassembly_binning_run_binners_full.pl' or 's3_coassembly_binning_run_binners_no_comebin.pl'.
- `$binning_PE_assembly_$min_length.fa`: the reformated and trimmed assembly from step2
- `$min_length`: the minimum length of contig for binning (the same as step2)
- `$s2_alignment_dir`: the dir where bam files are stored (output of step2)
```sh
# step 3 of coassembly binning
cd ~/MGBK_example/coassembly_binning
mkdir s3_binning
cd s3_binning
# usage: perl ~/MGBK/s3_coassembly_binning_run_binners_full.pl $binning_PE_assembly_$min_length.fa $min_length $cpu $s2_alignment_dir
perl ~/MGBK/s3_coassembly_binning_run_binners_full.pl ~/MGBK_example/coassembly_binning/s2_alignment/binning_PE_assembly_1500.fa 1500 80 ~/MGBK_example/coassembly_binning/s2_alignment/
```


- `multisample binning` Run 's3_multisample_binning_run_binners_full.pl' or 's3_multisample_binning_run_binners_no_comebin.pl'.
```sh
# step 2 of multisample binning
# MUST be run in the same path as 's1_multisample_binning_2_assembly_PE_megahit.pl'
cd ~/MGBK_example/multisample_binning
# usage: perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design $min_length $cpu
# this script will detect s1_assemblies_res dir and bams files (from s2_multisample_binning_align_fq_for_bam_and_depth.pl) in the sub dirs
# assembly_design used here is the same as the one used for 's1_multisample_binning_2_assembly_PE_megahit.pl'
perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design 1500 80
```

-----
### Step 4. genome dereplication (only for multisample_binning)
In multisample_binning, we will get a number of refined bins from each assembly. Many of the bins from different assemblies can be the same strain (ANI > 98%). We use drep to conduct Bin dereplication.

- `multisample binning` Run 's4_multisample_binning_derep_bins.pl' to dereplicate  bins from different assemblies.
```sh
# step 4 of multisample binning
# MUST be run in the same path as 's1_multisample_binning_2_assembly_PE_megahit.pl'
cd ~/MGBK_example/multisample_binning
# usage: perl ~/MGBK/s4_multisample_binning_derep_bins.pl multisample_binning_assembly_design $cpu
# this script will detect s1_assemblies_res dir and metawrap_50_10_bins from step3 binning
# assembly_design used here is the same as the one used for 's1_multisample_binning_2_assembly_PE_megahit.pl'
perl ~/MGBK/s4_multisample_binning_derep_bins.pl multisample_binning_assembly_design 80
```

-----
### Step 5. check bin quality
We use checkm2 and gunc to check the quality of bins. Check the results in `s5_checkm2_out/quality_report.tsv` and `s5_gunc_out/GUNC.progenomes_3.maxCSS_level.tsv`.


A good bin should be: `Completeness > 90% & Contamination < 5%` based on checkm2 and `clade_separation_score (CSS) < 0.45 & reference_representation_score (RRS) > 0.5` based on gunc.

- `coassembly binning` Run 's5_check_bins.pl'
- `$final_bin_dir`: the final bin dir; for 'coassembly binning', this dir is '/path/to/metawrap_refinement/round_final/metawrap_50_10_bins'
- `$checkm2_db.dmnd`: path to your checkm2 dmnd database
- `$gunc_db.dmnd`: path to your gunc dmnd database
```sh
# step 5 of coassembly binning
cd coassembly_binning/s3_binning/metawrap_refinement/round_2_final
# usage: perl ~/MGBK/s5_check_bins.pl $final_bin_dir $cpu $checkm2_db.dmnd $gunc_db.dmnd
perl ~/MGBK/s5_check_bins.pl metawrap_50_10_bins 80 ~/checkm2_db/CheckM2_database/uniref100.KO.1.dmnd ~/gunc_db/progenomes3/gunc_db_progenomes3.dmnd
```
- `multisample binning` Run 's5_check_bins.pl'
- `$final_bin_dir`: the final bin dir; for 'multisample binning', this dir is '/path/to/s4_derep/drep_output/dereplicated_genomes'
```sh
# step 5 of multisample binning
cd ~/MGBK_example/multisample_binning/s4_derep/drep_output
# usage: perl ~/MGBK/s5_check_bins.pl $final_bin_dir $cpu $checkm2_db.dmnd $gunc_db.dmnd
perl ~/MGBK/s5_check_bins.pl metawrap_50_10_bins 80 ~/checkm2_db/CheckM2_database/uniref100.KO.1.dmnd ~/gunc_db/progenomes3/gunc_db_progenomes3.dmnd
```

Citation
---------------
If you feel MGBK is helpful, please cite the URL: https://github.com/jchenek/MGBK in your publication(s).