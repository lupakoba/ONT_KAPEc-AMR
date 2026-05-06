nextflow.enable.dsl=2

/* -----------------------------------------------------------
    IMPORTACIÓN DE MÓDULOS
----------------------------------------------------------- */
// Nanopore
include { CAT_READS }                    from '../modules/cat'
include { NANOPLOT as NANOPLOT_RAW }     from '../modules/nanoplot'
include { FILTLONG }                     from '../modules/filtlong'
include { PORECHOP }                     from '../modules/porechop'
include { NANOPLOT as NANOPLOT_POST }    from '../modules/nanoplot'
include { NANOCOMP as NANOCOMP_TRIM }    from '../modules/nanocomp'
include { NANOCOMP as NANOCOMP_SUBS }    from '../modules/nanocomp'
include { SEQKIT_STATS }                 from '../modules/seqkit'
include { SUBSAMPLING }                  from '../modules/subsampling'

// Illumina
include { FASTQC as FASTQC_RAW }         from '../modules/fastqc'
include { FASTP }                        from '../modules/fastp'
include { FASTQC as FASTQC_TRIMMED }     from '../modules/fastqc'
include { MULTIQC }    from '../modules/multiqc'

// Assembly & Sorting
include { UNICYCLER }                    from '../modules/unicycler'
include { DNAAPLER }                     from '../modules/dnaapler'
include { QUAST }                        from '../modules/quast'

workflow hybrid {

    take:
    ont_ch       // [ [id:sample, gsize:gsize], [fastqs] ]
    illumina_ch  // [ [id:sample], [R1, R2] ]
    gsize_csv     // [ [id:sample, gsize] ]

    main:

    // ============================================================
    // 1. FLUJO NANOPORE (Tu estructura original)
    // ============================================================
    cat_out = CAT_READS(ont_reads_ch)
    NANOPLOT_RAW(cat_out, "raw")

    filt_out = FILTLONG(cat_out)
    pore_out = PORECHOP(filt_out)
    NANOPLOT_POST(pore_out, "post_trim")

    // QC Comparativo de recortes
    raw_files = pore_out.map { it[1] }.collect()
    NANOCOMP_TRIM(raw_files, "trimmed")

    // Stats y Subsampling con GSize
    stats_out = SEQKIT_STATS(pore_out)
    subs_branch = SUBSAMPLING(stats_out, gsize_csv)

    // QC Comparativo de subsampling
    subs_files = subs_branch.map { it[1] }.collect()
    NANOCOMP_SUBS(subs_files, "subsampled")

    // ============================================================
    // 2. FLUJO ILLUMINA (Estructura solicitada)
    // ============================================================
    
    // FastQC inicial
    fastqc_raw_result = FASTQC_RAW(illumina_ch, "raw")

    // Trimming con Fastp
    fastp_result = FASTP(illumina_ch)

    // FastQC post-trimming
    fastqc_trimmed_result = FASTQC_TRIMMED(fastp_result.trimmed_reads, "trimmed")

    // Reporte MultiQC para Illumina
    multiqc_input = fastqc_raw_result.zip
        .mix(fastqc_trimmed_result.zip)
        .collect()
    
    MULTIQC(multiqc_input)

    // ============================================================
    // 3. ENSAMBLAJE HÍBRIDO Y REORIENTACIÓN
    // ============================================================
    
    // Sincronización de canales: [meta, [R1, R2], long_reads]
    ch_unicycler_in = fastp_out.trimmed_reads.join(subs_branch)

    unicycler_out = UNICYCLER(ch_unicycler_in)

    // Reorientación con Dnaapler
    // Emite el canal .reoriented que ya usas en assembly.nf
    ch_final_assemblies = DNAAPLER(unicycler_out.assembly).reoriented 

    // QUAST Final para todos los ensambles reorientados
    ch_final_assemblies
        .map { it[1] }
        .collect()
        .set { ch_quast_input }
    
    QUAST(ch_quast_input)

    emit:
    assembly = ch_final_assemblies
}