# Tau-typing: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Annotation Transfer](#annotation_transfer) - Identify homologous feature sequences in each genome provided by the user from a set of reference annotations.
- [Core Genome](#core_genome) - Compute a core genome from feature sequences clustered by coverage and percent identity.
- [Evolutionary Distance](#evolutionary_distance) - Calculate evolutionary distance between each core gene feature using either ANI (sequence identity) or maximum likelihood.
- [Rank Correlations](#rank_correlations) - Evaluate all core gene features for phylogenetic signal correlated with whole-genome signal.
- [Set Construction](#set_construction) - Constructs sets of features from core gene features that correlate well with whole-genome signals.  Distance matrices and rank correlations are calculated for each set to evaluate each set against whole-genome signal.
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution


### Annotation Transfer

Using the reference FASTA and GFF files provided by the user with `--ref_fasta` and `--ref_gff`, this pipeline uses the programs [`Liftoff`](https://academic.oup.com/bioinformatics/article/37/12/1639/6035128) and [`GFFRead`](https://github.com/gpertea/gffread) to identify and extract homologous feature sequences in each of the samples given in the providfed samplesheet.  The user can use `--feature_types` to provide a list file to `Liftoff` with specific types of features to extract (by default: `gene` and `CDS`).  

<details markdown="1">
<summary>Output files</summary>

- `liftoff/`: a directory containing a GFF and `unmapped_features` file per genome.
- `gffread/`: a directory containing nucleotide (CDS) FASTA files for all features, one FASTA file per genome.

</details>

### Core Genome

A provisional pangenome is computed by [`PIRATE`](https://academic.oup.com/gigascience/article/8/10/giz119/5584409) using the results from annotation transfer.  All core genes represented by homologous sequences in all (i.e. 100%) of the genomes provided in the `--input` samplesheet plus multiple-sequence aligments are passed to the next steps to compute percent identity or maximum likelihood distance matrices.

<details markdown="1">
<summary>Output files</summary>

- `pirate/`
  - `results/`
    - `feature_sequences`: a directory containing individual FASTA alignments for each analyzed pangenom feature.
    - `pangenome_alignment.fasta`: a FASTA multiple-sequence alignment containing all genes in the the total pangenome analyzed by PIRATE.
    - `core_alignment.fasta`: a FASTA multiple-sequence alignment containing all core genes with homologous sequences found in 100% of the genomes provided.
    - `additional results`: PIRATE produces a plethora of other potentially useful data files which are made available for additional study

</details>

### Evolutionary Distance via ANI or Maximum Likelihood

The last processing step prior to computing signal correlations between core gene features and WGS is to compute all-vs-all distance matrices for each core gene feature and between genomes.  For whole genome sequences, the program `FastANI` is used to compute ANI distances if the user wishes to use `--distance ani` and `blastn` to compute distances from alignments from each gene feature.  Alternatively, the user can use `--distance likelihood` to specify the use of maximum likelihood distances, which will toggle the pipeline to use the `R` library `phangorn` to compute distance matrices from alignments.

<details markdown="1">
<summary>Output files</summary>

- `fastani/`: a directory containing results from `FastANI` used to efficiently compute all-vs-all ANI distance at whole-genome level (only if `--distance` is `ani`).
- `blastn/`: a directory containing results from `blastn` used to compute all-vs-all ANI distance per core gene feature (only if `--distance` is `ani`).
- `phangorn_ml/`: a directory containing results from `R-phangorn` used to compute all-vs-all maximum likelihood distance per core gene feature and WGS(only if `--distance` is `likelihood`).
- `table2matrix/`: a directory containing distance matrices for downstream calculation of rank correlations.
- `nj/`: a directory containing newick-formatted trees computed from each distance matrix.

</details>


### Rank Correlations

Distance matrices are compared individually against the corresponding distances from whole-genome comparisons to determine which core gene features msot closely correlate with the whole-genome signal.  These gene features have high potential as new molecular markers suitable for genomic typing schemes of many forms, e.g. MLST, molecular epidemiology, etc.  The user has three options for which correlation statistic to use with the parameter `--correlation`: `kendall` (default), `spearman`, or `pearson`.  Kendall's tau (from which this pipeline takes its name) and Spearman's rho are best suited to non-normal/non-linear data, and the tau statistic performing more conservatively in the presence of non-monotonicity often encountered with molecular sequence data.  Thus, we recommend users to use Kendall's tau, however we leave the ultimate choice to the user.  

<details markdown="1">
<summary>Output files</summary>

- `correlations/`: a directory containing raw results from computing correlations for each feature.
  - `Histogram_of_Genes_mqc.png`: a PNG image file summarizing the distribution of correlation coefficients for all core gene features.  
- `sorted_correlations/`: a directory containing final (i.e. sorted) csv-formatted output files from collated correlation results.
  - `Sorted_Gene_Correlations_mqc.csv`: CSV collated output from all individual core gene features correlated against WGS.
  - `Sorted_Gene_Set_Correlations_mqc.csv`: CSV collated output from all gene sets correlated against WGS.

</details>

Note: The suffix `_mqc` is used by `MultiQC` for inclusion in the final HTML report.  

### Set Construction

From the core gene features that correlate most closely with WGS signal, we construct sets with the goal of improving the correlating power by using multiple gene features.  By default, sets of size 3 are constructed from the top 10 ranking gene features.  The user can change these parameters using the options `--n` to change the number of top _n_ ranking genes, `--k` to constuct sets of size _k_, or if desired, `--kmin` and `--kmax` to construct sets of variable sizes ranging from a minimum (`kmin`) and maximum (`kmax`).  Once sets are constructed, the pipeline repeats the previous two steps of computing all-vs-all distances and correlates the signal for each set against the WGS signal in the same manner as described above.

<details markdown="1">
<summary>Output files</summary>

- `sets`/`: a directory containing concatenated FASTA files for each constructed set.
  - `Histogram_of_Gene_Sets_mqc.png`: a PNG image file summarizing the distribution of correlation coefficients for all sets.  

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. The key pipeline  results are visualised in the report as images or tables and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
