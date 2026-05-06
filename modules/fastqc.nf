process FASTQC {
    tag "QC ${type} for sample: ${meta.id}"

    // La carpeta de salida cambiará según el valor de 'type' (raw o trimmed)
    publishDir "${projectDir}/results/fastqc/${type}", mode: 'copy'

    label 'process_low'

    input:
    // Recibe el meta, las reads y un valor (String) para diferenciar el momento del QC
    tuple val(meta), path(reads)
    val type

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip

    script:
    """
    fastqc ${reads} --threads ${task.cpus}
    """
}