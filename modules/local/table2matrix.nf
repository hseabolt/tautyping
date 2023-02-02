process TABLE2MATRIX {
    tag "$meta.id"
    label "process_low"

    input:
    tuple val(meta), path(table)

    output:
    tuple val(meta), path("*.dist")               , emit: dist
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    table2matrix -i $table $args > ${prefix}.dist
    """
}
