process BLAST_MAKEBLASTDB {
    tag "$fasta"
    label 'process_medium'

    conda "bioconda::blast=2.12.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.12.0--pl5262h3289130_0' :
        'quay.io/biocontainers/blast:2.12.0--pl5262h3289130_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    path "blast_db_${meta.id}" , emit: db

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    makeblastdb \\
        -in $fasta \\
        $args
    mkdir blast_db_${meta.id}
    mv ${fasta}* blast_db_${meta.id}
    """
}
