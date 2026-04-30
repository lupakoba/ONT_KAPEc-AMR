process SEQKIT_STATS {
    tag "${meta.id}"
    label 'process_low'

    input:
    // Recibe la tupla con el objeto meta y las reads
    tuple val(meta), path(reads)

    output:
    // Emite la tupla completa: meta, las reads originales y el archivo de stats
    tuple val(meta), path(reads), path("stats.txt")

    script:
    """
    seqkit stats -a ${reads} > stats.txt
    """
}