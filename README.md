MGBK (MetaGenomic Binning Kit)
=======

MGBK is a pipeline for metagenomic binning. We will start with the metaG raw fastq data and proceed to refined metagenome-assembled genomes (MAGs). This pipeline is designed based on two NC papers:
- `Kim et at., 2026`: Comprehensive benchmarking of metagenomic binning tools reveals key factors for improved genome recovery
- `Han et at., 2025`: Benchmarking metagenomic binning tools on real datasets across sequencing platforms and binning modes

Installation
---------------

### Create conda environments
```sh
#If you are using old Linux system, you can use old version conda
#wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-x86_64.sh
#type 'yes' twice
#sh Miniconda3-py310_23.10.0-1-Linux-x86_64.sh
conda update conda -y

conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels ursky
conda config --set channel_priority flexible

#We need mamba to accelerate environment configuration
#If you are using old Linux system, you can use old version mamba
#conda install conda-forge::mamba=1.5.6 -y
#conda install conda-forge::mamba -y

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

```

### Download or clone the MGBK repository
```sh
cd ~
git clone https://github.com/jchenek/MGBK.git
```

### Download and prepare example raw fq data
```sh
cd ~
mkdir MGBK_example
cd MGBK_example
#download data from: https://figshare.com/articles/online_resource/example_NGS_metaG_fq/33101945
#upload the the file '33101945.zip' to MGBK_example
#you will see dir 'example_NGS_metaG_fq_from_cold_seep' after unzip
unzip 33101945.zip
cd example_NGS_metaG_fq_from_cold_seep/
#prepare a fq_list file for further analysis
perl ~/MGBK/scripts/get_fq_list_from_gz.pl
```

Tutorial with example data
- `$cpu`: 
- `$fq_list`: 

-----
### Step 1. assembly
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
perl ~/MGBK/s1_multisample_binning_1_NGS_trim.pl 80 ~/MGBK_example/example_NGS_metaG_fq_from_cold_seep/fq_list ~/MGBK/trimmomatic_adaptor/TruSeq3-PE-2-GGGGG.fa
cp ~/MGBK/multisample_binning_assembly_design ./
perl ~/MGBK/s1_multisample_binning_2_NGS_assembly.pl 80 multisample_binning_assembly_design
```

For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.

Make sure Perl is available in your system.
- `-i`: the path to your directory where genomes or MAGs were stored
- `-p`: the ABSOLUTE path to Diaiden repository
- `-c`: potential diazotroph must carry genes that encode at least `-c number` of the three catalytic genes (nifH, nifD, nifK)
- `-b`: potential diazotroph must carry genes that encode at least `-b number` of the three biosynthetic genes (nifE, nifN, nifB)