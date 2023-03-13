process TABLE2MATRIX {
    tag "$meta.id"
    label "process_low"

    conda "conda-forge::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(table)

    output:
    tuple val(meta), path("*.dist"), optional:true     , emit: dist
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [ -s $table ]; then
        table2matrix -i $table $args > ${prefix}.dist
    else
        rm $table
    fi
    """
}
