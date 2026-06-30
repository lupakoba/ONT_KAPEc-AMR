process CAT_READS {
    
    tag "Concatenating ${meta.id}"

    publishDir "${projectDir}/results/cat_reads", mode: 'copy'

    label 'process_low'

    input:
    
    tuple val(meta), path(reads)

    output:
    
    tuple val(meta), path("${meta.id}_combined.fastq.gz")

    script:
    """
    zcat ${reads} | gzip > ${meta.id}_combined.fastq.gz
    """
}
