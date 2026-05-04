nextflow.enable.dsl=2

process CHECKM2 {

    tag "Assessing completeness and contamination for genome ${sample_id}"
        
    label 'process_high'

    publishDir "${params.outdir}/checkm2", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta), path(db_file)

    output:
    tuple val(sample_id), path("${sample_id}_checkm2"), emit: results
    

    script:
    """
    export HOME=\$PWD

    checkm2 predict \\
        --input ${fasta} \\
        --database_path ${db_file} \\
        --output-directory ${sample_id}_checkm2 \\
        --force

    cat <<-END_VERSIONS > versions.yml
    "CHECKM2":
        checkm2: \$(checkm2 --version 2>&1)
    END_VERSIONS
    """
}