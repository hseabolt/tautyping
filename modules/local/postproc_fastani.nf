process FASTANI_POSTPROC {
    tag "$meta.id"
    label 'process_low'

	conda (params.enable_conda ? "conda-forge::perl=5.32.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(fastani)
    path mappings

    output:
    tuple val(meta), path("*.fastani.final.txt")      , emit: ani

    when:
    task.ext.when == null || task.ext.when

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}" 
    """
    postproc_fastani.pl \\
    --in ${fastani} \\
    --map ${mappings} | \\
    sed 's/-/_/g' | \\
    sort -k1,1 -k2,2 > ${prefix}.fastani.final.txt
    """
}