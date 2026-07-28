MGBK (MetaGenomic Binning Kit)
=======

MGBK is a pipeline for metagenomic binning. We can start with the metaG raw fastq data and proceed to refined bins or metagenome-assembled genomes (MAGs). This pipeline is designed based on two papers published on Nature Communications:
- `Kim et al., 2026`: Comprehensive benchmarking of metagenomic binning tools reveals key factors for improved genome recovery
- `Han et al., 2025`: Benchmarking metagenomic binning tools on real datasets across sequencing platforms and binning modes

Installation
---------------

Make sure `conda` and `mamba` have been installed in advanced.
```sh
#if you are using old Linux system, you can try old version conda
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-x86_64.sh
#type 'yes' twice
sh Miniconda3-py310_23.10.0-1-Linux-x86_64.sh

#if you are using old Linux system, you can try old version mamba
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

#install trimmomatic
conda create -n trimmomatic -y
conda activate trimmomatic
mamba install bioconda::trimmomatic=0.39 -y
conda deactivate

#install megahit
conda create -n megahit -y
conda activate megahit
mamba install bioconda::megahit -y
conda deactivate

#install seqkit
conda create -n seqkit -y
conda activate seqkit
mamba install bioconda::seqkit -y
conda deactivate

#install minibwa
conda create -n minibwa -y
conda activate minibwa
mamba install minibwa -y
conda deactivate

#install samtools
#metabat2 was also installed in this env for the command 'jgi_summarize_bam_contig_depths'
conda create -n samtools -y
conda activate samtools
mamba install bioconda::metabat2 bioconda::samtools -y
conda deactivate

#install metawrap (simplified)
#This metawrap env is only used for bin_refinement
cd ~
git clone https://github.com/bxlab/metaWRAP.git
export PATH=~/metaWRAP/bin/:$PATH
source ~/.bashrc
mamba create -y -n metawrap python=2.7
conda activate metawrap
mamba install bioconda::checkm-genome=1.0.18 -y
cd ~/metaWRAP/
mkdir MY_CHECKM_FOLDER
# Now manually download the database:
cd MY_CHECKM_FOLDER
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xvf *.tar.gz
rm *.gz
checkm data setRoot ~/metaWRAP/MY_CHECKM_FOLDER/
conda deactivate

#install metabat2
conda create -n metabat2 -y
conda activate metabat2
mamba install bioconda::metabat2 -y
conda deactivate

#install concoct
conda create -n concoct -y
conda activate concoct
mamba install bioconda::concoct -y
conda deactivate

#install SemiBin2
conda create -n SemiBin -y
conda activate SemiBin
mamba install -c conda-forge -c bioconda semibin -y
conda deactivate

#install MetaBinner
cd ~
git clone https://github.com/ziyewang/MetaBinner.git
cd MetaBinner
mamba env create -f metabinner_env.yaml -y

#install COMEBin (cpu version)
conda create -n comebin -y
conda activate comebin
mamba install -c conda-forge -c bioconda comebin -y
conda deactivate
```

Download or clone the MGBK repository
```sh
cd ~
git clone https://github.com/jchenek/MGBK.git
```


Users' Guide
---------------
Download example NGS data from DOI: [https://figshare.com/articles/online_resource/example_NGS_metaG_fq/33101945](https://figshare.com/articles/online_resource/example_NGS_metaG_fq/33101945).

Upload the downloaded file '33101945.zip' to the dir ~/MGBK_example.
```sh
cd ~
mkdir MGBK_example
cd MGBK_example
#upload the the file '33101945.zip' to ~/MGBK_example
unzip 33101945.zip #you will see dir 'example_NGS_metaG_fq_from_cold_seep' after unzip
cd example_NGS_metaG_fq_from_cold_seep/
#prepare a fq_list file for further analysis
perl ~/MGBK/scripts/get_fq_list_from_gz.pl
```
- `fq_list`: This is a tsv file that looks like this: "A_id\tA_PATH_1.fq\tA_PATH_2.fq\nB_id\tB_PATH_1.fq\tB_PATH_2.fq\nC_id\tC_PATH_1.fq\tC_PATH_2.fq\n". You can get this file by ~/MGBK/scripts/get_fq_list_from_gz.pl or make one useing any text editor you like.
- `~/MGBK/scripts/get_fq_list_from_gz.pl`: This perl scripts will detect all files under current path, extract those ended with "gz", and create a fq_list.

Step 1. trim and assembly
---------------
For NGS mstaG fq, we use trimmomatic for trimming and megahit for assembly.


If performing coassembly binning, run s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl to trim and assemble.
```sh
cd ~/MGBK_example
mkdir coassembly_binning
cd coassembly_binning
#perl ~/MGBK/s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl $cpu $fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
perl ~/MGBK/s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
```


If performing multiple binning, first run s1_multisample_binning_1_trim_PE_trimmomatic_NGS.pl for all data, then edit a assembly_design tsv to run s1_multisample_binning_2_assembly_PE_megahit.pl
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

-----
### Step 2. alignment
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