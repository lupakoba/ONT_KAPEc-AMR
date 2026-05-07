process KAPTIVE {
    tag "KL/OCL inference for ${meta.id}"
    label 'process_medium'

    publishDir "${projectDir}/results/kaptive", mode: 'copy'

    input:
    tuple val(meta), path(assembly), path(mlst_tsv)
    path gbk_files

    output:
    tuple val(meta), path("${meta.id}_kaptive_kl.tsv"),  emit: kaptive_kl
    tuple val(meta), path("${meta.id}_kaptive_ocl.tsv"), emit: kaptive_ocl
    path "${meta.id}_species_not_supported.txt", optional: true

    script:
    def id = meta.id

    """
    set -euo pipefail

    ########################################
    # Safe matplotlib config
    ########################################
    export MPLCONFIGDIR=\$(pwd)/matplotlib_cache
    mkdir -p \$MPLCONFIGDIR

    ########################################
    # MLST-based species detection
    ########################################
    species_raw=\$(head -n1 ${mlst_tsv} | cut -f2 | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    echo "Detected MLST: \$species_raw"

    ########################################
    # SKIP NON-TARGET SPECIES EARLY (IMPORTANT FIX)
    ########################################
    if [[ "\$species_clean" != *"acinetobacter"* && "\$species_clean" != *"abaumannii"* && "\$species_clean" != *"klebsiella"* && "\$species_clean" != *"pneumoniae"* ]]; then
        echo "Skipping Kaptive for non-target species: \$species_raw" > ${id}_species_not_supported.txt
        touch ${id}_kaptive_kl.tsv
        touch ${id}_kaptive_ocl.tsv
        exit 0
    fi

    ########################################
    # ACINETOBACTER BAUMANNII
    ########################################
    if [[ "\$species_clean" == *"acinetobacter"* || "\$species_clean" == *"abaumannii"* ]]; then

        echo "Running Kaptive for Acinetobacter (GBK mode)..."

        K_DB=\$(ls *.gbk | grep -i "Acinetobacter" | grep -i "k_locus" | head -n1)
        OC_DB=\$(ls *.gbk | grep -i "Acinetobacter" | grep -i "OC_locus" | head -n1)

        if [ -z "\$K_DB" ] || [ -z "\$OC_DB" ]; then
            echo "ERROR: Missing Acinetobacter GBK databases" >&2
            exit 1
        fi

        kaptive assembly "\$K_DB" ${assembly} -o ${id}_kaptive_kl
        kaptive assembly "\$OC_DB" ${assembly} -o ${id}_kaptive_ocl

    ########################################
    # KLEBSIELLA
    ########################################
    elif [[ "\$species_clean" == *"klebsiella"* || "\$species_clean" == *"pneumoniae"* ]]; then

        echo "Running Kaptive for Klebsiella (GBK mode)..."

        K_DB=\$(ls *.gbk | grep -i "Klebsiella" | grep -i "k_locus" | head -n1)
        O_DB=\$(ls *.gbk | grep -i "Klebsiella" | grep -v -i "k_locus" | head -n1)

        if [ -z "\$K_DB" ] || [ -z "\$O_DB" ]; then
            echo "ERROR: Missing Klebsiella GBK databases" >&2
            exit 1
        fi

        kaptive assembly "\$K_DB" ${assembly} -o ${id}_kaptive_kl
        kaptive assembly "\$O_DB" ${assembly} -o ${id}_kaptive_ocl
    fi

    ########################################
    # SAFE OUTPUT HANDLING (FIXED MV BUG)
    ########################################

    if [ ! -s ${id}_kaptive_kl.tsv ]; then
        if ls ${id}_kaptive_kl*.tsv 1> /dev/null 2>&1; then
            for f in ${id}_kaptive_kl*.tsv; do
                [ "\$f" != "${id}_kaptive_kl.tsv" ] && mv "\$f" ${id}_kaptive_kl.tsv
            done
        else
            echo "Kaptive failed or no KL locus found" > ${id}_kaptive_kl.tsv
        fi
    fi

    if [ ! -s ${id}_kaptive_ocl.tsv ]; then
        if ls ${id}_kaptive_ocl*.tsv 1> /dev/null 2>&1; then
            for f in ${id}_kaptive_ocl*.tsv; do
                [ "\$f" != "${id}_kaptive_ocl.tsv" ] && mv "\$f" ${id}_kaptive_ocl.tsv
            done
        else
            echo "Kaptive failed or no OCL locus found" > ${id}_kaptive_ocl.tsv
        fi
    fi
    """
}