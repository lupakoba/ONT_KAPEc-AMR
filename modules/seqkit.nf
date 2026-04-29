process SEQKIT_STATS {
    tag "${sample_id}"
    label 'process_low'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path(reads), path("stats.txt")

    script:
    """
    seqkit stats -a ${reads} > stats.txt
    """
}