process PREPARE_REFERENCE {
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::perl=5.32.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

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
    cat ${gff_in} | \\
    perl -e '{
        while (<STDIN>) { 
            chomp \$_; 
            if ( \$_ =~ /^##/ ) { 
                print "\$_\\n";
            } 
            else { 
                @line = split("\\t", \$_); 
                if (scalar @line != 9) {
                    print join("\\t", @line), "\\n";
                }
                @annots = split(";", \$line[8]); 
                foreach my \$feature ( @annots ) {
                    last if ( grep(/^gene=/, @annots) );
                    if ( \$feature =~ /^locus_tag=/i ) { 
                        \$name = \$feature; 
                        \$name =~ s/locus_tag=//i;
                        \$name =~ s/_//;
                        \$feature = \$feature . ";gene=\$name";
                    } 
                } 
                \$line[8] = join(";", @annots); 
                print join("\\t", @line), "\\n"; 
            }
        }
    }' > ${prefix}.tmp.gff
    
    if grep -q -w '##FASTA' ${prefix}.tmp.gff; then
         cat ${prefix}.tmp.gff > ${prefix}.valid.gff
    else 
        cat ${prefix}.tmp.gff > ${prefix}.valid.gff
        echo "##FASTA" >> ${prefix}.valid.gff
        cat ${fasta_in} >> ${prefix}.valid.gff
    fi

    rm ${prefix}.tmp.gff
    """
}