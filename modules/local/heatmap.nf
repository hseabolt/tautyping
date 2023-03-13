process HEATMAP_FASTANI_R {
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
	tuple val(meta), path("*_all-vs-all_ANI_mqc.png")              , emit: ani
    tuple val(meta), path("*_all-vs-all_Jaccard_mqc.png")          , emit: jaccard
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla
    library(ggplot2)
    heats = as.data.frame(read.table(file="${csv_file}", sep="\\t"))
    colnames(heats) <- c("Genome1", "Genome2", "ANI", "FragsA", "FragsB")
    heats\$Jaccard = round(heats\$FragsA/heats\$FragsB, 4)
    ggplot(heats, aes(Genome1, Genome2, fill=ANI)) + geom_tile() + 
        theme(axis.text.x=element_text(angle=45, vjust=0.85, hjust=1)) + 
        scale_fill_gradient(low="darkred", high="lightgoldenrodyellow")
    ggsave("${prefix}_all-vs-all_ANI_mqc.png", dpi=300, height=8, width=8, units="in")
    
    ggplot(heats, aes(Genome1, Genome2, fill=Jaccard)) + geom_tile() + 
        theme(axis.text.x=element_text(angle=45, vjust=0.85, hjust=1)) + 
        scale_fill_gradient(low="navy", high="lightgoldenrodyellow")
    ggsave("${prefix}_all-vs-all_Jaccard_mqc.png", dpi=300, height=8, width=8, units="in")
    """
}
