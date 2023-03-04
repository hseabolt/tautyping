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
    val(kmin)
    val(kmax)

    output:
    path '*.csv'       , emit: csv

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"
    def awk    = task.ext.awk ?: ""
    def ps2_k_args = ""
    if (kmin != -1 && kmax != -1) {
        ps2_k_args = "-kmin ${kmin} -kmax ${kmax}"
    } else if (kmax && kmin == -1)   {
        ps2_k_args = "-kmax ${kmax}"
    } else if (kmin && kmax == -1)   {
        ps2_k_args = "-kmin ${kmin}"
    } else {
        ps2_k_args = "-k ${k}"
    }
    """
    grep -v ",NA," ${file_in} | \\
    ${awk} \\
    cut -f5 -d, > sets.tmp
    echo -e "sample\tset" > ${prefix}.csv
    power_set2 -i sets.tmp -n ${n} ${ps2_k_args} -h 1 >> ${prefix}.csv
    rm sets.tmp
    """
}
