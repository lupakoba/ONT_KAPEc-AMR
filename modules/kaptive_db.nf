process KAPTIVE_DB {
    tag "Verifying Kaptive database files"
    publishDir "${params.kaptive_db}", mode: 'copy'
    
    label 'process_low'

    output:
    path("*.gbk"), emit: db_files

    script:
    """
    set -euo pipefail

    # Require Kaptive database files
    FILES=(
        "Acinetobacter_baumannii_k_locus_primary_reference.gbk"
        "Acinetobacter_baumannii_OC_locus_primary_reference.gbk"
        "Klebsiella_k_locus_primary_reference.gbk"
        "Klebsiella_o_locus_primary_reference.gbk"
    )

    echo "Checking for Kaptive database files in ${params.kaptive_db}..."

    MISSING_FILES=()

    for FILE in "\${FILES[@]}"; do
        if [[ -f "${params.kaptive_db}/\$FILE" ]]; then
            echo "Found \$FILE. Creating symbolic link..."
            ln -sf "${params.kaptive_db}/\$FILE" .
        else
            MISSING_FILES+=("\$FILE")
        fi
    done

    # ERROR announcement if any database files are missing
    if [ \${#MISSING_FILES[@]} -ne 0 ]; then
        echo "======================================================================="
        echo " ERROR: The following Kaptive GBK files were not found in:"
        echo " ${params.kaptive_db}"
        echo "======================================================================="
        for MISSING in "\${MISSING_FILES[@]}"; do
            echo "  - \$MISSING"
        done
        echo "======================================================================="
        echo "Please ensure all database files are in the directory."
        exit 1
    fi
    """
}