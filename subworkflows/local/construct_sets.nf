#!/usr/bin/env nextflow

//
// CONSTRUCT_SETS: Construct compatible sets of genes based on strength of rank correlations
//
include { CORRELATIONS_R                       } from '../../modules/local/correlations'

workflow CONSTRUCT_SETS {

    take:
        ch_corrs      // REQUIRED channel:  [ [meta], correlation_file, fasta_file   ]
		ch_n          // REQUIRED channel:  [ n (integer)    ]   
        ch_k          // REQUIRED channel:  [ k (integer)    ]
		
    main:
        // Take sorted correlations file, parse into [[meta{id, corr}], aln file]
        
        

        // From user-given n (=n top ranking genes) and k (=number of genes), construct n choose k sets

        // Concatenate FASTA alignments for each set of genes assembled

        // Return [[meta{id}], concat aln]

    emit:
        correlations       = ch_correlations       // channel: [ [meta], correlations          ]
}