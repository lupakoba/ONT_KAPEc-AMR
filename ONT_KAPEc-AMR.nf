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

    // NANOPORE CHANNEL
    reads_ch = Channel.fromPath(params.samplesheet)
    .splitCsv(header: true)
    .map { row ->
        // CSV CLEAN-UP
        def sampleId  = row.sample.trim()
        def subFolder = row.folder_path.trim()
        
        // Route folder path for reads
        def folder_path = "${projectDir}/data/${subFolder}"
        def folder = file(folder_path)

        // Veryfing if folder exists
        if( !folder.exists() ) {
            error """
            --- ROUTE ERROR (projectDir) ---
            Sample: ${sampleId}
            Search path: ${folder_path}
            
            Tip: Make sure that the folder '${subFolder}' is in: ${projectDir}/data/
            """.stripIndent()
        }

        // Búsqueda de archivos fastq.gz
        def fastq_files = file("${folder_path}/*.fastq.gz")
        
        if( fastq_files.size() == 0 ) {
            error "ERROR: No .fastq.gz files found in: ${folder_path}"
        }

        def gsize = row.gsize?.trim()

        if (!gsize) {
            log.warn "No gsize provided for ${sampleId}, using default: ${params.genome_size}"
            gsize = params.genome_size
        }

        return [ [id: sampleId, gsize: gsize], fastq_files ]
    }
    
    if (params.mode == 'assembly') {
        assembly(reads_ch)
    } 
    else if (params.mode == 'hybrid') {

        // ILLUMINA CHANNEL
        illumina_ch = Channel
            .fromFilePairs("${params.short_inputs}/*_R{1,2}.fastq.gz")
            .map { id, files ->

                if (files.size() != 2) {
                    error "Sample ${id} does not have exactly 2 paired-end files"
                }

                def sorted_files = files.sort { it.name }

                return [ [id: id.trim()], sorted_files ]
            }

        // DEBUG 
        reads_ch
            .map { meta, files -> meta.id }
            .view { "ONT IDs: $it" }

        illumina_ch
            .map { meta, files -> meta.id }
            .view { "ILLUMINA IDs: $it" }


        // ============================================================
        // HYBRID CALL (UPDATED)
        // ============================================================

        hybrid(reads_ch, illumina_ch)
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