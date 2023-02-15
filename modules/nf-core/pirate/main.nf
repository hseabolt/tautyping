process PIRATE {
    tag "$meta.id"
    label 'process_medium'
    
	conda (params.enable_conda ? "bioconda::pirate=1.0.4 bioconda::perl-bioperl=1.7.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pirate:1.0.4--hdfd78af_2' :
        'quay.io/biocontainers/pirate:1.0.4--hdfd78af_2' }"

    input:
    tuple val(meta), path(gff)
	
    output:
    tuple val(meta), path("results/*")                                        , emit: results
    tuple val(meta), path("results/core_alignment.fasta"), optional: true     , emit: aln
    tuple val(meta), path("results/pangenome_alignment.fasta"), optional: true, emit: pangenome
	path("results/feature_sequences/*.fasta"), optional: true                 , emit: genes
    path "versions.yml"                                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Note: this module has been tailored to include post-processing specific to the Tau-Typing pipeline
    """
    PIRATE \\
        $args \\
        --threads $task.cpus \\
        --input ./ \\
        --output results/

    sed -i "s/_liftoff*//g" results/core_alignment.fasta
    sed -i "s/_liftoff*//g" results/pangenome_alignment.fasta
    for i in `ls results/feature_sequences/*.fasta`; do \\
        sed -i "s/_liftoff.*//g" \$i
        NAME=\$(basename \$i .nucleotide.fasta)
        GENE=\$(grep -w "ID=\$NAME" results/pangenome_alignment.gff | cut -f9 | cut -f2 -d ';' | sed 's/gene=//')
        mv \$i results/feature_sequences/\$GENE.fasta
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pirate: \$( echo \$( PIRATE --version 2>&1) | sed 's/PIRATE //' )
    END_VERSIONS
    """
}
