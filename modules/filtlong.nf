process FILTLONG {
    // Usamos meta.id para el tag
    tag "${meta.id}"

    publishDir "${projectDir}/results/filtlong", mode: 'copy'

    label 'process_medium'

    input:
    // Recibe la tupla con el objeto meta (ID + gsize)
    tuple val(meta), path(reads)

    output:
    // Devuelve el objeto meta intacto para el siguiente proceso
    tuple val(meta), path("${meta.id}.filtlong.fastq.gz")

    script:
    def min_length = params.min_length ?: 1000

    """
    echo "Running Filtlong (length-only filtering) for ${meta.id}"

    filtlong \
        --min_length ${min_length} \
        ${reads} | gzip > ${meta.id}.filtlong.fastq.gz
    """
}