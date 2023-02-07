#!/usr/bin/env nextflow

//
// CORE_GENOME: Compute a core genome and output alignments plus distance matrices for each core gene feature
//
include { PIRATE                           } from '../../modules/nf-core/pirate/main'
include { BLAST_MAKEBLASTDB as MAKEBLASTDB } from '../../modules/nf-core/blast/makeblastdb/main'
include { BLAST_BLASTN as BLASTN           } from '../../modules/nf-core/blast/blastn/main'
include { TABLE2MATRIX                     } from '../../modules/local/table2matrix'
include { NJ_R as NJ                       } from '../../modules/local/nj'


workflow CORE_GENOME {

    take:
        ch_cds   // REQUIRED channel:  [meta, fasta]
		ch_gffs  // REQUIRED channel:  [meta, gff  ]   

		
    main:
        ch_core_aln = Channel.empty()
		ch_genes    = Channel.empty()
        ch_pan_aln  = Channel.empty()
        ch_versions = Channel.empty()
		
		// Compute a pangenome and core alignments
		ch_gffs.collect{meta, gff -> gff}.map{ gff -> [[id: 'pangenome'], gff]}.set{ ch_merge_gff }
		PIRATE (
            ch_merge_gff
        )
        ch_core_aln     = ch_core_aln.mix(PIRATE.out.aln)
        ch_pan_aln      = ch_pan_aln.mix(PIRATE.out.pangenome)
		ch_genes        = ch_genes.mix(PIRATE.out.genes)
		ch_versions     = ch_versions.mix(PIRATE.out.versions)

        // Hash gene names to meta, pass each gene to Blast for all-vs-all comparisons
        ch_genes = ch_genes.flatten()
        ch_genes = ch_genes.map{ it -> tuple( ['id': it.baseName], it) }

        // Compute all-vs-all nucleotide identity matrices for each core gene using Blastn,
        // Then, convert Blastn tabular report to a distance matrix,
        // Last, generate a Newick (neighbor-joining) tree from the distance matrix
        ch_dists   = Channel.empty()
        ch_nwk     = Channel.empty()
        ch_blastdb = Channel.empty()
        MAKEBLASTDB(
            ch_pan_aln.map{ meta, fasta -> fasta }
        )
        ch_blastdb = ch_blastdb.mix(MAKEBLASTDB.out.db).collect()
        BLASTN(
            ch_genes, ch_blastdb
        )
        TABLE2MATRIX (
	        BLASTN.out.txt
	    )
        ch_dists = ch_dists.mix(TABLE2MATRIX.out.dist)
		NJ (
			ch_dists
		)
		ch_nwk = ch_nwk.mix(NJ.out.newick)


    emit:
        core_aln       = ch_core_aln       // channel: [ [meta], core_fasta       ]
        pan_aln        = ch_pan_aln        // channel: [ [meta], pangenome_fasta  ]
		genes          = ch_genes          // channel: [ [meta], genes            ]
        dists          = ch_dists          // channel: [ [meta], dists            ]
        versions       = ch_versions       // channel: [ versions.yml             ]
}
