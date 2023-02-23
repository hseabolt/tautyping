//
// This file holds several functions specific to the workflow/tautyping.nf in the nf-core/tautyping pipeline
//

class WorkflowTautyping {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log, valid_params) {
        
        // Check input reference FASTA and GFF files exist
        if (!params.ref_fasta) {
            log.error "Reference genome FASTA file not specified with e.g. '--ref_fasta genome.fasta' or via a detectable config file."
            System.exit(1)
        }
		if (!params.ref_gff) {
            log.error "Reference genome GFF file not specified with e.g. '--ref_gff annots.gff' or via a detectable config file."
            System.exit(1)
        }

        // Check that the user specified a valid genetic distance (either ANI or ML)
        if (!valid_params['distance'].contains(params.distance)) {
            log.error "Invalid option: '${params.distance}'. Valid options for '--distance': ${valid_params['distance'].join(', ')}."
            System.exit(1)
        }

        // Check that the user specified a valid correlation measture (one of pearson, kendall, or spearman)
        if (!valid_params['correlation'].contains(params.correlation)) {
            log.error "Invalid option: '${params.correlation}'. Valid options for '--correlation': ${valid_params['correlation'].join(', ')}."
            System.exit(1)
        }
    }
}
