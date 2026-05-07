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
    // RAW QC AND TRIMMING
    // -----------------------
    
    raw_files = pore_out.map { it[1] }.collect()

    
    NANOCOMP_TRIM(raw_files, "trimmed")

    // -----------------------
    // STEP: SEQKIT STATS
    // -----------------------
    
    stats_out = SEQKIT_STATS(pore_out)

    // -----------------------
    // BRANCH B: SUBSAMPLING
    // -----------------------
    
    
    subs_branch = SUBSAMPLING(stats_out)

    
    subs_files = subs_branch.map { it[1] }.collect()

    
    NANOCOMP_SUBS(subs_files, "subsampled")

    
    flye_out = FLYE(subs_branch)

    
    racon1_in = flye_out.assembly.join(subs_branch)
    racon1_out = RACON_1(racon1_in, 1)

    
    racon2_in = racon1_out.polished.join(subs_branch)
    racon2_out = RACON_2(racon2_in, 2)

    
    medaka_in = racon2_out.polished.join(subs_branch)
    medaka_out = MEDAKA(medaka_in)

       
    ch_final_assemblies = DNAAPLER(medaka_out.polished).reoriented 

    
    ch_final_assemblies
        .map { it[1] }
        .collect()
        .set { ch_quast_input }
    
    QUAST(ch_quast_input)

    
    ch_mlst_results = MLST(ch_final_assemblies)

    ch_joined_data = ch_final_assemblies.join(ch_mlst_results)

    

    BAKTA(ch_final_assemblies)

    
    CHECKM2(ch_final_assemblies)

    
    
    ch_kaptive_db_raw = KAPTIVE_DB()
    
    
    ch_kaptive_db = ch_kaptive_db_raw.collect()

    
    KAPTIVE(ch_joined_data, ch_kaptive_db)

    
    AMRFINDERPLUS(ch_joined_data)
    ECTYPER(ch_joined_data)
    PASTY(ch_joined_data)

    
    MOB_RECON(ch_final_assemblies)

    
    ch_abricate_db = ABRICATE_DB().collect() 

    
    ch_final_assemblies
        .combine(ch_abricate_db)
        .set { ch_abricate_input }

    
    ABRICATE_VF(ch_abricate_input)

}