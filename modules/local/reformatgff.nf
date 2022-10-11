process REFORMAT_GFF {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::pigz=2.3.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4':
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    tuple val(meta), path(contigs), path(annotations)

    output:
    tuple val(meta), path('*.reformat.gff')      , emit: gff

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat ${annotations} | grep -v "#" > ${prefix}.reformat.gff
    echo "##FASTA" >> ${prefix}.reformat.gff
    zcat ${contigs} >> ${prefix}.reformat.gff 
    """
}
