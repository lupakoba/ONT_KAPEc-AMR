nextflow.enable.dsl=2

include { CAT_READS }                   from '../modules/cat'
include { NANOPLOT as NANOPLOT_RAW }    from '../modules/nanoplot'
include { FILTLONG }                    from '../modules/filtlong'
include { PORECHOP }                    from '../modules/porechop'
include { NANOPLOT as NANOPLOT_POST }   from '../modules/nanoplot'
include { NANOCOMP as NANOCOMP_RAW }    from '../modules/nanocomp'
include { NANOCOMP as NANOCOMP_SUBS }   from '../modules/nanocomp'
include { SEQKIT_STATS }                from '../modules/seqkit'
include { SUBSAMPLING }                 from '../modules/subsampling'

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
    NANOCOMP_RAW(raw_files, "raw")

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
    NANOCOMP_SUBS(subs_files, "processed")
}