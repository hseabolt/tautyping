//
// Check input file of correlations and map them to FASTA channels
//

include { SAMPLESHEET_CORRELATIONS } from '../../modules/local/samplesheet_correlations'

workflow INPUT_CHECK {
    take:
    tuple val(meta), corrsheet, fasta_file         // file: /path/to/correlations.tab

    main:
    corrsheet
        .csv
        .splitCsv ( header:false, sep:"\t" )
        .map { create_fasta_channel(it) }
        .set { fasta }
    
    fasta.view()


    emit:
    fasta                                     // channel: [ val(meta), file(fasta) ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, fasta ]
def create_fasta_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row[0]
    meta.cor        = row[1]
    meta.frx        = row[3] / row[2]

    def array = []
    if (!file(row[4]]).exists()) {
        exit 1, "ERROR: Please check input file -> FASTA file does not exist!\n${row[4]]}"
    }
    array = [ meta, file(row[4]) ]
    return array
}

