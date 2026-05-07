nextflow.enable.dsl=2

process ABRICATE_DB {

    tag "Preparing ABRICATE db"

    label 'process_medium'

    output:
    path "abricate_db", emit: db

    script:
    """
    export ABRICATE_DB=\$PWD/abricate_db

    mkdir -p \$ABRICATE_DB

    # Check if the ABRICATE database is already set up, otherwise set it up
    if [ ! -d "\$ABRICATE_DB/vfdb" ]; then
        abricate --setupdb
    fi
    """
}