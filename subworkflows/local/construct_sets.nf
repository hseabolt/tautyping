#!/usr/bin/env nextflow

//
// CONSTRUCT_SETS: Construct compatible sets of genes based on strength of rank correlations
//
include { CONCAT_ALIGNMENTS                       } from '../../modules/local/concat_alignments'
include { BLAST_MAKEBLASTDB as MAKEBLASTDB_UNIQUE } from '../../modules/local/makeblastdb_unique'
include { BLASTN_SETS as BLASTN                    } from '../../modules/local/blastn_sets'
include { TABLE2MATRIX                            } from '../../modules/local/table2matrix'
include { NJ_R as NJ                              } from '../../modules/local/nj'

workflow CONSTRUCT_SETS {

    take:
        ch_prepped_sets      // REQUIRED channel:  [ [meta], fasta_list   ]
		
    main:
        // Take sorted correlations file, parse into [[meta{id, corr, frx}], aln file]
        ch_sets     = Channel.empty()
        ch_versions = Channel.empty()

        // From the set of pre-prepared sets, concatenate the selected alignments
        CONCAT_ALIGNMENTS (
            ch_prepped_sets
        )
        ch_sets = ch_sets.mix(CONCAT_ALIGNMENTS.out.concat)

        // Compute all-vs-all nucleotide identity matrices for each concatenated alignment using Blastn as before,
        // Convert Blastn tabular report to a distance matrix,
        // Generate a Newick (neighbor-joining) tree from the distance matrix
        ch_dists   = Channel.empty()
        ch_nwk     = Channel.empty()
        ch_blastdb = Channel.empty()
        MAKEBLASTDB_UNIQUE (
            ch_sets
        )
        ch_blastdb = ch_blastdb.mix(MAKEBLASTDB_UNIQUE.out.db).collect()
        ch_versions = ch_versions.mix(MAKEBLASTDB_UNIQUE.out.versions)
        BLASTN(
            ch_sets, ch_blastdb
        )
        ch_versions = ch_versions.mix(BLASTN.out.versions)
        TABLE2MATRIX (
	        BLASTN.out.txt
	    )
        ch_dists = ch_dists.mix(TABLE2MATRIX.out.dist)
		NJ (
			ch_dists
		)
		ch_nwk = ch_nwk.mix(NJ.out.newick)

    emit:
        sets       = ch_sets           // channel: [ [meta], concat aln  ]
        dists      = ch_dists          // channel: [ [meta], dists       ]
        versions   = ch_versions       // channel: [ versions.yml        ]
}