nextflow.enable.dsl=2

process ECTYPER {

    tag "Serotyping for genome ${meta.id}"

    label 'process_low'

    publishDir "${params.outdir}/ectyper", mode: 'copy'

    input:
    tuple val(meta), path(assembly), path(mlst_tsv)

    output:
    tuple val(meta), path("${meta.id}_ectyper.tsv"), emit: ectyper
    tuple val(meta), path("${meta.id}_species_not_supported.txt"), optional: true, emit: skipped
    

    script:
    """
    set -euo pipefail

    # Extract species information from MLST 
    species_raw=\$(head -n1 ${mlst_tsv} | cut -f2 | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    # Logic for E. coli only
    if [[ "\$species_clean" == *"escherichia"* || "\$species_clean" == *"ecoli"* ]]; then
        echo "Running ECTyper for Escherichia coli..."

        ectyper \\
            -i ${assembly} \\
            -o ${meta.id}_ectyper.tsv

    else
        echo "Species \$species_raw not supported by ECTyper (only E. coli)." > ${meta.id}_species_not_supported.txt
        
        # Create empty output file to avoid breaking pipeline
        touch "${meta.id}_ectyper.tsv"
    fi

    cat <<-END_VERSIONS > versions.yml
    "ECTYPER":
        ectyper: \$(ectyper --version 2>&1 || echo "unknown")
    END_VERSIONS
    """
}