process CONCAT_ALIGNMENTS {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), val(fasta_list)

    output:
	tuple val(meta), path("*.concat.fasta")              , emit: concat
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	concat_alignments.pl --input ${fasta_list} > ${prefix}.concat.fasta
    """
}
