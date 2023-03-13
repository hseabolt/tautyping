/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def valid_params = [
    correlation       : ['pearson', 'kendall', 'spearman'],
    distance          : ['ani', 'likelihood'],
]

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowTautyping.initialise(params, log, valid_params)

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

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                    } from '../subworkflows/local/input_check'
include { ANNOTATION_TRANSFER            } from '../subworkflows/local/annotation_transfer'
include { FASTANI                        } from '../subworkflows/local/fastani'
include { CORE_GENOME                    } from '../subworkflows/local/core_genome'
include { RANK_CORRELATIONS              } from '../subworkflows/local/rank_correlations'
include { RANK_CORRELATIONS_SETS         } from '../subworkflows/local/rank_correlations_sets'
include { PREPROCESS_SETS                } from '../subworkflows/local/preproc_sets'
include { CONSTRUCT_SETS                 } from '../subworkflows/local/construct_sets'
include { CREATE_LIST                    } from '../modules/local/create_list'
include { NJ_R as NJ_ML                  } from '../modules/local/nj'
include { FASTTREE                       } from '../modules/nf-core/fasttree/main'
include { PHANGORN_ML as PHANGORN_ML_WGS } from '../modules/local/phangorn_ml'
include { MULTIQC                        } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS    } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//



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

    // MODULE: Create some list files to be used downstream
    CREATE_LIST (
       params.input
    )
    ch_genome_list = CREATE_LIST.out.list
    ch_mappings = CREATE_LIST.out.basenames

    //
    // SUBWORKFLOW: Compute one vs. all FastANI and generate a table of genome pairs
    //
    ch_wgs_matrix  = Channel.empty()
    ch_wgs_tree    = Channel.empty()
    ch_wgs_plots   = Channel.empty()
    if ( params.distance == 'ani') {
        FASTANI (
            ch_fastani_qry, ch_genome_list, ch_mappings
        )
        ch_wgs_matrix    = FASTANI.out.wgs_matrix.collect()
        ch_wgs_tree      = ch_wgs_tree.mix(FASTANI.out.wgs_nwk_plot)
        ch_wgs_plots     = ch_wgs_plots.mix(FASTANI.out.wgs_plots)
        ch_versions      = ch_versions.mix(FASTANI.out.versions)
    }

    //
    // SUBWORKFLOW: Compute a provisional "pangenome" and generate all vs. all distance matrices for each core gene in the pangenome
    // 
	ch_core_alns = Channel.empty()
	ch_genes = Channel.empty()
    ch_dists = Channel.empty()
    
    CORE_GENOME (
	   ch_transcripts, ch_gffs
	)
	ch_core_alns      = ch_core_alns.mix(CORE_GENOME.out.core_aln)
    ch_genes          = ch_genes.mix(CORE_GENOME.out.genes)
    ch_dists          = ch_dists.mix(CORE_GENOME.out.dists)
	ch_versions       = ch_versions.mix(CORE_GENOME.out.versions)

    if ( params.distance == 'likelihood') {
        PHANGORN_ML_WGS (
            ch_core_alns
        )
        ch_wgs_matrix    = PHANGORN_ML_WGS.out.dist.collect()
        FASTTREE (
            ch_core_alns.collect{it[1]}
        )
        ch_versions       = ch_versions.mix(FASTTREE.out.versions)
        NJ_ML (
            ch_wgs_matrix
        )
        ch_wgs_tree      = ch_wgs_tree.mix(NJ_ML.out.png)
    }

    //
    // SUBWORKFLOW: Compute rank correlations between individual genes' distance matrices and WGS-based distance matrix
    //
    ch_method       = Channel.of(params.correlation)
    ch_correlations = Channel.empty()
    ch_sorted_corrs = Channel.empty()
    ch_histograms   = Channel.empty()
    RANK_CORRELATIONS (
        ch_wgs_matrix, ch_dists, ch_method.first(), ch_genes
    )
    ch_correlations = ch_correlations.mix(RANK_CORRELATIONS.out.correlations)
    ch_sorted_corrs = ch_sorted_corrs.mix(RANK_CORRELATIONS.out.sorted_corrs)
    ch_histograms   = ch_histograms.mix(RANK_CORRELATIONS.out.png)
    ch_versions     = ch_versions.mix(RANK_CORRELATIONS.out.versions)

    //
    // SUBWORKFLOW: Construct required channels for subsequent set construction
    //
    ch_preproc_sets = Channel.empty()
    PREPROCESS_SETS(
        ch_sorted_corrs, params.n, params.k, params.kmin, params.kmax
    )
    ch_preproc_sets = ch_preproc_sets.mix(PREPROCESS_SETS.out.fasta)

    //
    // SUBWORKFLOW: Construct sets from genes with the strongest rank correlations
    //
    ch_sets      = Channel.empty()
    ch_sets_dist = Channel.empty()
    CONSTRUCT_SETS(
        ch_preproc_sets
    )
    ch_sets      = ch_sets.mix(CONSTRUCT_SETS.out.sets)
    ch_sets_dist = ch_sets_dist.mix(CONSTRUCT_SETS.out.dists)

    //
    // SUBWORKFLOW: Compute rank correlations between gene sets' distance matrices and WGS-based distance matrix
    //
    ch_correlations_sets  = Channel.empty()
    ch_sorted_sets        = Channel.empty()
    ch_histograms_sets    = Channel.empty()
    RANK_CORRELATIONS_SETS (
        ch_wgs_matrix, ch_sets_dist, ch_method.first(), ch_sets
    )
    ch_correlations_sets = ch_correlations_sets.mix(RANK_CORRELATIONS_SETS.out.correlations)
    ch_sorted_sets       = ch_sorted_sets.mix(RANK_CORRELATIONS_SETS.out.sorted_corrs)
    ch_histograms_sets   = ch_histograms_sets.mix(RANK_CORRELATIONS_SETS.out.png)
    ch_versions          = ch_versions.mix(RANK_CORRELATIONS_SETS.out.versions)

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowTautyping.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowTautyping.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_wgs_tree.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_wgs_plots.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_histograms.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_sorted_corrs.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_histograms.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_sorted_sets.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_histograms_sets.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))


    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
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
