#!/usr/bin/env nextflow

//
// CORE_GENOME: Compute a core genome and output alignments plus distance matrices for each core gene feature
//
include { CORRELATIONS_R                       } from '../../modules/local/correlations'
include { CAT_CAT as CAT                       } from '../../modules/nf-core/cat/cat/main'
include { SORT                                 } from '../../modules/local/sort'

workflow RANK_CORRELATIONS {

    take:
        ch_matrix1    // REQUIRED channel:  [ meta1, matrix1 ]
		ch_matrix2    // REQUIRED channel:  [ meta2, matrix2 ]   
        ch_method     // REQUIRED channel:  [ correlation   ]
		
    main:
        ch_correlations = Channel.empty()    

		// Compute rank correlations for all genes previously computed with PIRATE vs. WGS
        // Note: The Rscript here does handle matrices with different dimensions
		CORRELATIONS_R (
            ch_matrix1, ch_matrix2, ch_method
        )
        ch_correlations = ch_correlations.mix(CORRELATIONS_R.out.correlation)

		// Collate all the individual results into one results file
        ch_correlations.collect{meta, corr -> corr}.map{ corr -> [[id: 'all'], corr]}.set{ ch_merge_correlations }
        ch_sorted = Channel.empty()
        CAT (
            ch_merge_correlations
        )
        SORT (
            CAT.out.file_out
        )
        ch_sorted = ch_sorted.mix(SORT.out.file_out)
    emit:
        correlations       = ch_correlations       // channel: [ [meta], correlations        ]
        sorted_corrs       = ch_sorted             // channel: [ [meta], sorted_all          ]
}