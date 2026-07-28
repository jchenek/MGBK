MGBK (MetaGenomic Binning Kit)
=======

MGBK is a pipeline for metagenomic binning. We will start from metaG raw fastq data to refined metagenome-assembled genomes (MAGs). This pipeline is designed based on two NC papers:
- `Kim et at., 2026`: Comprehensive benchmarking of metagenomic binning tools reveals key factors for improved genome recovery
- `Han et at., 2025`: Benchmarking metagenomic binning tools on real datasets across sequencing platforms and binning modes

Installation
---------------

### Create conda environments
```sh
conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels ursky
conda config --set channel_priority flexible
conda install conda-forge::mamba -y


```

### Download or clone the Diaiden repository
```sh
git clone https://github.com/jchenek/Diaiden.git
```

### Download example raw fq data
```sh
git clone https://github.com/jchenek/Diaiden.git
```

Usage
-----
### Step 1. assembly
For NGS results, use megahit.
For long sequencing & NGS hybrid assembly, I need to evaluate after obtaining the data.
If directly performing co-assembly binning, just run s1_coassembly_binning_trim_and_coassembly_PE_megahit.pl to trim and assemble.If performing multiple binning, first run s1_multisample_binning_1_trim_PE_trimmomatic_NGS.pl for all data, then edit assembly_design to run s1_multisample_binning_2_assembly_PE_megahit.pl.
```sh
perl /PATH/TO/Diaiden.pl -i /PATH/TO/YOUR/genomes_dir -p /PATH/TO/Diaiden_dir -c 2 -b 2
```

Make sure Perl is available in your system.
- `-i`: the path to your directory where genomes or MAGs were stored
- `-p`: the ABSOLUTE path to Diaiden repository
- `-c`: potential diazotroph must carry genes that encode at least `-c number` of the three catalytic genes (nifH, nifD, nifK)
- `-b`: potential diazotroph must carry genes that encode at least `-b number` of the three biosynthetic genes (nifE, nifN, nifB)