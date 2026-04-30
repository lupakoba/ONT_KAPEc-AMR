process PORECHOP {
    // Usamos meta.id para identificar el proceso en la consola
    tag "${meta.id}"

    publishDir "${projectDir}/results/porechop", mode: 'copy'

    label 'process_high'

    input:
    // Recibe la tupla [meta, reads]
    tuple val(meta), path(reads)

    output:
    // Mantiene el objeto meta para que llegue a SEQKIT y SUBSAMPLING
    tuple val(meta), path("${meta.id}.porechop.fastq.gz")

    script:
    """
    echo "Running Porechop for ${meta.id}"

    porechop \
        -i ${reads} \
        -o ${meta.id}.porechop.fastq.gz \
        --threads ${task.cpus}
        
    """
}