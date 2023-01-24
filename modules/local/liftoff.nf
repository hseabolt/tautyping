process LIFTOFF {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::liftoff=1.6.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/liftoff:1.6.3--pyhdfd78af_0' :
        'quay.io/biocontainers/liftoff' }"

    input:
    tuple val(meta), path(inputFASTA)
	path(refFASTA)
	path(refGFF)
	path(feature_types)

    output:
    tuple val(meta), path("*.liftoff.gff"),    emit: gff
	path("*.unmapped_features.txt"),           emit: unmapped
    path "versions.yml",                       emit: versions
	
	when:
    task.ext.when == null || task.ext.when
	
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ftypes = feature_types ? "-f $feature_types" : ""
    """
    liftoff \\
    -g $refGFF \\
    -u ${prefix}.unmapped_features.txt \\
    -o ${prefix}.liftoff.gff \\
    -p $task.cpus \\
    $ftypes \\
    $args \\
    $inputFASTA \\
    $refFASTA 
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        liftoff: \$(liftoff --version | sed 's/v//')
    END_VERSIONS
    """
}

process LIFTOFF_FASTA {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::liftoff=1.6.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/liftoff:1.6.3--pyhdfd78af_0' :
        'quay.io/biocontainers/liftoff' }"

    input:
    tuple val(meta), path(inputFASTA)
	path(refFASTA)
	path(refGFF)
	path(feature_types)

    output:
    tuple val(meta), path("*.liftoff.gff"),    emit: gff
	path("*.unmapped_features.txt"),           emit: unmapped
    path "versions.yml",                       emit: versions
	
	when:
    task.ext.when == null || task.ext.when
	
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ftypes = feature_types ? "-f $feature_types" : ""
    """
    liftoff \\
    -g $refGFF \\
    -u ${prefix}.unmapped_features.txt \\
    -o ${prefix}.liftoff.gff \\
    -p $task.cpus \\
    $ftypes \\
    $args \\
    $inputFASTA \\
    $refFASTA 
	
	echo "##FASTA" >> ${prefix}.liftoff.gff \
	cat $inputFASTA >> ${prefix}.liftoff.gff
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        liftoff: \$(liftoff --version | sed 's/v//')
    END_VERSIONS
    """
}
