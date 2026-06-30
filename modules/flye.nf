process FLYE {
    tag "De novo assembly ${meta.id}"
    label 'process_high'
        
    publishDir "${projectDir}/results/flye", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_flye.fasta"), emit: assembly
    path "${meta.id}_flye_info.txt"          , emit: info

    script:
    
    """
    flye --nano-hq ${reads} \\
        --out-dir ${meta.id}_flye \\
        --genome-size ${meta.gsize} \\
        --threads ${task.cpus} \\
        --iterations 2

    # Rename output
    mv ${meta.id}_flye/assembly.fasta ${meta.id}_flye.fasta
    mv ${meta.id}_flye/assembly_info.txt ${meta.id}_flye_info.txt
    """
}