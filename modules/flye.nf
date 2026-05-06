process FLYE {
    tag "${meta.id}"
    label 'process_high'
        
    publishDir "${projectDir}/results/flye", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_flye.fasta"), emit: assembly
    path "${meta.id}_flye_info.txt"          , emit: info

    script:
    // Definimos si usamos nano-hq basado en la calidad esperada de R10 SUP
    """
    flye --nano-hq ${reads} \\
        --out-dir ${meta.id}_flye \\
        --genome-size ${meta.gsize} \\
        --threads ${task.cpus} \\
        --iterations 3

    # Renombramos el output principal
    mv ${meta.id}_flye/assembly.fasta ${meta.id}_flye.fasta
    mv ${meta.id}_flye/assembly_info.txt ${meta.id}_flye_info.txt
    """
}