process NANOPLOT {

    tag "${sample_id} (${mode})"

    publishDir "${projectDir}/results/nanoplot_${mode}", mode: 'copy'

    label 'process_low'

    input:
    tuple val(sample_id), path(reads)
    val mode

    output:
    tuple val(sample_id), path("${sample_id}_${mode}")

    script:

    """
    echo "Running NanoPlot for ${sample_id} (${mode})"

    NanoPlot \
        --fastq ${reads} \
        -o ${sample_id}_${mode} \
        -p ${sample_id}_${mode}_
    """
}