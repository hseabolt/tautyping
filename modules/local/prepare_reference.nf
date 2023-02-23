process PREPARE_REFERENCE {
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::pigz=2.3.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    path(fasta_in)
    path(gff_in)

    output:
	path(fasta_in)        , emit: fasta
    path("*.valid.gff")   , emit: gff
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "ref"
    """
    if grep -q -w '##FASTA' ${gff_in}; then
         cat ${gff_in} > ${prefix}.valid.gff
    else 
        cat ${gff_in} > ${prefix}.valid.gff
        echo "##FASTA" >> ${prefix}.valid.gff
        cat ${fasta_in} >> ${prefix}.valid.gff
    fi
    """
}