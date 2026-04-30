process SUBSAMPLING {
    tag "${meta.id}" // Cambiado de sample_id a meta.id
    label 'process_medium'

    publishDir "${projectDir}/results/subsampling", mode: 'copy'

    input:
    // Ahora recibe el objeto meta completo que contiene el gsize del CSV
    tuple val(meta), path(reads), path(stats_file)

    output:
    tuple val(meta), path("${meta.id}.processed.fastq.gz")

    script:
    // Definimos una variable local para el script por si gsize no viene en el meta
    def gsize = meta.gsize ?: params.genome_size
    
    """
    set -euo pipefail

    # 1. Safety check
    if [ ! -s ${reads} ]; then
        echo "ERROR: Input file ${reads} is empty. Aborting." >&2
        exit 1
    fi

    # 2. Compute total bases
    total_bases=\$(zcat ${reads} | awk 'NR%4==2 {sum+=length(\$0)} END {print sum}')

    # 3. Extract median read length
    median_len=\$(awk 'NR==2 {print \$6}' ${stats_file})

    echo "Total bases: \$total_bases"
    echo "Median read length: \$median_len"

    # 4. Compute coverage usando el gsize del CSV ($gsize)
    cov=\$(awk -v tb="\$total_bases" -v gs="${gsize}" 'BEGIN {print tb / gs}')

    echo "Estimated coverage: \$cov"

    # 5. Decision logic
    if [ \$(awk -v c="\$cov" -v t="${params.target_cov}" 'BEGIN {print (c > t ? 1 : 0)}') -eq 1 ]; then
        echo "High coverage -> Subsampling para genoma de ${gsize} bp"

        # Calculamos los target_bases multiplicando el target_cov por el gsize dinámico
        filtlong --target_bases \$(( ${params.target_cov} * ${gsize} )) ${reads} > tmp.fastq

        if [ ! -s tmp.fastq ]; then
            echo "WARNING: filtlong produced empty output -> fallback to original reads"
            zcat ${reads} > tmp.fastq
        fi

        gzip tmp.fastq
        mv tmp.fastq.gz ${meta.id}.processed.fastq.gz

    else
        echo "Low coverage -> Keeping original file"
        cp ${reads} ${meta.id}.processed.fastq.gz
    fi
    """
}