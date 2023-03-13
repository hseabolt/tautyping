process ONE_VS_ALL_FASTANI {
    tag "$meta.id"
    label 'process_medium'

	conda "bioconda::fastani=1.33"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastani:1.33--h0fdf51a_1' :
        'quay.io/biocontainers/fastani:1.33--h0fdf51a_1' }"

    input:
    tuple val(meta), path(query)
    path reference

    output:
    path("*.fastani.sorted.txt")      , emit: ani
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:  
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	fastANI \\
        -q $query \\
        --rl $reference \\
		$args \\
        -o ${prefix}.ani.txt
	
	sed 's+\\.fa[s][t][a]++g' ${prefix}.ani.txt | \\
	sed 's+\\/.*\\/++g' | \\
	sort -k1,1 -k2,2 > ${prefix}.fastani.sorted.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastani: \$(fastANI --version 2>&1 | sed 's/version//;')
    END_VERSIONS
    """
}
