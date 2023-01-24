#!/usr/bin/env nextflow

//
// CORE_GENOME: Compute a core genome and output alignments plus distance matrices for each core gene feature
//
include { PIRATE                           } from '../../modules/nf-core/pirate/main'
include { BLAST_MAKEBLASTDB as MAKEBLASTDB } from '../../modules/nf-core/blast/makeblastdb/main'
include { BLAST_BLASTN as BLASTN           } from '../../modules/nf-core/blast/blastn/main'


workflow CORE_GENOME {

    take:
        ch_cds   // REQUIRED channel:  [meta, fasta]
		ch_gffs  // REQUIRED channel:  [meta, gff  ]   

		
    main:
        ch_core_aln = Channel.empty()
		ch_pirate_results = Channel.empty()
        ch_versions = Channel.empty()
		
		// Compute a pangenome and core alignments
		ch_gffs.collect{meta, gff -> gff}.map{ gff -> [[id: 'pangenome'], gff]}.set{ ch_merge_gff }
		PIRATE (
            ch_merge_gff
        )
        ch_core_aln     = ch_core_aln.mix(PIRATE.out.aln)
		ch_pirate_results = ch_pirate_results.mix(PIRATE.out.results)
		ch_versions = ch_versions.mix(PIRATE.out.versions)


    emit:
        core_aln       = ch_core_aln       // channel: [ [meta], gff          ]
		pirate_results = ch_pirate_results // channel: [ [meta], results_dir  ]
        versions       = ch_versions       // channel: [ versions.yml         ]
}