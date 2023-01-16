//
// This file holds several functions specific to the workflow/tautyping.nf in the nf-core/tautyping pipeline
//

class WorkflowTautyping {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        genomeExistsError(params, log)

        if (!params.ref_fasta) {
            log.error "Reference genome FASTA file not specified with e.g. '--ref_fasta genome.fasta' or via a detectable config file."
            System.exit(1)
        }
		if (!params.ref_gff) {
            log.error "Reference genome GFF file not specified with e.g. '--ref_gff annots.gff' or via a detectable config file."
            System.exit(1)
        }
    }
}
