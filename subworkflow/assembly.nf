nextflow.enable.dsl=2

include { CAT_READS }                   from '../modules/cat'
include { NANOPLOT as NANOPLOT_RAW }    from '../modules/nanoplot'
include { FILTLONG }                    from '../modules/filtlong'
include { PORECHOP }                    from '../modules/porechop'
include { NANOPLOT as NANOPLOT_POST }   from '../modules/nanoplot'
include { NANOCOMP as NANOCOMP_TRIM }   from '../modules/nanocomp'
include { NANOCOMP as NANOCOMP_SUBS }   from '../modules/nanocomp'
include { SEQKIT_STATS }                from '../modules/seqkit'
include { SUBSAMPLING }                 from '../modules/subsampling'
include { FLYE }                        from '../modules/flye'
include { RACON as RACON_1 }            from '../modules/racon'
include { RACON as RACON_2 }            from '../modules/racon'
include { MEDAKA }                      from '../modules/medaka'
include { DNAAPLER }                    from '../modules/dnaapler'
include { QUAST }                       from '../modules/quast'
include { MLST }                        from '../modules/mlst'
include { CHECKM2 }                     from '../modules/checkm2'
include { BAKTA }                       from '../modules/bakta'
include { AMRFINDERPLUS }               from '../modules/amrfinder'
include { ABRICATE_DB }                 from '../modules/abricate_db'
include { ABRICATE_VF }                 from '../modules/virulence'
include { MOB_RECON }                   from '../modules/mobrecon'
include { KAPTIVE_DB }                  from '../modules/kaptive_db'
include { KAPTIVE }                     from '../modules/kaptive'
include { ECTYPER }                     from '../modules/ectyper'
include { PASTY }                       from '../modules/pasty'


workflow assembly {

    take:
    reads_ch
    
    main:

    cat_out = CAT_READS(reads_ch)

    NANOPLOT_RAW(cat_out, "raw")

    filt_out = FILTLONG(cat_out)
    pore_out = PORECHOP(filt_out)

    NANOPLOT_POST(pore_out, "post_trim")

    // -----------------------
    // BRANCH A: RAW QC
    // -----------------------
    // 1. Extraemos solo la ruta de las lecturas y las colectamos todas
    raw_files = pore_out.map { it[1] }.collect()

    // 2. Llamamos al alias pasándole la lista y el modo
    NANOCOMP_TRIM(raw_files, "trimmed")

    // -----------------------
    // STEP: SEQKIT STATS
    // -----------------------
    // stats_out will have [id, reads, stats.txt]
    stats_out = SEQKIT_STATS(pore_out)

    // -----------------------
    // BRANCH B: SUBSAMPLING
    // -----------------------
    
    // 1. ¡Esta es la línea que faltaba! Aquí ejecutas el proceso
    subs_branch = SUBSAMPLING(stats_out)

    // 2. Ahora que subs_branch ya existe, puedes transformarlo y colectarlo
    subs_files = subs_branch.map { it[1] }.collect()

    // 3. Y finalmente llamas al reporte
    NANOCOMP_SUBS(subs_files, "subsampled")

    // 1. Ensamblaje Inicial
    flye_out = FLYE(subs_branch)

    // 2. RACON - RONDA 1
    // IMPORTANTE: Usamos el alias RACON_1
    racon1_in = flye_out.assembly.join(subs_branch)
    racon1_out = RACON_1(racon1_in, 1)

    // 3. RACON - RONDA 2
    // IMPORTANTE: Usamos el alias RACON_2
    racon2_in = racon1_out.polished.join(subs_branch)
    racon2_out = RACON_2(racon2_in, 2)

    // 4. MEDAKA (Pulido final de alta precisión)
    medaka_in = racon2_out.polished.join(subs_branch)
    medaka_out = MEDAKA(medaka_in)

    // ============================================================
    // 5. DNAAPLER -> Canal de ensambles finales
    // ============================================================
    // Ahora ch_final_assemblies es un canal simple: [meta, fasta]
    ch_final_assemblies = DNAAPLER(medaka_out.polished).reoriented 

    // QUAST: Recolecta todos los fastas para un solo reporte
    ch_final_assemblies
        .map { it[1] }
        .collect()
        .set { ch_quast_input }
    
    QUAST(ch_quast_input)

    // ============================================================
    // MLST 
    // ============================================================
    
    ch_mlst_results = MLST(ch_final_assemblies)

    ch_joined_data = ch_final_assemblies.join(ch_mlst_results)

    // ============================================================
    // BAKTA
    // ============================================================

    BAKTA(ch_final_assemblies)

    // ============================================================
    // CHECKM2
    // ============================================================
    CHECKM2(ch_final_assemblies)

    // ============================================================
    // KAPTIVE_DB
    // ============================================================
    // Quitamos el .out.db_files ya que el proceso emite el canal directamente
    ch_kaptive_db_raw = KAPTIVE_DB()
    
    // Usamos collect para que la DB esté disponible para todas las muestras
    ch_kaptive_db = ch_kaptive_db_raw.collect()

    // Llamada a KAPTIVE (2 argumentos: datos de muestra y DB)
    KAPTIVE(ch_joined_data, ch_kaptive_db)

    // ============================================================
    // AMRFINDERPLUS / ECTYPER / PASTY
    // ============================================================
    // Estos procesos suelen recibir la tupla de 3 elementos [meta, fasta, tsv]
    AMRFINDERPLUS(ch_joined_data)
    ECTYPER(ch_joined_data)
    PASTY(ch_joined_data)

    // ============================================================
    // MOB RECON Y ABRICATE
    // ============================================================
    // MOB_RECON solo necesita el ensamble
    MOB_RECON(ch_final_assemblies)

    // ABRICATE necesita el ensamble y su DB
    // ============================================================
    // ABRICATE_VF
    // ============================================================
    ch_abricate_db = ABRICATE_DB().collect() // Aseguramos que sea un solo objeto

    // Combinamos el ensamble con la DB en un solo canal (un solo argumento)
    ch_final_assemblies
        .combine(ch_abricate_db)
        .set { ch_abricate_input }

    // LLAMADA CORREGIDA: Ahora es solo 1 argumento (la tupla combinada)
    ABRICATE_VF(ch_abricate_input)

}