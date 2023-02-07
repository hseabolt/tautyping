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
    if ( identical(dim(matrix1),dim(matrix2)) ) {
        corr <- cor.test(matrix1, matrix2, method="$method")
        df <- as.data.frame(c("${prefix}", corr\$estimate))
        write.table(df, file="${prefix}.${method}.txt")
    } else {
        file_out <- file("${prefix}.bad_compute.txt")
        str <- paste("Matrix dimensions are incompatible -- cannot compute rank correlation!", sep='')
        writeLines(str, file_out)
        close(file_out)
    }
    """
}
