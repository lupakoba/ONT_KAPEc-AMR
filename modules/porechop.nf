process PORECHOP {

    tag "${sample_id}"

    publishDir "${projectDir}/results/porechop", mode: 'copy'

    label 'process_high'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.porechop.fastq.gz")

    script:
    """
    echo "Running Porechop for ${sample_id}"

    porechop \
        -i ${reads} \
        -o ${sample_id}.porechop.fastq.gz
    """
}