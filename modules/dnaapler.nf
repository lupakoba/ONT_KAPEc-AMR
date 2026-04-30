process DNAAPLER {
    tag "${meta.id}"
    label 'process_medium'
    
    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}.fasta"), emit: reoriented

    script:
    def output_name = "${meta.id}.fasta"
    """
    
    dnaapler all --input ${assembly} --prefix ${meta.id} --threads ${task.cpus} --output out_dnaapler
    
    # Detection logic
    if [ -f out_dnaapler/${meta.id}_reoriented.fasta ]; then
        mv out_dnaapler/${meta.id}_reoriented.fasta ${output_name}
    elif [ -f out_dnaapler/${meta.id}.fasta ]; then
        mv out_dnaapler/${meta.id}.fasta ${output_name}
    else
        # Si falla la reorientación, copiamos el original con el nombre esperado
        echo "WARNING: Dnaapler no pudo reorientar ${meta.id}, usando ensamble original" >&2
        cp ${assembly} ${output_name}
    fi
    """
}