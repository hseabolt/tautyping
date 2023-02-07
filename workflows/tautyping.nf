/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowTautyping.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.ref_fasta, params.ref_gff, params.feature_types ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Currently no custom config files included

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK         } from '../subworkflows/local/input_check'
include { ANNOTATION_TRANSFER } from '../subworkflows/local/annotation_transfer'
include { FASTANI             } from '../subworkflows/local/fastani'
include { CORE_GENOME         } from '../subworkflows/local/core_genome'
include { RANK_CORRELATIONS   } from '../subworkflows/local/rank_correlations'

include { CREATE_LIST         } from '../modules/local/create_list'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []
workflow TAUTYPING {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    ch_all_fastas = Channel.empty()
    ch_input      = file(params.input)
    INPUT_CHECK (
        ch_input
    )
    ch_versions     = ch_versions.mix(INPUT_CHECK.out.versions)
    ch_annots_fasta = INPUT_CHECK.out.fasta
    ch_fastani_qry  = INPUT_CHECK.out.fasta
    
    //
    // SUBWORKFLOW: Transfer GFF annotations from a reference FASTA/GFF to another closely related genome
    //
    ch_ref_fasta     = file(params.ref_fasta)
    ch_ref_gff       = file(params.ref_gff)
    ch_feature_types = file(params.feature_types)
	ANNOTATION_TRANSFER (
        ch_annots_fasta, ch_ref_fasta, ch_ref_gff, ch_feature_types
    )
    ch_gffs        = ANNOTATION_TRANSFER.out.gffs
    ch_unmapped    = ANNOTATION_TRANSFER.out.unmapped
    ch_transcripts = ANNOTATION_TRANSFER.out.transcripts
    ch_versions    = ch_versions.mix(ANNOTATION_TRANSFER.out.versions)

    //
    // SUBWORKFLOW: Compute one vs. all FastANI and generate a table of genome pairs
    //
    ch_ani         = Channel.empty()
    ch_wgs_matrix  = Channel.empty()
    CREATE_LIST (
       params.input
    )
    ch_genome_list = CREATE_LIST.out.list
    FASTANI (
        ch_fastani_qry, ch_genome_list
    )
    ch_wgs_matrix    = FASTANI.out.wgs_matrix.collect()
	ch_versions      = ch_versions.mix(FASTANI.out.versions)
	
    //
    // SUBWORKFLOW: Compute a provisional "pangenome" and generate all vs. all distance matrices for each core gene in the pangenome
    // 
	ch_core_alns = Channel.empty()
	ch_genes = Channel.empty()
    CORE_GENOME (
	   ch_transcripts, ch_gffs
	)
	ch_core_alns      = ch_core_alns.mix(CORE_GENOME.out.core_aln)
    ch_genes          = ch_genes.mix(CORE_GENOME.out.dists)
	ch_versions       = ch_versions.mix(CORE_GENOME.out.versions)
	
    //
    // SUBWORKFLOW: Compute rank correlations between individual genes' distance matrices and WGS-based distance matrix
    //
    ch_method = Channel.of("kendall")
    RANK_CORRELATIONS (
        ch_wgs_matrix, ch_genes, ch_method
    )
    
    //
    // SUBWORKFLOW: Construct sets from genes with the strongest rank correlations
    //
    
    //CUSTOM_DUMPSOFTWAREVERSIONS (
    //    ch_versions.unique().collectFile(name: 'collated_versions.yml')
    //)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
