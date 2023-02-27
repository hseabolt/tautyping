//
// Check input file of correlations and map them to FASTA channels
//
include { PREP_SETS } from '../../modules/local/prep_sets'
include { CSV_CHECK } from '../../modules/local/csv_check'

workflow PREPROCESS_SETS {
    take:
    corrsheet        // channel: [ val(meta), file(/path/to/correlations.csv) ]
    ch_n             // value  : params.n
    ch_k             // value  : params.k
    //ch_m             // value  : params.m

    main:
    PREP_SETS( corrsheet, ch_n, ch_k)
        .csv
        .splitCsv ( header:true, sep:"\t" )
        .map { create_fastalist_channel(it) }
        .set { fasta }

    emit:
    fasta                                     // emits a list channel with each element as: [ val(meta), file(fasta) ]
}

// Function to get list of [ meta, fasta ] from the sorted correlations list file
def create_correlations_channel(LinkedHashMap row) {
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

// Function to get list of [ meta, fasta_list ]
def create_fastalist_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id  = row.sample
    array    = [ meta, "${row.set}" ]
    return array
}
