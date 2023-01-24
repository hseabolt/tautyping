#!/usr/bin/env nextflow

//
// ANNOTATION_TRANSFER: Transfer GFF annotations from a reference FASTA/GFF to another closely related genome
//
include { LIFTOFF_FASTA as LIFTOFF } from '../../modules/local/liftoff'
include { GFFREAD } from '../../modules/nf-core/gffread/main'


workflow ANNOTATION_TRANSFER {

    take:
        ch_all_fastas     // REQUIRED channel:  [meta, fasta]
		ref_fasta         // REQUIRED filepath: path to reference genome in FASTA format  
        ref_gff           // REQUIRED filepath: path reference genome annotations in GFF format to be transferred to target genome(s)
		feature_types     // OPTIONAL filepath: path to list of GFF feature types to use for annotation transfer (e.g. CDS, rRNA, gene)
		
    main:
        ch_gffs     = Channel.empty()
        ch_unmapped = Channel.empty()
        ch_versions = Channel.empty()
		
		// Transfer reference annotations to target genome with Liftoff
		LIFTOFF (
            ch_all_fastas, ref_fasta, ref_gff, feature_types 
        )
        ch_gffs     = ch_gffs.mix(LIFTOFF.out.gff)
		ch_unmapped = ch_unmapped.mix(LIFTOFF.out.unmapped)
		ch_versions = ch_versions.mix(LIFTOFF.out.versions)
		
		// Extend Liftoff post-processing here as needed
		// Consider post-processing GFFs from Liftoff for specific feature types
     
        // Extracting transcript sequences from each genome
        ch_transcripts = Channel.empty()
        GFFREAD (
            ch_all_fastas.join(ch_gffs)
        )
        ch_transcripts = ch_transcripts.mix(GFFREAD.out.transcripts)
        ch_versions = ch_versions.mix(GFFREAD.out.versions)

    emit:
        gffs     = ch_gffs           // channel: [ [meta], gff  ]
		unmapped = ch_unmapped       // channel: [ [meta], unmapped  ]
        transcripts = ch_transcripts // channel: [ [meta], transcripts ]
        versions = ch_versions       // channel: [ versions.yml ]
}