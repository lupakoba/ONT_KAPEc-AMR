nextflow.enable.dsl=2

process BAKTA {

    tag "Annotation for genome ${meta.id}"

    publishDir "${projectDir}/results/bakta", mode: 'copy'

    label 'process_medium'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}/"), emit: results
    tuple val(meta), path("${meta.id}/${meta.id}.gff3"), emit: gff
    

    script:
    """
    set -euo pipefail

    mkdir -p tmp_bakta

    # Export variables for Bakta
    export TMPDIR=\$PWD/tmp_bakta
    export TMP=\$PWD/tmp_bakta
    export TEMP=\$PWD/tmp_bakta
    export MPLCONFIGDIR=.

    bakta \\
        --db /db \\
        --output ${meta.id} \\
        --prefix ${meta.id} \\
        --tmp-dir \$PWD/tmp_bakta \\
        --locus-tag ${meta.id} \\
        --skip-plot \\
        --keep-contig-headers \\
        ${fasta}

    # Version information
    cat <<-END_VERSIONS > versions.yml
    "BAKTA":
        bakta: \$(bakta --version 2>&1 | sed 's/^bakta //')
    END_VERSIONS
    """
}