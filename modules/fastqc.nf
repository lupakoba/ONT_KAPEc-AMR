process FASTQC {

    tag "Read QC ${meta.id} (${meta.stage ?: 'raw'})"

    publishDir "${projectDir}/results/fastqc/${meta.stage ?: 'raw'}", mode: 'copy'

    label 'process_low'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip

    script:
    """
    fastqc ${reads} --threads ${task.cpus}
    """
}