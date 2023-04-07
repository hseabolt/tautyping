# ![Tau-typing](docs/images/tautyping_logo_light.png#gh-light-mode-only) 

## Introduction

**Tau-typing** is a bioinformatics analysis pipeline tuned for identifying genes or genomic segments which most closely reflect the genome-wide phylogenetic signal of a given organism using the rank correlation statistics (Kendall's tau or Spearman's rho).

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been installed from [nf-core/modules](https://github.com/nf-core/modules).

Development and testing of this pipeline used `singularity` as the container technology and `Sun Grid Engine` (SGE) for testing on cluster environments. 


## Pipeline summary

1. Transfer annotations ([`Liftoff`](https://academic.oup.com/bioinformatics/article/37/12/1639/6035128))
2. Extract features ([`GFFRead`](https://github.com/gpertea/gffread))
3. Compare genome sequences - ANI or Maximum Likelihood ([`FastANI`](https://www.nature.com/articles/s41467-018-07641-9), [`Phangorn`](https://academic.oup.com/bioinformatics/article/27/4/592/198887))
4. Compute the core genomes ([`PIRATE`](https://academic.oup.com/gigascience/article/8/10/giz119/5584409))
5. Rank individual features against WGS (Custom ([`R`](https://www.r-project.org/)) scripts)
6. Create sets of features from best-correlating features (Custom ([`Perl`](https://www.perl.org/)) scripts)
7. Rank sets against WGS (Custom ([`R`](https://www.r-project.org/)) scripts)
8. Tabulate results ([`MultiQC`](http://multiqc.info/))

![Tau-typing](docs/images/tautyping_workflow_v1.0.300.tiff) 

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.10.3`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```console
   nextflow run hseabolt/tautyping -profile test,<YOURPROFILE> --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

   ```console
   nextflow run hseabolt/tautyping --input samplesheet.csv --outdir <OUTDIR> -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>
   ```

## Documentation

The Tau-typing pipeline comes with documentation about the pipeline [usage](https://github.com/hseabolt/tautyping/usage), [parameters](https://github.com/hseabolt/tautyping/parameters) and [output](https://github.com/hseabolt/tautyping/output).

## Credits

Tau-typing was originally written by hseabolt.

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

If you use Tau-typing for your analysis, please cite it using the following citation: 

> **Tau-typing: a Nextflow pipeline enabling on-demand, high-resolution molecular typing for pathogen genomics**
>
> Matthew H. Seabolt, Arun K. Boddapati, Joshua J. Forstedt, Kostantinos T. Konstantinidis.  
>
> Tau-typing: a Nextflow pipeline for finding the best phylogenetic markers in the genome for genomotyping of microbial species
>
> _To be submitted to Bioinformatics_

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
