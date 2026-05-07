nextflow.enable.dsl=2

process MLST {

    tag "MLST typing for ${meta.id}"

    label 'process_low'

    publishDir "${projectDir}/results/mlst", mode: 'copy'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_mlst.tsv"), emit: mlst
    
    script:
    """
    set -euo pipefail

    mlst ${fasta} > ${meta.id}_mlst.tsv

    cat <<-END_VERSIONS > versions.yml
    "MLST":
        mlst: \$(mlst --version 2>&1 || echo "unknown")
    END_VERSIONS
    """
}