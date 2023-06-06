process CREATE_LIST {
    label 'process_low'

    conda "conda-forge::perl=5.32.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(fasta)
    path(samplesheet)

    output:
	path "genomes.list"               , emit: list
    path "genomes.basenames"          , emit: basenames
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    def args = task.ext.args ?: ''
    //def name = "${fasta.getSimpleName()}"
    """
	echo "\$(realpath ${fasta})" >> genomes.list
    
    BASE=\$(basename ${fasta} | sed "s/\\.fa.*\$//")
    grep "${fasta}" $samplesheet | awk -v name=\$BASE 'BEGIN { FS="," }; { print \$1, "\\t", name }' >> genomes.basenames
    """
}