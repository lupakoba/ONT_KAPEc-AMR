process CAT_READS {

    tag "Concatenating ${sample_id}"

    publishDir "${projectDir}/results/cat_reads", mode: 'copy'

    label 'process_low'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_combined.fastq.gz")

    script:
    """
    cat ${reads} > ${sample_id}_combined.fastq.gz
    """
}