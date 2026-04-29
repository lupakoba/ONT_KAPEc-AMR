process FILTLONG {

    tag "${sample_id}"

    publishDir "${projectDir}/results/filtlong", mode: 'copy'

    label 'process_medium'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.filtlong.fastq.gz")

    script:

    def min_length = params.min_length ?: 1000

    """
    echo "Running Filtlong (length-only filtering) for ${sample_id}"

    filtlong \
        --min_length ${min_length} \
        ${reads} | gzip > ${sample_id}.filtlong.fastq.gz
    """
}