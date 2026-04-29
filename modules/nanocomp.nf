process NANOCOMP {

    tag "Joining reports ${mode}"

    label 'process_low'

    publishDir "results/nanocomp_${mode}", mode: 'copy'

    input:
    path reads
    val mode

    output:
    path "nanocomp_${mode}"

    script:
    """
    NanoComp --fastq ${reads} -o nanocomp_${mode}
    """
}