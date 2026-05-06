process UNICYCLER {
    tag "Hybrid assembly: ${meta.id}"

    // Organizamos la salida en la carpeta de resultados del modo híbrido
    publishDir "${projectDir}/results/unicycler", mode: 'copy'

    label 'process_high' 

    input:
    // Tupla que contiene meta (id, gsize), las reads de ONT y las reads de Illumina (R1, R2)
    tuple val(meta), path(ont_reads), path(illumina_reads)

    output:
    // El archivo principal es el assembly en formato fasta
    tuple val(meta), path("${meta.id}_assembly.fasta"), emit: assembly
    // El grafo de ensamblaje (GFA) es muy útil para verificar circularidad
    tuple val(meta), path("${meta.id}_assembly.gfa")  , emit: gfa
    // El log detallado de Unicycler
    path "${meta.id}_unicycler.log"                  , emit: log

    script:
    // Extraemos gsize del objeto meta. 
    // Si gsize viene como '5.5m', Unicycler lo entiende perfectamente.
    def gsize = meta.gsize ? "--genome_size ${meta.gsize}" : ""
    
    """
    unicycler -1 ${illumina_reads[0]} -2 ${illumina_reads[1]} \\
        -l ${ont_reads} \\
        -o . \\
        --prefix ${meta.id} \\
        --threads ${task.cpus} \\
        ${gsize} \\
        --keep 0
    
    # Renombramos los archivos por si Unicycler usa nombres genéricos
    mv ${meta.id}.assembly.fasta ${meta.id}.fasta
    mv ${meta.id}.assembly.gfa ${meta.id}.gfa
    mv ${meta.id}.unicycler.log ${meta.id}_unicycler.log
    """
}