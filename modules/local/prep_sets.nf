process PREP_SETS {
    tag "$file_in"

    conda (params.enable_conda ? "conda-forge::perl=5.26.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(file_in)
    val(n)
    val(k)

    output:
    path '*.csv'       , emit: csv

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "sample\tset" > ${prefix}.csv
    tail -n +2 ${file_in} | \\
    grep -v ",NA," | \\
    awk 'BEGIN { FS = "," } ; { if (\$3 == \$4) print } ; END { OFS = ","}' | \\
    cut -f5 -d, | \\
    power_set2 -n ${n} -k ${k} -h 1 >> ${prefix}.csv
    """
}
