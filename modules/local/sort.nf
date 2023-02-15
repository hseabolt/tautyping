process SORT {
	tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::pigz=2.3.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    tuple val(meta), path(file_in)

    output:
    tuple val(meta), path("*.sorted.txt"), emit: file_out
	
    when:
    task.ext.when == null || task.ext.when

    script:  
	def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${file_in.SimpleName}"
    """
	sort $args ${file_in} > ${prefix}.sorted.txt
    """
}