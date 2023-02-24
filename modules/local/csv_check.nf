process CSV_CHECK {
    tag "$file_in"

        conda (params.enable_conda ? "conda-forge::pigz=2.3.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    tuple val(meta), path(file_in)

    output:
    path '*.csv'       , emit: csv

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat $file_in | grep -v ",NA," > ${prefix}.valid.csv
    """
}
