#!/usr/bin/env nextflow

//
// CORE_GENOME: Compute a core genome and output alignments plus distance matrices for each core gene feature
//
include { CORRELATIONS_R                       } from '../../modules/local/correlations'

workflow RANK_CORRELATIONS {

    take:
        ch_matrix1    // REQUIRED channel:  [ meta, matrix1 ]
		ch_matrix2    // REQUIRED channel:  [ meta, matrix2 ]   
        ch_method     // REQUIRED channel:  [ correlation   ]
		
    main:
        ch_correlations = Channel.empty()

		// Compute a pangenome and core alignments
		CORRELATIONS_R (
            ch_matrix1, ch_matrix2, ch_method
        )
        ch_correlations = ch_correlations.mix(CORRELATIONS_R.out.correlation)

		// Collate all the individual results into one results file
	    correlations_out = CORRELATIONS_R.out.correlation.collectFile()
	    correlations_out.branch{ COR: it.name.contains("*.kendall.txt") }.set { result }
	    result.COR.collectFile(name: 'correlations.txt', storeDir: "${params.outdir}/correlations")

    emit:
        correlations       = ch_correlations       // channel: [ correlations        ]
}