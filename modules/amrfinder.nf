process AMRFINDERPLUS {

    tag "AMR determinants for ${meta.id}"

    label 'process_medium'

    publishDir "${projectDir}/results/amrfinder", mode: 'copy'

    input:
    tuple val(meta), path(assembly), path(mlst_result)

    output:
    tuple val(meta), path("${meta.id}_amrfinder.tsv")

    script:
    """
    set -euo pipefail

    # Extract and normalize organism name from MLST result
    organism=\$(head -n1 ${mlst_result} | cut -f2 | sed 's/_/ /g' | tr '[:upper:]' '[:lower:]')

    echo "Detected organism: \$organism"

    # Name normalization for AMRFinderPlus
    case "\$organism" in
        *ecoli*)
            genus="Escherichia"
            ;;
        *klebsiella*|*kpneumoniae*)
            genus="Klebsiella_pneumoniae"
            ;;
        *abaumannii*|*acinetobacter*)
            genus="Acinetobacter_baumannii"
            ;;
        *pseudomonas*|*paeruginosa*)
            genus="Pseudomonas_aeruginosa"
            ;;
        *)
            # fallback seguro: tomar la primera palabra
            genus=\$(echo "\$organism" | cut -d ' ' -f1)
            ;;
    esac

    # Validation, otherwise runs without --organism flag
    case "\$genus" in
        Escherichia|Klebsiella_pneumoniae|Acinetobacter_baumannii|Pseudomonas_aeruginosa)
            org_flag="--organism \$genus"
            ;;
        *)
            echo "WARNING: Unknown genus '\$genus' → running without --organism flag"
            org_flag=""
            ;;
    esac

    echo "Normalized genus: \$genus"
    echo "Using org_flag: \$org_flag"

    amrfinder \\
        --nucleotide ${assembly} \\
        \$org_flag \\
        --threads ${task.cpus} \\
        --output ${meta.id}_amrfinder.tsv \\
        --plus
    """
}