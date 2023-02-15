process CORRELATIONS_R {
    tag "$meta2.id"
    label 'process_low'

    input:
    tuple val(meta1), path(matrix1)
    tuple val(meta2), path(matrix2)
    val(method)

    output:
	tuple val(meta2), path("*.txt")              , emit: correlation
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta2.id}"
    """
	#!/usr/bin/env Rscript --vanilla

    matrix1 <- as.matrix(read.table("$matrix1", head=T, row.names=1))
    matrix2 <- as.matrix(read.table("$matrix2", head=T, row.names=1))
    file_out <- file("${prefix}.${method}.txt")
    if ( identical(dim(matrix1),dim(matrix2)) ) {
        corr <- cor.test(matrix1, matrix2, method="$method")
        str <- paste("${prefix}", round(corr\$estimate,4), nrow(matrix1), nrow(matrix2), sep="\\t")
        writeLines(str, file_out)
    } else if ( nrow(matrix2) == 1 ) {
        str <- paste("${prefix}", "NA", nrow(matrix1), nrow(matrix2), sep="\\t")
        writeLines(str, file_out)
    } else {
        row_names_to_remove <- setdiff(rownames(matrix1), rownames(matrix2))
        matrix1.rm <- matrix1[!(row.names(matrix1) %in% row_names_to_remove),]
        matrix1.rm <- t(matrix1.rm)
        matrix1.rm <- matrix1.rm[!(row.names(matrix1.rm) %in% row_names_to_remove),]
        d1 <- as.character(dim(matrix1.rm))
        d2 <- as.character(dim(matrix2))
        writeLines(d1, file_out)
        writeLines(d2, file_out)
        corr <- cor.test(matrix1.rm, matrix2, method="$method")
        str <- paste("${prefix}", round(corr\$estimate,4), nrow(matrix1), nrow(matrix2), sep="\\t")
        writeLines(str, file_out)
    }
    """
}
