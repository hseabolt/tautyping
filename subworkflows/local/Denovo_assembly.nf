//
// Subworkflow : Denovo Assembly - upstream assembly pipeline
//

include { FASTQC as FASTQC_RAW                   } from '../modules/nf-core/modules/nf-core/fastqc/main'
include { NF-CORE_FASTP as FASTP                 } from '../modules/nf-core/modules/nf-core/fastp/main'
include { FASTQC as FASTQC_TRIMMED               } from '../modules/nf-core/modules/nf-core/fastqc/main'
include { NF-CORE_KRAKEN2_KRAKEN2 as KRAKEN2     } from '../modules/nf-core/modules/nf-core/kraken2/kraken2/main'
include { NF-CORE_BBMAP_BBDUK as BBDUK           } from '../modules/nf-core/modules/nf-core/bbmap/bbduk/main'
include { SKESA                                  } from '/scicomp/home-pure/ngr8/SCBS/nf-core/nf-core-tautyping/modules/local/skesa.nf'
// Include statement for Skesa

workflow DE_NOVO_ASSEMBLY {
    take:
    reads      // channel: [ val(meta), [reads] ]
    fasta      // channel: /path/to/genome.fasta
    kraken2db  // channel: /path/to/kraken2db - custom DB for positive read selection
    // include additional input files

    main:
    ch_versions                                 = Channel.empty()
    fastqc_raw_html                             = FASTQC_RAW.out.html
    fastqc_raw_zip                              = FASTQC_RAW.out.zip
    ch_versions                                 = ch_versions.mix(FASTQC_RAW.out.versions.first())
    trim_reads                                  = FASTP.out.reads
    trim_json                                   = FASTP.out.json
    trim_html                                   = FASTP.out.html
    trim_log                                    = FASTP.out.log
    ch_versions                                 = ch_versions.mix(FASTP.out.versions.first())
    fastqc_trim_html                            = FASTQC_TRIM.out.html
    fastqc_trim_zip                             = FASTQC_TRIM.out.zip
    ch_versions                                 = ch_versions.mix(FASTQC_TRIM.out.versions.first())
    
    // TODO: add processes/steps 
    

    emit:
    reads = trim_reads // channel: [ val(meta), [ reads ] ]
    trim_json          // channel: [ val(meta), [ json ] ]
    trim_html          // channel: [ val(meta), [ html ] ]
    trim_log           // channel: [ val(meta), [ log ] ]

    fastqc_raw_html    // channel: [ val(meta), [ html ] ]
    fastqc_raw_zip     // channel: [ val(meta), [ zip ] ]
    fastqc_trim_html   // channel: [ val(meta), [ html ] ]
    fastqc_trim_zip    // channel: [ val(meta), [ zip ] ]

    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}