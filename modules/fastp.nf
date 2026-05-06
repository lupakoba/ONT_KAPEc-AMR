process FASTP {
    // Usamos meta.id para que el rastreo sea consistente con los otros procesos
    tag "Trimming for sample ${meta.id}"

    publishDir "${projectDir}/results/fastp", mode: 'copy'

    label 'process_medium'

    input:
    // Recibe la tupla [ [id:..., gsize:...], [R1.fastq.gz, R2.fastq.gz] ]
    tuple val(meta), path(reads)

    output:
    // Emitimos el meta original junto con las lecturas limpias
    tuple val(meta), path("${meta.id}_trimmed_R{1,2}.fastq.gz"), emit: trimmed_reads
    tuple val(meta), path("${meta.id}_fastp.html")             , emit: fastp_html
    tuple val(meta), path("${meta.id}_fastp.json")             , emit: fastp_json

    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} \\
          -o ${meta.id}_trimmed_R1.fastq.gz \\
          -O ${meta.id}_trimmed_R2.fastq.gz \\
          -h ${meta.id}_fastp.html \\
          -j ${meta.id}_fastp.json \\
          --thread ${task.cpus}
    """
}