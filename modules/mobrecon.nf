nextflow.enable.dsl=2

process MOB_RECON {

    tag "Plasmid inference for genome ${meta.id}"

    publishDir "${projectDir}/results/mob_recon", mode: 'copy'

    label 'process_medium'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_mob_recon"), emit: results
    

    script:
    """
    set -euo pipefail

    mob_recon -i ${assembly} -o ${meta.id}_mob_recon -n ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "MOB_RECON":
        mob_recon: \$(mob_recon --version 2>&1 || echo "unknown")
    END_VERSIONS
    """
}