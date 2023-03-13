process PHANGORN_ML {
    tag "$meta.id"
    label 'process_low'
    label 'error_ignore'

	conda "conda-forge::r-phangorn=2.11.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phangorn:2.4.0--r351h9d2a408_0' :
        'quay.io/biocontainers/r-phangorn:2.4.0--r351h9d2a408_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
	tuple val(meta), path("*.dist"), optional: true             , emit: dist
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla
    library(phangorn)
    fh <- file("${fasta}", open="rb")
    nlines <- 0L
    while (length(chunk <- readBin(fh, "raw", 1000000)) > 0) {
        nlines <- nlines + sum(chunk == as.raw(10L))
    }  
    close(fh) 
    if ( (nlines/2) > 1 ) {
        dna <- phyDat(read.FASTA(file="${fasta}", type="DNA"))
        dna.ml <- as.matrix(dist.ml(dna, model="F81"))
        write.table(dna.ml, file="${prefix}.dist", sep="\t", quote=FALSE)
    }
    """
}
