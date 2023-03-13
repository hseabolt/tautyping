process HISTOGRAM_R {
    tag "$meta.id"
    label 'process_low'
    label 'error_ignore'

	conda "conda-forge::r-ggplot2=3.4.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-genomicsupersignature:1.6.0--r42hdfd78af_0' :
        'quay.io/biocontainers/bioconductor-genomicsupersignature:1.6.0--r42hdfd78af_0' }"

    input:
    tuple val(meta), path(csv_file)

    output:
	tuple val(meta), path("*_mqc.png")              , emit: png
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def title = task.ext.title ?: "Rank Correlations"
    """
	#!/usr/bin/env Rscript --vanilla
    library(ggplot2)

    ranks  <- as.data.frame(read.table(file="${csv_file}", sep=",", header=T))
    ranks  <- ranks[which(ranks\$correlation != "NA"), ]
    ggplot(ranks, aes(x=correlation)) + geom_histogram(fill="black", colour="gray", bins=25) +
        xlab("Corelation Coefficient") + ylab("Frequency") + ggtitle("${title}")
    ggsave("${prefix}_mqc.png", dpi=300, height=8, width=8, units="in")
    """
}
