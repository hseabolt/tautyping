//
// Check input file of correlations and map them to FASTA channels
//
include { CSV_CHECK } from '../../modules/local/csv_check'

workflow PREPROCESS_SETS {
    take:
    corrsheet        // channel: [ val(meta), file(/path/to/correlations.csv) ]

    main:
    CSV_CHECK( corrsheet )
        .csv
        .splitCsv ( header:true, sep:"," )
        .map { create_fasta_channel(it) }
        .set { fasta }

    emit:
    fasta                                     // channel: [ val(meta), file(fasta) ]
}

// Function to get list of [ meta, fasta ]
def create_fasta_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    int A = "${row.fragsA}".toInteger()
    int B = "${row.fragsB}".toInteger()
    meta.id         = row.sample
    meta.cor        = row.correlation
    meta.frx        = B/A

    def array = []
    if (!file(row.fasta).exists()) {
        exit 1, "ERROR: Please check input file -> FASTA file does not exist!\n${row.fasta}"
    }
    array = [ meta, file(row.fasta) ]
    return array
}

