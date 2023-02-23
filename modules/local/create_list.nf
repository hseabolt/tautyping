process CREATE_LIST {
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::pigz=2.3.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    path(sample_sheet)

    output:
	path "genomes.list"               , emit: list
    path "genomes.basenames"          , emit: basenames
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    def args = task.ext.args ?: ''
    """
	cut $args $sample_sheet | tail -n +2 > genomes.list
    
    for i in `tail +2 $sample_sheet`; do \\
        base=\$(basename \$i .fasta)
        grep "\$i" $sample_sheet | awk -v name=\$base 'BEGIN { FS="," }; { print \$1, "\\t", name }'
    done > genomes.basenames
    """
}