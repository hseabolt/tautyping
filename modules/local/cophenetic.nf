process COPHENETIC_R {
    tag "$meta.id"
    label 'process_low'

	conda "conda-forge::r-phangorn=2.11.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phangorn:2.4.0--r351h9d2a408_0' :
        'quay.io/biocontainers/r-phangorn:2.4.0--r351h9d2a408_0' }"

    input:
    tuple val(meta), path(tree)

    output:
	tuple val(meta), path("*.dist")              , emit: dist
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla
    library(phangorn)
	tr <- read.tree(file="${tree}")
	dist <- cophenetic(tr)
    write.table(dist, file="${prefix}.dist", quote=FALSE, sep="\\t")
    """
}
