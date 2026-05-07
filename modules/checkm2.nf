process CHECKM2 {
    tag "CheckM2 assessment: ${meta.id}"
    label 'process_high'

    publishDir "${projectDir}/results/checkm2", mode: 'copy'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_checkm2"), emit: results

    script:
    """
    export HOME=\$PWD

    # Buscamos el archivo .dmnd dentro del punto de montaje
    # Usamos una variable de bash para evitar problemas de interpretación de Nextflow
    DB_FILE=\$(ls /db_checkm2/*.dmnd)

    checkm2 predict \\
        --input ${fasta} \\
        --database_path \$DB_FILE \\
        --output-directory ${meta.id}_checkm2 \\
        --threads ${task.cpus} \\
        --force
    """
}