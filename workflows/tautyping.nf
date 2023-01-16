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

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

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

include { CREATE_LIST         } from '../modules/local/create_list'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

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
	ch_feature_types = Channel.empty()
	ch_tmpdir        = Channel.empty()
	if(params.feature_types != null)    {   ch_feature_types  = Channel.fromPath(params.feature_types, checkIfExists:true).first()    }
	if(params.tmpdir != null)           {   ch_tmpdir         = Channel.fromPath(params.tmpdir, checkIfExists:true).first()           }
    ANNOTATION_TRANSFER (
	    ch_annots_fasta, ch_ref_fasta, ch_ref_gff, ch_feature_types, ch_tmpdir
	}
    ch_gffs       = ANNOTATION_TRANSFER.out.gffs
	ch_unmapped   = ANNOTATION_TRANSFER.out.unmapped
	ch_versions   = ch_versions.mix(ANNOTATION_TRANSFER.out.versions)

    //
	// SUBWORKFLOW: Compute one vs. all FastANI and generate a table of genome pairs
    //
	ch_ani         = Channel.empty()
	CREATE_LIST (
	   params.input
	)
	ch_genome_list = CREATE_LIST.out.list
	FASTANI (
	    ch_fastani_qry, ch_genome_list
	)
	ch_ani        = FASTANI.out.ani
	ch_versions   = ch_versions.mix(FASTANI.out.versions)
	
	
	//
	// SUBWORKFLOW: Compute a provisional "pangenome" and generate all vs. all distance matrices for each core gene in the pangenome
    // 
	
	//
	// SUBWORKFLOW: Compute rank correlations between individual genes' distance matrices and WGS-based distance matrix
	//
	
	
	//
	// SUBWORKFLOW: Construct sets from genes with the strongest rank corrlations
	//
	

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
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
