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

    // 5. DNAAPLER (Re-orientación y finalización)
    final_genome = DNAAPLER(medaka_out.polished)

    // 2. Reporte agrupado
    // .map{ it[1] } extrae el archivo .fasta ignorando el meta
    // .collect() junta todos los .fasta en una sola lista/canal
    all_fastas_ch = final_genome.reoriented.map{ it[1] }.collect()
    
    QUAST(all_fastas_ch)



}