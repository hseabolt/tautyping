process NJ_R {
    tag "$meta.id"
    label 'process_low'
    label 'error_ignore'

	conda "conda-forge::r-phangorn=2.11.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phangorn:2.4.0--r351h9d2a408_0' :
        'quay.io/biocontainers/r-phangorn:2.4.0--r351h9d2a408_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
	tuple val(meta), path("*.nj.nwk")              , emit: newick
    path("*_mqc.png"), optional:true               , emit: png
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla
    library(phangorn)
	matrix <- as.matrix(read.table(file="$matrix", header=T, row.names=1, sep="\\t"))
	if ( max(matrix) == 100 ) {
		matrix <- 100 - matrix
	}
    
    if ( dim(matrix)[1] > 3 ) {
	    tr <- NJ(matrix)
	    write.tree(tr, file="${prefix}.nj.nwk")
        img <- png(file="${prefix}_Phylogeny_mqc.png", height=3000, width=3000, res=300)
        plot(tr)
        dev.off()
    } else {
        file_out <- file("${prefix}.nj.nwk")
        str <- paste(row.names(matrix)[1], ":0.0;", sep='')
        writeLines(str, file_out)
        close(file_out)
    }
    """
}
