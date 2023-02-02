#!/usr/bin/env nextflow

//
// FASTANI: Compute one vs. all ANI using a modified version of nf-core FastANI module
//
include { ONE_VS_ALL_FASTANI as FASTANI_ONE_VS_ALL } from '../../modules/local/one_vs_all_fastani'
include { TABLE2MATRIX as TABLE2MATRIX_WGS         } from '../../modules/local/table2matrix'
include { NJ_R as NJ_WGS                           } from '../../modules/local/nj'

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
	    //result.ANI.collectFile(name: 'WGS.fastani.txt', storeDir: "${params.outdir}/fastani")
		ch_wgs_ani = result.ANI.collectFile(name: 'WGS.fastani.txt', storeDir: "${params.outdir}/fastani")

		// Convert the compiled WGS fastANI file to a symmetrical matrix and sort it
        ch_wgs_matrix = Channel.empty()
		ch_meta = Channel.of( ['id' : 'WGS'] )
		ch_wgs_ani = ch_meta.combine(ch_wgs_ani)
		TABLE2MATRIX_WGS (
	        ch_wgs_ani
	    )
		ch_wgs_matrix = ch_wgs_matrix.mix(TABLE2MATRIX_WGS.out.dist)

		// Generate a Newick (neighbor-joining) tree from the distance matrix
		ch_wgs_nwk = Channel.empty()
		NJ_WGS (
			TABLE2MATRIX_WGS.out.dist
		)
		ch_wgs_nwk = ch_wgs_nwk.mix(NJ_WGS.out.newick)
		
    emit:
        ani        = ch_ani                                                     // channel: [ ani  ]
		wgs_matrix = ch_wgs_matrix                                              // channel: [ meta, dist ]
		wgs_tree   = ch_wgs_nwk                                                 // channel: [ meta, nwk  ]
        versions   = ch_versions                                                // channel: [ versions.yml ]
}