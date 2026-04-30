process MEDAKA {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(assembly), path(reads)

    output:
    tuple val(meta), path("${meta.id}_medaka.fasta"), emit: polished

    script:
    
    def model = "r1041_e82_400bps_sup_v5.2.0"
    """
    medaka_consensus \
        -i ${reads} \
        -d ${assembly} \
        -o medaka_out \
        -t ${task.cpus} \
        -m ${model}

    if [ -f medaka_out/consensus.fasta ]; then
        mv medaka_out/consensus.fasta ${meta.id}_medaka.fasta
    else
        echo "Error: Medaka did not produce a consensus file for ${meta.id}" >&2
        exit 1
    fi
    """
}