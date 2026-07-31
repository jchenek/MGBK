MGBK (MetaGenomic Binning Kit)
=======

MGBK is a metagenomic binning pipeline that processes raw fastq data into refined bins, built on two benchmarks published in Nature Communications.
- `Kim, J., Kim, N., Cha, J. H., Ma, J., & Lee, I. (2026). Comprehensive benchmarking of metagenomic binning tools reveals key factors for improved genome recovery. Nature Communications, 17(1), 3467. https://doi.org/10.1038/s41467-026-71521-w`
- `Han, H., Wang, Z., & Zhu, S. (2025). Benchmarking metagenomic binning tools on real datasets across sequencing platforms and binning modes. Nature Communications, 16(1), 2865. https://doi.org/10.1038/s41467-025-57957-6`

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

# install drep
conda create -n drep -y
conda activate drep
mamba install bioconda::drep -y
# remember to set your checkm database
checkm data setRoot /path/to/your/miniconda3/envs/drep/checkm_data
conda deactivate

# install checkm2
mamba create -n checkm2 -c bioconda -c conda-forge checkm2 -y

# install gunc
conda create -n gunc -y
conda activate gunc
mamba install -c bioconda gunc -y
#Download GUNC DB
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
`fq_list`: This is a tsv file that looks like this: "A_id\tA_PATH_1.fq\tA_PATH_2.fq\nB_id\tB_PATH_1.fq\tB_PATH_2.fq\nC_id\tC_PATH_1.fq\tC_PATH_2.fq\n". You can get this file by ~/MGBK/scripts/get_fq_list_from_gz.pl or make one using any text editor you like.


`~/MGBK/scripts/get_fq_list_from_gz.pl`: This perl scripts will detect all files under current path, extract those ended with "gz", and create a fq_list.

Step 1. trim and assembly
---------------
For NGS metaG data, we use trimmomatic for trimming and megahit for assembly.


For `coassembly binning`, run 's1_coassembly_binning_trim_and_coassembly_PE_megahit.pl' to trim and assemble.
```sh
cd ~/MGBK_example
mkdir coassembly_binning
cd coassembly_binning
#perl ~/MGBK/s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl $cpu $fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
perl ~/MGBK/s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
```


For `multiple binning`, first run 's1_multisample_binning_1_NGS_trim.pl' to trim all fastq; then edit a tsv file `assembly_design` and run 's1_multisample_binning_2_NGS_assembly.pl'.


`assembly_design` tells the scripts how many assemblies to be generated using which fastq file(s). For each assembly, it can be assembled from one sample or many samples (concatenated). This tsv file looks like this:


"Name_of_single_assembly_1.fastq.gz`\t`path_to_raw_1.fastq.gz`\t`Name_of_single_assembly_2.fastq.gz`\t`path_to_raw_2.fastq.gz`\n`"


Here one `assembly` called 'Name_of_single_assembly' will be generated using the PE reads 'path_to_raw_1.fastq.gz' and 'path_to_raw_2.fastq.gz'


"Name_of_multiple_assembly_1.fastq.gz`\t`path_to_raw1_1.fastq.gz` `path_to_raw2_1.fastq.gz` `path_to_raw3_1.fastq.gz`\t`Name_of_multiple_assembly_2.fastq.gz`\t`path_to_raw1_2.fastq.gz` `path_to_raw2_2.fastq.gz` `path_to_raw3_2.fastq.gz`\n`"


Here one `co-assembly` called 'Name_of_single_assembly' will be generated using the concatenated PE reads 'path_to_raw_1.fastq.gz & path_to_raw2_1.fastq.gz & path_to_raw3_1.fastq.gz' and 'path_to_raw1_2.fastq.gz & path_to_raw2_2.fastq.gz & path_to_raw3_2.fastq.gz'.



```sh
cd ~/MGBK_example
mkdir multisample_binning
cd multisample_binning
#perl ~/MGBK/s1_multisample_binning_1_NGS_trim.pl $cpu ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
perl ~/MGBK/s1_multisample_binning_1_NGS_trim.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
#perl ~/MGBK/s1_multisample_binning_2_NGS_assembly.pl $cpu multisample_binning_assembly_design
cp ~/MGBK/multisample_binning_assembly_design ./
perl ~/MGBK/s1_multisample_binning_2_NGS_assembly.pl 80 multisample_binning_assembly_design
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `1`: tbw
- `2`: tbw
- `3`: tbw
- `4`: tbw


Step 2. alignment
---------------
We use minibwa to align short reads against reference genomes.


If performing coassembly binning, run s2_coassembly_binning_align_fq_for_bam_and_depth.pl to align trimmed fq against the co-assembled genome.
```sh
cd ~/MGBK_example/coassembly_binning
mkdir s2_alignment
cd s2_alignment
#perl ~/MGBK/s2_coassembly_binning_align_fq_for_bam_and_depth.pl $assembly $min_length $cpu $fq_list_trim
perl ~/MGBK/s2_coassembly_binning_align_fq_for_bam_and_depth.pl ~/MGBK_example/coassembly_binning/s1_coassembly/final.contigs.fa 1500 80 ~/MGBK_example/coassembly_binning/fq_list_trim
```


If performing multiple binning, first run s1_multisample_binning_1_trim_PE_trimmomatic_NGS.pl for all data, then edit a assembly_design tsv to run s1_multisample_binning_2_assembly_PE_megahit.pl
```sh
#must run this scripts in the same path with s1_multisample_binning_2_assembly_PE_megahit.pl
cd ~/MGBK_example/multisample_binning
#perl ~/MGBK/s2_multisample_binning_align_fq_for_bam_and_depth.pl multisample_binning_assembly_design $min_length $cpu $fq_list_trim
#this scripts will detect s1_assemblies_res dir and mapping read for each assemblies
#assembly_design used here is the same with s1_multisample_binning_2_assembly_PE_megahit.pl
perl ~/MGBK/s2_multisample_binning_align_fq_for_bam_and_depth.pl multisample_binning_assembly_design 1500 80 fq_list_trim
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `1`: tbw
- `2`: tbw
- `3`: tbw
- `4`: tbw

