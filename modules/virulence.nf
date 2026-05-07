process ABRICATE_VF {

    tag "Virulence factors for ${meta.id}"

    publishDir "${projectDir}/results/abricate_vfdb", mode: 'copy'

    label 'process_medium'

    input:
    tuple val(meta), path(assembly), path(db)

    output:
    tuple val(meta), path("${meta.id}_vfdb.tab"), emit: vfdb_hits
    tuple val(meta), path("${meta.id}_vfdb.summary.txt"), emit: summary
    

    script:
    """
    export ABRICATE_DB=${db}

    abricate \
        --db vfdb \
        --minid 90 \
        --mincov 70 \
        --threads ${task.cpus} \
        ${assembly} > ${meta.id}_vfdb.tab

    abricate --summary ${meta.id}_vfdb.tab > ${meta.id}_vfdb.summary.txt

    cat <<-END_VERSIONS > versions.yml
    "ABRICATE":
        abricate: \$(abricate --version 2>&1)
    END_VERSIONS
    """
}