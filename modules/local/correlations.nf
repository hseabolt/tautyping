process CORRELATIONS_R {
    //tag "${meta.id}"
    label 'process_low'

    input:
    path(matrix1)
    //tuple val(meta), path(matrix2)
    path(matrix2)
    val(method)

    output:
	path "*.txt"               , emit: correlation
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    //def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env R

    matrix1 <- as.matrix(read.table("$matrix1", head=T, row.names=1))
    matrix2 <- as.matrix(read.table("$matrix2", head=T, row.names=1))
    corr <- cor(matrix1, matrix2, method="$method")
    prefix <- basename(file.path(matrix2))
    df <- as.data.frame(c(prefix, corr))
    write.table(df, file="\${prefix}.${method}.txt")
    """
}
