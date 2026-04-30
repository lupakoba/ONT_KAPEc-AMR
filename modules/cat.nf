process CAT_READS {
    // Usamos meta.id para que el log de Nextflow sea claro
    tag "Concatenating ${meta.id}"

    publishDir "${projectDir}/results/cat_reads", mode: 'copy'

    label 'process_low'

    input:
    // Aquí recibimos el objeto meta completo y la lista de archivos
    tuple val(meta), path(reads)

    output:
    // Emitimos el objeto meta intacto y el archivo combinado
    tuple val(meta), path("${meta.id}_combined.fastq.gz")

    script:
    """
    # Como 'reads' es una lista de archivos de la carpeta, cat los une todos
    cat ${reads} > ${meta.id}_combined.fastq.gz
    """
}