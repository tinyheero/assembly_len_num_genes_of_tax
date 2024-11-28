# Get the reference assembly length and number of protein coding genes per taxon

This repository contains the bash script `get_assembly_len_and_num_protein_coding_genes_of_taxon.sh`.
Given a taxon (e.g. human), it will retrieve:

1. The reference assembly length
2. Number of protein coding genes

You can give it multiple taxons.

## 1 Installation

Git clone this repository:

```bash
git clone git@github.com:tinyheero/assembly_len_num_genes_of_tax.git
```

You will need the NCBI command-line tools `datasets`. This can be installed
using conda:

```bash
conda install -c conda-forge ncbi-datasets-cli
```

You will also need `jq`. On MacOSX, you can do:

```bash
brew install jq
```

## 4 Tutorial

To run this, you simply need to specify the list of taxons you are interested 
in using the `--taxons` argument. For instance:

```bash
./get_assembly_len_and_num_protein_coding_genes_of_taxon.sh \
        --taxons "mus musculus" "Drosophila melanogaster"
```
```
taxon	assembly_length	num_protein_coding_genes
mus musculus	2728206152	26251
Drosophila melanogaster	143706478	13986
```

**Note that this will take some time as it will query the NCBI databases to 
retrieve this information.**

## 6 Release History

* 0.1.0

## 7 Contributors

* Fong Chun Chan (<fong_chun_chan@gmail.com>)
