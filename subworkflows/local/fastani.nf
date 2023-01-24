#!/usr/bin/env nextflow

//
// FASTANI: Compute one vs. all ANI using a modified version of nf-core FastANI module
//
include { ONE_VS_ALL_FASTANI as FASTANI_ONE_VS_ALL } from '../../modules/local/one_vs_all_fastani'
include { SORT as SORT_WGS    } from '../../modules/local/sort'

workflow FASTANI {

    take:
        query       // REQUIRED channel:  [meta, fasta]
        ref_list    // REQUIRED filepath: path to file containing all genomes to compute ANI vs the query genome.
		
    main:
	    ch_ani      = Channel.empty()
        ch_versions = Channel.empty()
		
		// Transfer reference annotations to target genome with Liftoff
		FASTANI_ONE_VS_ALL (
            query, ref_list
        )
        ch_ani      = ch_ani.mix(FASTANI_ONE_VS_ALL.out.ani)
		ch_versions = ch_versions.mix(FASTANI_ONE_VS_ALL.out.versions)
		
		// Collate all the individual results into one results file
	    fastani_out = FASTANI_ONE_VS_ALL.out.ani.collectFile()
	    fastani_out.branch{ ANI: it.name.contains('fastani.sorted.txt') }.set { result }
	    result.ANI.collectFile(name: 'WGS.fastani.txt', storeDir: "${params.outdir}/fastani")
		
		// TODO: Figure out how to get this subworkflow to correctly sort the compiled WGS fastANI file
        // SORT_WGS (
	    //    result.ANI.collectFile(name: 'WGS.fastani.txt', storeDir: "${params.outdir}/fastani")
	    //)
		
    emit:
        ani      = ch_ani                                                     // channel: [ ani  ]
        versions = ch_versions                                                // channel: [ versions.yml ]
}