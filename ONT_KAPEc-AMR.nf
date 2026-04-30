/*
  ============================================================
  ONT_KAPEc-AMR - Nextflow Pipeline
  ============================================================
*/

nextflow.enable.dsl = 2

// ============================================================
// HELP MODE
// ============================================================

if (params.help) {
    printHelp()
    exit 0
}

// ============================================================
// VALIDATION
// ============================================================

checkInputParams()

log.info """
Pipeline mode:      ${params.mode}
Profile:            ${workflow.profile}
Samplesheet:        ${params.samplesheet}
""".stripIndent()

// ============================================================
// SUBWORKFLOWS
// ============================================================

include { assembly } from "$projectDir/subworkflow/assembly"
include { hybrid }   from "$projectDir/subworkflow/hybrid"

// ============================================================
// WORKFLOW MAP (dispatcher)
// ============================================================

def workflows_map = [
    assembly: assembly,
    hybrid  : hybrid
]

// ============================================================
// MAIN WORKFLOW
// ============================================================

workflow {

    reads_ch = Channel.fromPath(params.samplesheet)
    .splitCsv(header: true)
    .map { row ->
        // Construimos la ruta: data/barcode01 (por ejemplo)
        def folder_path = "${params.reads_dir}/${row.folder_path}"
        def folder = file(folder_path)
        
        if( !folder.isDirectory() ) {
            error "ERROR: No se encuentra la carpeta en ${folder_path}"
        }

        def fastq_files = file("${folder_path}/*.fastq.gz")
        
        if( fastq_files.size() == 0 ) {
            error "ERROR: No hay archivos .fastq.gz en ${folder_path}"
        }

        // Retornamos el objeto meta y la lista de archivos
        return [ [id: row.sample, gsize: row.gsize], fastq_files ]
    }




    if (params.mode == 'assembly') {
        assembly(reads_ch)
    }
    else if (params.mode == 'hybrid') {
        hybrid(reads_ch)
    }
}
////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
////////////////////////////////////////////////////////////////////////////////

def printHelp() {
    def readmeFile = file("${projectDir}/README.md")
    def printSection = false

    if (readmeFile.exists()) {
        log.info "\n"
        readmeFile.eachLine { line ->

            if (line.contains("## Usage")) {
                printSection = true
            }

            if (line.contains("## Output")) {
                printSection = false
            }

            if (printSection) {
                log.info line
            }
        }
        log.info "\n"
    } else {
        log.warn "README.md not found in ${projectDir}"
    }
}

def checkInputParams() {

    boolean fatal_error = false

    // INPUT
    if (!params.samplesheet || !file(params.samplesheet).exists()) {
    log.warn("ERROR: CSV file not found. You must provide a valid samplesheet.csv using --samplesheet.")
    fatal_error = true
    }

    // MODE
    def valid_modes = ['assembly', 'hybrid']

    if (!params.mode || !(params.mode in valid_modes)) {
        log.warn("Invalid --mode. Use: assembly or hybrid")
        fatal_error = true
    }

    // HYBRID REQUIREMENTS
    if (params.mode == 'hybrid' && !params.short_inputs) {
        log.warn("You need to provide --short_inputs when using hybrid mode")
        fatal_error = true
    }

    // PROFILE CHECK
    def profiles = workflow.profile.tokenize(',')

    if (!profiles.any { it in ['docker','singularity','conda'] }) {
        log.warn("You need to provide a valid profile: docker, singularity or conda")
        fatal_error = true
    }

    if (fatal_error) {
        error "Missing one or more required parameters"
    }
}