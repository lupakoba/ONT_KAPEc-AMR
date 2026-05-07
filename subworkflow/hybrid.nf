nextflow.enable.dsl=2

/* -----------------------------------------------------------
    IMPORTACIÓN DE MÓDULOS (Sin cambios)
----------------------------------------------------------- */
include { CAT_READS }                   from '../modules/cat'
include { NANOPLOT as RAW_QC }          from '../modules/nanoplot'
include { FILTLONG }                    from '../modules/filtlong'
include { PORECHOP }                    from '../modules/porechop'
include { NANOPLOT as POST_QC }         from '../modules/nanoplot'
include { NANOCOMP as NANOCOMP_TRIM }   from '../modules/nanocomp'
include { NANOCOMP as NANOCOMP_SUBS }   from '../modules/nanocomp'
include { SEQKIT_STATS }                from '../modules/seqkit'
include { SUBSAMPLING }                 from '../modules/subsampling'
include { FASTQC as FASTQC_RAW }        from '../modules/fastqc'
include { FASTP }                       from '../modules/fastp'
include { FASTQC as FASTQC_TRIM }       from '../modules/fastqc'
include { MULTIQC }                     from '../modules/multiqc'
include { UNICYCLER }                   from '../modules/unicycler'
include { DNAAPLER }                    from '../modules/dnaapler'
include { QUAST }                       from '../modules/quast'
include { MLST }                        from '../modules/mlst'
include { BAKTA }                       from '../modules/bakta'
include { CHECKM2 }                     from '../modules/checkm2'
include { KAPTIVE_DB }                  from '../modules/kaptive_db'
include { KAPTIVE }                     from '../modules/kaptive'
include { ECTYPER }                     from '../modules/ectyper'
include { PASTY }                       from '../modules/pasty'
include { MOB_RECON }                   from '../modules/mobrecon'
include { ABRICATE_DB }                 from '../modules/abricate_db'
include { ABRICATE_VF }                 from '../modules/virulence'
include { AMRFINDERPLUS }               from '../modules/amrfinder'


workflow hybrid {

    take:
        ont_ch
        illumina_ch

    main:

    // ============================================================
    // 1. NANOPORE PIPELINE
    // ============================================================

    
    cat_out = CAT_READS(ont_ch)

    
    RAW_QC( cat_out, "raw" )

    filt_out = FILTLONG(cat_out)
    pore_out = PORECHOP(filt_out)

    POST_QC( pore_out, "post_trim" )

    
    NANOCOMP_TRIM(
        pore_out.map { it -> it[1] }.collect(), 
        "trimmed"
    )

    stats_out = SEQKIT_STATS(pore_out)

    
    subs_branch = SUBSAMPLING(stats_out)

    NANOCOMP_SUBS(
        subs_branch.map { it -> it[1] }.collect(), 
        "subsampled"
    )

    // ============================================================
    // 2. ILLUMINA PIPELINE
    // ============================================================

    
    fastqc_raw_in = illumina_ch.map { it -> 
        def new_meta = it[0].clone()
        new_meta.stage = 'raw'
        return [ new_meta, it[1] ]
    }
    fastqc_raw = FASTQC_RAW(fastqc_raw_in)

    fastp_result = FASTP(illumina_ch)

    fastqc_trim_in = fastp_result.trimmed_reads.map { it ->
        def new_meta = it[0].clone()
        new_meta.stage = 'trimmed'
        return [ new_meta, it[1] ]
    }
    fastqc_trim = FASTQC_TRIM(fastqc_trim_in)

    
    multiqc_input = fastqc_raw.zip
        .mix(fastqc_trim.zip)
        .map { meta, file -> file }
        .collect()

    MULTIQC(multiqc_input)



    // ============================================================
    // 3. JOIN
    // ============================================================

    
    hybrid_input = subs_branch
        .map { it -> [ it[0].id, it[0], it[1] ] } 
        .join(
            fastp_result.trimmed_reads.map { it -> [ it[0].id, it[1] ] } 
        )
        .map { it -> 
            
            def r1 = it[3][0]
            def r2 = it[3][1]
            return [ it[1], it[2], r1, r2 ]
        }

    // ============================================================
    // 4. ASSEMBLY + POST-PROCESSING
    // ============================================================

    unicycler_out = UNICYCLER(hybrid_input)

    
    dnaapler_out = DNAAPLER(unicycler_out.fasta)
    ch_reoriented = dnaapler_out.reoriented

    
    quast_input = ch_reoriented.map { it[1] }.collect()

    QUAST(quast_input)

    // ============================================================
    // MLST 
    // ============================================================
    
    ch_mlst_results = MLST(ch_reoriented)

    ch_joined_data = ch_reoriented.join(ch_mlst_results)

    // ============================================================
    // BAKTA
    // ============================================================

    BAKTA(ch_reoriented)

    // ============================================================
    // CHECKM2
    // ============================================================
    CHECKM2(ch_reoriented)

    // ============================================================
    // KAPTIVE_DB
    // ============================================================
    
    ch_kaptive_db_raw = KAPTIVE_DB()
    
    
    ch_kaptive_db = ch_kaptive_db_raw.collect()

    
    KAPTIVE(ch_joined_data, ch_kaptive_db)

    // ============================================================
    // AMRFINDERPLUS / ECTYPER / PASTY
    // ============================================================
    
    AMRFINDERPLUS(ch_joined_data)
    ECTYPER(ch_joined_data)
    PASTY(ch_joined_data)

    // ============================================================
    // MOB RECON Y ABRICATE
    // ============================================================
    
    MOB_RECON(ch_reoriented)

    
    // ABRICATE
    // ============================================================
    ch_abricate_db = ABRICATE_DB().collect() 
    
    
    ch_reoriented       
        .combine(ch_abricate_db)
        .set { ch_abricate_input }

    
    ABRICATE_VF(ch_abricate_input)

    
}