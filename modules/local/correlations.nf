process CORRELATIONS_R {
    tag "$meta2.id"
    label 'process_low'

    conda "conda-forge::r-plotly=4.10.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-plotly:4.5.6--r3.3.2_0' :
        'quay.io/biocontainers/r-plotly:4.5.6--r3.3.2_0' }"

    input:
    tuple val(meta1), path(matrix1)
    tuple val(meta2), path(matrix2), path(fasta)
    val(method)

    output:
	tuple val(meta2), path("*.csv")              , emit: correlation
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta2.id}"

    """
	#!/usr/bin/env Rscript --vanilla

    matrix1 <- as.matrix(read.table("$matrix1", head=T, row.names=1))
    matrix1 <- matrix1[sort(rownames(matrix1)), sort(colnames(matrix1))]
    matrix2 <- as.matrix(read.table("$matrix2", head=T, row.names=1))
    matrix2 <- matrix2[sort(rownames(matrix2)), sort(colnames(matrix2))]
    file_out <- file("${prefix}.${method}.csv")
    if ( identical(dim(matrix1),dim(matrix2)) ) {
        corr <- cor.test(matrix1, matrix2, method="$method")
        str <- paste("${prefix}", round(corr\$estimate,4), nrow(matrix1), nrow(matrix2), normalizePath("${fasta}"), sep=",")
        writeLines(str, file_out)
    } else if ( nrow(matrix2) == 1 ) {
        str <- paste("${prefix}", "NA", nrow(matrix1), nrow(matrix2), normalizePath("${fasta}"), sep=",")
        writeLines(str, file_out)
    } else {
        row_names_to_remove <- setdiff(rownames(matrix1), rownames(matrix2))
        col_names_to_remove <- setdiff(colnames(matrix1), colnames(matrix2))
        matrix1.rm <- matrix1[!(row.names(matrix1) %in% row_names_to_remove),]
        matrix1.rm <- t(matrix1.rm)
        matrix1.rm <- matrix1.rm[!(row.names(matrix1.rm) %in% col_names_to_remove),]
        matrix2.rm <- matrix2[!(row.names(matrix2) %in% row_names_to_remove),]
        matrix2.rm <- t(matrix2.rm)
        matrix2.rm <- matrix2.rm[!(row.names(matrix2.rm) %in% col_names_to_remove),]
        corr <- cor.test(matrix1.rm, matrix2.rm, method="$method")
        str <- paste("${prefix}", round(corr\$estimate,4), nrow(matrix1), nrow(matrix2), normalizePath("${fasta}"), sep=",")
        writeLines(str, file_out)
    }
    """
}
