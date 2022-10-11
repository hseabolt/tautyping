process AUGUSTUS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::augustus=3.5.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.5.0--pl5321hf46c7bb_0' :
        'quay.io/biocontainers/augustus:3.5.0' }"

    input:
    tuple val(meta), path(fasta)
    val(species)                                // Must be a valid species bundled with Augustus models

    output:
    tuple val(meta), path('*.predictions.gff.gz')       , emit: gff

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/tautyping/bin/
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxmem = task.memory
    """
    augustus --species=${species} ${fasta} | \\
    gzip > ${prefix}.predictions.gff.gz
    """
}