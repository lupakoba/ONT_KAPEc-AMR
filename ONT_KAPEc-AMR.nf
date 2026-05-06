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

    // CANAL NANOPORE (Igual al que ya tienes)
    reads_ch = Channel.fromPath(params.samplesheet)
    .splitCsv(header: true)
    .map { row ->
        // Limpieza de datos del CSV
        def sampleId  = row.sample.trim()
        def subFolder = row.folder_path.trim()
        
        // Construimos la ruta usando projectDir
        // Esto asume que tus datos están en una carpeta 'data' dentro del proyecto
        def folder_path = "${projectDir}/data/${subFolder}"
        def folder = file(folder_path)

        // Verificación de existencia de la carpeta
        if( !folder.exists() ) {
            error """
            --- ERROR DE RUTA (projectDir) ---
            Muestra: ${sampleId}
            Ruta buscada: ${folder_path}
            
            Tip: Asegúrate de que la carpeta '${subFolder}' esté en: ${projectDir}/data/
            """.stripIndent()
        }

        // Búsqueda de archivos fastq.gz
        def fastq_files = file("${folder_path}/*.fastq.gz")
        
        if( fastq_files.size() == 0 ) {
            error "ERROR: No se encontraron archivos .fastq.gz en: ${folder_path}"
        }

        return [ [id: sampleId, gsize: row.gsize.trim()], fastq_files ]
    }
    
    if (params.mode == 'assembly') {
        assembly(reads_ch)
    } 
    else if (params.mode == 'hybrid') {
        
        // CANAL ILLUMINA
        // Buscamos pares R1/R2 que coincidan con el ID de la muestra en el CSV
        illumina_ch = Channel.fromFilePairs("${params.short_inputs}/*_R{1,2}.fastq.gz")
            .map { id, files -> 
                // Creamos un meta simple para el join posterior
                return [ [id: id], files ] 
            }

        // Preparamos el archivo GSIZE como un canal de valor
        ch_gsize_file = file(params.samplesheet)

        // Llamamos al subworkflow híbrido (ajustado a los 3 inputs del diseño anterior)
        hybrid(reads_ch, illumina_ch, ch_gsize_file)
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