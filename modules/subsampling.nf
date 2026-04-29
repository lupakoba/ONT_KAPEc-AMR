process SUBSAMPLING {

    tag "${sample_id}"

    label 'process_medium'

    publishDir "${projectDir}/results/subsampling", mode: 'copy'

    input:
    tuple val(sample_id), path(reads), path(stats_file)

    output:
    tuple val(sample_id), path("${sample_id}.processed.fastq.gz")

    script:
    """
    set -euo pipefail

    # -----------------------------
    # 1. Safety check
    # -----------------------------
    if [ ! -s ${reads} ]; then
        echo "ERROR: Input file ${reads} is empty. Aborting." >&2
        exit 1
    fi

    # -----------------------------
    # 2. Compute total bases
    # -----------------------------
    total_bases=\$(zcat ${reads} | awk 'NR%4==2 {sum+=length(\$0)} END {print sum}')

    # -----------------------------
    # 3. Extract median read length
    # -----------------------------
    median_len=\$(awk 'NR==2 {print \$6}' ${stats_file})

    echo "Total bases: \$total_bases"
    echo "Median read length: \$median_len"

    # -----------------------------
    # 4. Compute coverage (using params.genome_size)
    # -----------------------------
    cov=\$(awk -v tb="\$total_bases" -v gs="${params.genome_size}" 'BEGIN {print tb / gs}')

    echo "Estimated coverage: \$cov"

    # -----------------------------
    # 5. Decision logic
    # -----------------------------
    if [ \$(awk -v c="\$cov" -v t="${params.target_cov}" 'BEGIN {print (c > t ? 1 : 0)}') -eq 1 ]; then
        echo "High coverage -> Subsampling"

        filtlong --target_bases \$(( ${params.target_cov} * ${params.genome_size} )) ${reads} > tmp.fastq

        # safeguard against empty output
        if [ ! -s tmp.fastq ]; then
            echo "WARNING: filtlong produced empty output -> fallback to original reads"
            zcat ${reads} > tmp.fastq
        fi

        gzip tmp.fastq
        mv tmp.fastq.gz ${sample_id}.processed.fastq.gz

    else
        echo "Low coverage -> Keeping original file"
        cp ${reads} ${sample_id}.processed.fastq.gz
    fi
    """
}