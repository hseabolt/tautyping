#!/usr/bin/env nextflow

//
// FASTANI: Compute one vs. all ANI using a modified version of nf-core FastANI module
//
include { ONE_VS_ALL_FASTANI } from '../../modules/local/one_vs_all_fastani'


workflow FASTANI {

    take:
        query       // REQUIRED channel:  [meta, fasta]
        ref_list    // REQUIRED filepath: path to file containing all genomes to compute ANI vs the query genome.
		
    main:
	    ch_ani      = Channel.empty()
        ch_versions = Channel.empty()
		
		// Transfer reference annotations to target genome with Liftoff
		ONE_VS_ALL_FASTANI (
            query, reflist
        )
        ch_ani     = ch_ani.mix(ONE_VS_ALL_FASTANI.out.ani)
		ch_versions = ch_versions.mix(ONE_VS_ALL_FASTANI.out.versions)
		
		// TODO: Extend genome relatedness comparisons (e.g. with maximum likelihood, AAI, etc.) as desired
		

    emit:
        ani      = ch_ani        // channel: [ [meta], ani  ]
        versions = ch_versions    // channel: [ versions.yml ]
}