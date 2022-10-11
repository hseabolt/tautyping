//
// Subworkflow : Pangenome & Clustering
//

// Include

// include{ NF-CORE_}
include { NF-CORE_VSEARCH_USEARCHGLOBAL as VSEARCH_USEARCHGLOBAL            } from  '../modules/nf-core/modules/nf-core/vsearch/usearchglobal/main'


workflow PANGENOME {
    take:
    gff per assembly           // channel [val(meta), gff?]
    scaffols per assembly


    main:
    ch_versions      = Channel.empty()
    
    GFF_READ(
        gff
    )
    ch_gffread = GFF_READ.out.gtf
    ch_versions = ch_versions.mix(GFF_READ.versions.first().ifEmpty(null))
    // Extract CDS nucl sequences using GFF/scaffolds for each assembly,
    // compile all CDS into one global set (will contain redundant seqs)

    // Cluster/deduplicate CDS seqs (=reference genes)
    VSEARCH_USEARCHGLOBAL(
        
    )
    
    
    
    map trimmed reads from Kraken2 back to the set of reference genes to determine which genes are present in each assembly
    identify homologous genes in each mapped set of reads --> generate alignment of each gene
    separate out core,auxillary,unique genes into discrete subsets

    emit:
    
}
    

