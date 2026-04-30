process QUAST {
    label 'process_medium'
    tag "All Samples"
    
    // Guardamos todo en una sola carpeta de resultados
    publishDir "${params.outdir}/quast_summary", mode: 'copy'

    input:
    path(all_fastas) // Recibe la lista de genomas

    output:
    path("combined_report/*") // Captura todo el contenido (html, tsv, txt)

    script:
    """
    set -euo pipefail
    
    # Ejecutamos QUAST sobre todos los archivos a la vez
    quast.py \\
        ${all_fastas} \\
        -o combined_report \\
        --threads ${task.cpus} \\
        --min-contig 200
    """
}