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
Pipeline mode:     ${params.mode}
Profile:           ${workflow.profile}
Input:             ${params.input}
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

    reads_ch = Channel
        .fromPath("${params.input}/**/*.fastq.gz")
        .map { file ->
            def sample = file.parent.name
            tuple(sample, file)
        }
        .groupTuple()

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
    if (!params.input || !file(params.input).exists()) {
        log.warn("You need to provide a valid input directory with --input")
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