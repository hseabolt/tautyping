process TABLE2MATRIX {
    tag "$meta.id"
    label "process_low"

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
