process UNICYCLER {
    tag "Hybrid assembly: ${meta.id}"
    publishDir "${projectDir}/results/unicycler", mode: 'copy'
    label 'process_high' 

    input:
    tuple val(meta), path(ont_reads), path(short_r1), path(short_r2)

    output:
    tuple val(meta), path("${meta.id}.fasta"), emit: fasta
    tuple val(meta), path("${meta.id}.gfa")  , emit: gfa
    path "${meta.id}_unicycler.log"          , emit: log

    script:
    def gsize = meta.gsize ? "--genome_size ${meta.gsize}" : ""
    
    """
    unicycler -1 ${short_r1} -2 ${short_r2} \\
        -l ${ont_reads} \\
        -o . \\
        --threads ${task.cpus} \\
        --keep 0

    # Assembly.fasta for default, will change it to ${meta.id}.fasta
    mv assembly.fasta ${meta.id}.fasta
    mv assembly.gfa ${meta.id}.gfa
    mv unicycler.log ${meta.id}_unicycler.log
    """
}