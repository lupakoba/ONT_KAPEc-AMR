nextflow.enable.dsl=2

process PASTY {

    tag "Serotyping for ${meta.id}"

    label 'process_low'

    publishDir "${projectDir}/results/pasty", mode: 'copy'

    input:
    tuple val(meta), path(assembly), path(mlst_tsv)

    output:
    tuple val(meta), path("${meta.id}_pasty.tsv"), emit: pasty
    tuple val(meta), path("${meta.id}_species_not_supported.txt"), optional: true, emit: skipped
    

    script:
    """
    set -euo pipefail

    species_raw=\$(awk 'NR==2 {print \$2}' ${mlst_tsv} | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    if [[ "\$species_clean" == *"pseudomonas"* || "\$species_clean" == *"aeruginosa"* ]]; then
        echo "Running Pasty for Pseudomonas aeruginosa..."

        mkdir -p pasty_out

        pasty \\
            --input ${assembly} \\
            --outdir pasty_out

        TSV_FILE=\$(find pasty_out -name "*.tsv" | head -n1)

        if [[ -f "\$TSV_FILE" ]]; then
            cp "\$TSV_FILE" "${meta.id}_pasty.tsv"
        else
            echo "No TSV output found from Pasty" > "${meta.id}_pasty.tsv"
        fi

    else
        echo "Species \$species_raw not supported by Pasty (only P. aeruginosa)." > ${meta.id}_species_not_supported.txt
        touch "${meta.id}_pasty.tsv"
    fi

    cat <<-END_VERSIONS > versions.yml
    "PASTY":
        pasty: \$(pasty --version 2>&1 || echo "unknown")
    END_VERSIONS
    """
}