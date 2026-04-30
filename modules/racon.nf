process RACON {
    tag "${meta.id} - R${iteration}"
    label 'process_high'

    input:
    tuple val(meta), path(assembly), path(reads)
    val iteration

    output:
    tuple val(meta), path("${meta.id}_racon_v${iteration}.fasta"), emit: polished

    script:
    """
    # 1. Alinear lecturas al ensamblaje actual
    minimap2 -x map-ont -t ${task.cpus} ${assembly} ${reads} > alignment.paf

    # 2. Pulir
    racon -t ${task.cpus} ${reads} alignment.paf ${assembly} > ${meta.id}_racon_v${iteration}.fasta
    """
}