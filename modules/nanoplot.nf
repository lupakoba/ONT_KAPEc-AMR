process NANOPLOT {
    // Usamos meta.id y el modo para que el log de Nextflow sea claro
    tag "${meta.id} (${mode})"

    publishDir "${projectDir}/results/nanoplot_${mode}", mode: 'copy'

    label 'process_low'

    input:
    // Recibe la tupla con meta y el valor del modo (raw o post_trim)
    tuple val(meta), path(reads)
    val mode

    output:
    // Mantenemos el meta en la salida por consistencia
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