-----
### Step 3. binning
Based on the two NC papers, binny and COMEBin consistently performed very well. However, due to installation issues with binny and to facilitate running this pipeline across multiple platforms, I will not include binny in my pipeline.

Currently, 5 binning software tools are included, classified into 4 categories based on their algorithms (Kim et al., 2026):

- `Projection-based integration`: CONCOCT
- `Probabilistic Modeling`: MetaBAT2
- `Neural Networks`: COMEBin, SemiBin2
- `Ensembled-based integration`: MetaBinner


Since COMEBin takes an extremely long time to run, a "no-COMEBin" version is provided as an alternative.


Currently, there are 3 options available: metaWRAP, MAGScoT, and DASTool. metaWRAP takes the longest time and consumes the most resources, but it indeed yields genomes with lower contamination and fewer chimeric genomes (Kim et at., 2026). Therefore, I still use metaWRAP as the tool for refinement.


Since metaWRAP can only refine 3 sets of bins at a time, I split the 5 sets of bins and run metaWRAP 3 times in total:

CONCOCT, MetaBAT2
COMEBin, SemiBin2
r1, r2, MetaBinner

If without COMEBin, I split the 4 sets of bins and run metaWRAP 2 times in total:

CONCOCT, MetaBAT2
r1, SemiBin2, MetaBinner


If performing coassembly binning, run s3_coassembly_binning_run_binners_full.pl or s3_coassembly_binning_run_binners_no_comebin.pl
```sh
cd ~/MGBK_example/coassembly_binning
mkdir s3_binning
cd s3_binning
#perl ~/MGBK/s3_coassembly_binning_run_binners_full.pl $binning_PE_assembly_$min_length.fa $min_length $cpu $s2_alignment_dir
perl ~/MGBK/s3_coassembly_binning_run_binners_full.pl ~/MGBK_example/coassembly_binning/s2_alignment/binning_PE_assembly_1500.fa 1500 80 ~/MGBK_example/coassembly_binning/s2_alignment/
```


If performing multiple binning, run s3_multisample_binning_run_binners_full.pl or s3_multisample_binning_run_binners_no_comebin.pl.
```sh
#must run this scripts in the same path with s1_multisample_binning_2_assembly_PE_megahit.pl
cd ~/MGBK_example/multisample_binning
#perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design $min_length $cpu
#this scripts will detect s1_assemblies_res dir and bams files (from s2_multisample_binning_align_fq_for_bam_and_depth.pl) in the sub dirs
#assembly_design used here is the same with s1_multisample_binning_2_assembly_PE_megahit.pl
perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design 1500 80
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `1`: tbw
- `2`: tbw
- `3`: tbw
- `4`: tbw

-----
### Step 4. genome dereplication (only for multisample_binning)
In multisample_binning, we will get a number of refined bins from each assembly. Some of the bins from different assemblies can be the same strain (ANI > 98%). We use drep to conduct Bin dereplication.

If performing multiple binning, run s4_multisample_binning_derep_bins.pl
```sh
#must run this scripts in the same path with s1_multisample_binning_2_assembly_PE_megahit.pl
cd ~/MGBK_example/multisample_binning
#perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design $min_length $cpu
#this scripts will detect s1_assemblies_res dir and bams files (from s2_multisample_binning_align_fq_for_bam_and_depth.pl) in the sub dirs
#assembly_design used here is the same with s1_multisample_binning_2_assembly_PE_megahit.pl
perl ~/MGBK/s4_multisample_binning_derep_bins.pl  multisample_binning_assembly_design 80
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `1`: tbw
- `2`: tbw
- `3`: tbw
- `4`: tbw

-----
### Step 5. check bin quality
We use checkm2 and gunc to check the quality.

If performing multiple binning, run s5_multisample_binning_derep_bins.pl
```sh
#must run this scripts in the same path with s1_multisample_binning_2_assembly_PE_megahit.pl
cd ~/MGBK_example/multisample_binning
#perl ~/MGBK/s3_multisample_binning_run_binners_no_comebin.pl multisample_binning_assembly_design $min_length $cpu
#this scripts will detect s1_assemblies_res dir and bams files (from s2_multisample_binning_align_fq_for_bam_and_depth.pl) in the sub dirs
#assembly_design used here is the same with s1_multisample_binning_2_assembly_PE_megahit.pl
perl ~/MGBK/s4_multisample_binning_derep_bins.pl  multisample_binning_assembly_design 80
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `1`: tbw
- `2`: tbw
- `3`: tbw
- `4`: tbw