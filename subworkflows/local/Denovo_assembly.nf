//
// Subworkflow : Denovo Assembly - upstream assembly pipeline
//

include { NF-CORE_FASTQC as FASTQC_RAW           } from '../modules/nf-core/modules/nf-core/fastqc/main'
include { NF-CORE_FASTP as FASTP                 } from '../modules/nf-core/modules/nf-core/fastp/main'
include { NF-CORE_FASTQC as FASTQC_TRIMMED       } from '../modules/nf-core/modules/nf-core/fastqc/main'
include { NF-CORE_KRAKEN2_KRAKEN2 as KRAKEN2     } from '../modules/nf-core/modules/nf-core/kraken2/kraken2/main'
include { NF-CORE_BBMAP_BBDUK as BBDUK           } from '../modules/nf-core/modules/nf-core/bbmap/bbduk/main'
include { NF-CORE_UNICYCLER as UNICYCLER         } from '../modules/nf-core/modules/nf-core/unicycler/main'
include { NF-CORE_QUAST as QUAST                 } from '../modules/nf-core/modules/nf-core/quast/main'
include { AUGUSTUS                               } from '../modules/local/augustus'

// TODO: include functionality for ONT read data --> Skesa only handles Illumina short reads

workflow DE_NOVO_ASSEMBLY {
    take:
    reads      // channel: [ val(meta), [reads] ]
    kraken2db  // channel: /path/to/kraken2db - custom DB for positive read selection
    species    // channel: val; must be a valid species with a trained Augustus model

    main:
    ch_versions      = Channel.empty()

    //
    // MODULE: Run FASTQC raw 
    // 
    FASTQC_RAW(
        reads
    )
    ch_versions      = ch_versions.mix(FASTQC_RAW.out.versions.first().ifEmpty(null))

    //
    // MODULE: Run Kraken to keep only orthopox reads 
    // 
    ch_kraken2_db    = file(kraken2db, checkIfExists=true)
    KRAKEN2(
        reads, ch_kraken2_db,false,false,true
    )
    ch_koutput       = KRAKEN2.out.classified_reads_fastq
    ch_versions      = ch_versions.mix(KRAKEN2.out.versions.first().ifEmpty(null))
    
    //
    // MODULE: Run FASTP 
    //
    FASTP(
        ch_koutput, true, true
    ) 
    trim_reads       = FASTP.out.reads
    ch_versions      = ch_versions.mix(FASTP.out.versions)
    
    //
    // MODULE: Run FASTQC Trimmed 
    //
    FASTQC_TRIMMED(
        trim_reads
    )
    ch_versions      = ch_versions.mix(FASTQC_TRIMMED.out.versions.first().ifEmpty(null))

    //
    // MODULE: Run UNICYCLER 
    //
    UNICYCLER(
        trim_reads
    )
    ch_unioutput     = UNICYCLER.out.scaffolds
    ch_versions      = ch_versions.mix(UNICYCLER.out.versions.first().ifEmpty(null))

    //
    // MODULE: QUAST
    //
    QUAST(
        ch_unioutput.collect{ it[1] }, '', '', false, false
    )
    ch_quast         = QUAST.out.results
    ch_quast_tsv     = QUAST.out.tsv
    ch_versions      = ch_versions.mix(QUAST.out.versions)

    //
    // MODULE: Augustus
    // TODO: Made it already !!!!!!
    //
    AUGUSTUS( 
        ch_unioutput, species
    )
    ch_genecalling = AUGUSTUS.out.gff

    emit:
    // Unicycler output channels
    scaffolds     = ch_unioutput              // channel: [ val(meta), [ scaffolds ] ]
    gfa           = UNICYCLER.out.gfa         // channel: [ val(meta), [ gfa ] ]
    log_out       = UNICYCLER.out.log         // channel: [ val(meta), [ log ] ]

    // FastQC output channels
    fastqc_raw_html                             = FASTQC_RAW.out.html
    fastqc_raw_zip                              = FASTQC_RAW.out.zip
    fastqc_trim_html                            = FASTQC_TRIM.out.html
    fastqc_trim_zip                             = FASTQC_TRIM.out.zip

    // FastP output channels
    trim_reads                                  = FASTP.out.reads
    trim_json                                   = FASTP.out.json
    trim_html                                   = FASTP.out.html
    trim_log                                    = FASTP.out.log

    // Quast output channels
    quast_results = ch_quast                  // channel: [ val(meta), [ results ] ]
    quast_tsv     = ch_quast_tsv              // channel: [ val(meta), [ tsv ] ]

    // De novo gene calling
    gff           = ch_genecalling            // channel: [ val(meta), [ gff ] ]
    versions      = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}