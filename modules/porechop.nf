process PORECHOP {
    
    tag "Trimming ${meta.id}"

    publishDir "${projectDir}/results/porechop", mode: 'copy'

    label 'process_high'

    input:
    tuple val(meta), path(reads)

    output:
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