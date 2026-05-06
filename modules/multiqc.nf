process MULTIQC {
    tag "Joining FastQC reports"

    publishDir "${projectDir}/results/multiqc", mode: 'copy'

    label 'process_low'

    input:
    // Recibe una lista de todos los archivos .zip de FastQC
    path qc_files

    output:
    path "multiqc_report_reads.html"

    script:
    """
    multiqc . \
        --filename multiqc_report_reads.html \
        --force
    """
}