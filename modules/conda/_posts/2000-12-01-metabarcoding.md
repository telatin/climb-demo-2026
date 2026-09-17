---
title: "16S data"
---

> This example is designed to showcase how to use CLIMB Environments,
> it's not meant to be treated as a bioinformatics tutorial.
> The complete **metabarcoding tutorial** can be found [here](https://corebio.info/metabarcoding-tutorial-2026/).

## Getting started

We will keep all the files for this exercise in one directory under `/shared/team/`.
This makes it easier to find the data later, and it also keeps the working directory shared with the rest of the team.

The first file we need is a small sample sheet. It contains the metadata for the sequencing runs we want to download.

```bash
cd /shared/team/
mkdir -p my-metabarcoding-tutorial/data

wget -O my-metabarcoding-tutorial/data/samplesheet.tsv \
  "https://gist.githubusercontent.com/telatin/9447c3dc9175ba500fe9f6a6f6df8d71/raw/54eb3d9d0e821e73625791e972ad098afa5d7b83/metabarcoding_dataset_2026.tsv"
```

Here `mkdir -p` creates the directory if it does not already exist. The `-O` option of `wget` tells it where to save the downloaded file.

:bulb: JupyterLab offers an easy and built-in table viewer. Double click on the `samplesheet.tsv` file to open it with a nice tabular view.

The full sample sheet has several columns, but `fetchngs` only needs the accession column as input.
We can extract that column into a simpler file.

```bash
cut -f 15 my-metabarcoding-tutorial/data/samplesheet.tsv \
    | grep -v "sample" \
    > my-metabarcoding-tutorial/data/samples.csv
```

The command uses `cut -f 15` to select column 15 from the tab-separated file. We then pipe the result to `grep -v "sample"` to remove the header line.

The `>` symbol redirects the final list into `samples.csv`.
Try opening this file: it should contain one accession per line.

## Getting the raw reads

Now we can download the raw FASTQ files.
Instead of downloading each run manually, we will use the nf-core `fetchngs` pipeline.

This pipeline reads the accession list and fetches the corresponding sequencing data for us.

```bash
cd /shared/team/my-metabarcoding-tutorial/
nextflow run nf-core/fetchngs \
    --input data/samples.csv \
    --outdir reads
```

The `--input` option points to the accession list we created. The `--outdir` option tells Nextflow where to put the results.

Where are the FASTQ files? Try `ls reads/` and check which subdirectory might contain them
(or better, [read the docs](https://nf-co.re/fetchngs/1.13.0/docs/output/)).

The downloaded filenames can be quite long. For the rest of this exercise, it is convenient to create shorter names.

Here we do not copy the files. We create symbolic links in a new directory called `raw_reads/`.

```bash
mkdir -p raw_reads/

for i in reads/fastq/*;
do
  ln -s $PWD/$i raw_reads/$(echo $i|cut -f 2,3 -d_); 
done
```

The loop visits each file in `reads/fastq/`. For every file, `ln -s` creates a symbolic link pointing to the original file.

The `$(...)` syntax runs a command and inserts its output into the filename. Here we use it to keep only selected parts of the original name.

This is useful when a tool expects simple paired-end names, but we still want to preserve the original downloaded files.

## Getting Kraken and its database

Kraken2 classifies reads using a k-mer-based approach against a reference database.
For this 16S example, we will use a SILVA-based Kraken database.

If Kraken2 and related tools are not already available in your environment, 
we can install them with `mamba`.

```bash
# If we don't have a Kraken environment...
mamba create -n kraken --yes \
  kraken2 bracken kraut

conda activate kraken
```

This creates a Conda environment called `kraken` containing `kraken2`, `bracken`, and `kraut`.

You only need to create the environment once. In a later session, `conda activate kraken` is enough.

Next we download the pre-built 16S database and unpack it into `/shared/team/db/`.

```bash
wget https://genome-idx.s3.amazonaws.com/kraken/16S_Silva138_20200326.tgz

mkdir -p /shared/team/db/
tar -xvzf 16S_Silva138_20200326.tgz -C /shared/team/db/

# we can now remove the downloaded tarball to save space
rm 16S_Silva138_20200326.tgz
```

The file is a compressed tar archive.
The `tar -xvzf` command extracts it, and `-C /shared/team/db/` tells `tar` where to place the extracted database directory.

Kraken databases can be large, so it is usually better to keep them in a shared location instead of downloading a separate copy for every analysis.

## Running Kraken

We can now classify the paired-end reads with Kraken2.
The command below loops over all forward reads ending in `_1.fastq.gz` and automatically finds the matching reverse read.

```bash
# Create output directory for Kraken reports
mkdir -p kraken

# Loop over raw reads and classify them with Kraken
for i in raw_reads/*_1.fastq.gz; 
do 
  kraken2 --threads 8 --db /shared/team/db/16S_SILVA138_k2db/ \
    --report kraken/$(basename $i | cut -f 1 -d_).tsv \
    $i ${i/_1/_2} >/dev/null; 
done
```

The important part is `${i/_1/_2}`. This is a shell substitution: it takes the forward-read filename and replaces `_1` with `_2` to get the reverse-read filename.

For each sample, Kraken writes a report into the `kraken/` directory. The report name is built from the input filename using `basename` and `cut`.

:question: How does the report look like?

Try inspecting one report with `less` or with the JupyterLab file browser. Kraken reports are tabular files, but they do not have a header line by default.

## Combining reports and exploratory plots

Single-sample reports are useful, but most metabarcoding projects have several samples.
We often want a combined abundance table and a quick plot to see the main differences between samples.

Here we use `kraut`, a small utility for working with Kraken reports.

```bash
# Generate a combined table
kraut make-table -o cucumber.tsv \
  --rank G --min-perc 0.5 kraken/*tsv --add-lineage

# Plot bar chart
kraut plot-multi --rank G \
  -o plot.svg kraken/*tsv --min-perc 2

kraut dendrogram -p dendro.svg \
  kraken/*tsv
```

The `--rank G` option means that we summarise the results at genus level. The `--min-perc` option removes very low-abundance taxa from the output, which makes the table and plots easier to inspect.

The output files are:

* `cucumber.tsv`: a combined genus-level abundance table;
* `plot.svg`: a bar plot of the main genera;
* `dendro.svg`: a simple dendrogram comparing samples from their Kraken profiles.

Try opening the SVG files in JupyterLab. Do the samples look similar, or do some of them have clearly different profiles?
