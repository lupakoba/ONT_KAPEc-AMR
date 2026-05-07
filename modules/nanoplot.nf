process NANOPLOT {
    
    tag "Ploting for ${meta.id} (${mode})"

    publishDir "${projectDir}/results/nanoplot_${mode}", mode: 'copy'

    label 'process_low'

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("${meta.id}_${mode}")

    script:
    """
    echo "Running NanoPlot for ${meta.id} (${mode})"

    NanoPlot \
        --fastq ${reads} \
        -o ${meta.id}_${mode} \
        -p ${meta.id}_${mode}_ \
        --threads ${task.cpus}
    """
}