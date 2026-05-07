This repository is for antimicrobial resistance analysis of ONT sequenced isolates, focused on KAPEc bacteria (Klebsiella, Acinetobacter, Pseudomonas and Escherichia) and built on nextflow. Compatible with docker (usage in standalone computers) or Singularity (High Performance Cluster), see -profile for these options. This pipeline allows ONT-only de novo assembly (--mode assembly) and ONT/Illumina hybrid assembly (--mode hybrid). A mode for assembly with reference (for mutant analyses for example) is unsupported but might be implemented in the future. 

Input data: This pipeline needs already-basecalled Nanopore reads on a named folder (Using barcode04 as an example name from hereafter) inside /data folder. Also a .csv file (samplesheet.csv) should be included for sample and theoretical genome size (an example is provided in the repository). If using --mode hybrid, you will also have to provide R1/R2 illumina read files with the same name as the Nanopore folder per sample (example: barcode04_R1.fastq.gz and barcode04_R2.fastq.gz).

Overarll process: 

1. Nanopore reads are concatenated, then QC plots are obtained with Nanoplot. Reads are filtered with filtlong and adapters are trimmed with Porechop. QC plots are obtained afterwards and QC data are summarised with Nanocomp. If using --mode hybrid, raw read QC of Illumina reads is assessed with FastQC. Low quality bases, adapters and sequencing artifacts (such as Poly-Gs) are removed with FastP. Then trimmed reads QC is assessed. Reports are summarised with MultiQC.

2. A smart subsampling process is then added for oversequenced (>100x) samples. Given the theoretical genome size from .csv file, it will filter 


Quality control of reads: 






Quality check, completeness and contamination levels of assemblies: Quality metrics are obtained using QUAST and the overall metrics are condensed in a simplified report using MultiQC, while completeness and contamination levels are assessed with CheckM2.

Multi Locus Sequence Typing (MLST): MLST is determined using MLST tool.

Gene annotation: Gene annotation is obtained using BAKTA (since Prokka does not have updates anymore :/ )

Prediction of Antimicrobial resistance genes: Antimicrobial resistance determinants are predicted using AMRfinderplus (which uses a curated NCBI database, nice!). REMEMBER THAT THESE TOOLS ARE GOOD AS THEIR DATABASES, and some additional analysis must be made. The --organism option in the AMRfinderplus script is automated, derived from the MLST result (If no MLST is derived or is a species outside the list by MLST tool such as Stenotrophomonas maltophilia, it will run without --organism option).

Prediction of virulence factors: Virulence factors are predicted using ABRicate, with the VFDB database. The abricate_db module will manage the download and setup of its database.

Scan for plasmids/plasmid replicons: For Replicon identification and plasmid typing, this pipeline uses MOB RECON.

Capsular locus and O-antigen of Klebsiella/Acinetobacter: Kaptive is used for K/O typing in Klebsiella and Acinetobacter. If another species is used (E.coli/Pseudomonas sp., etc) it will print empty files and a .txt file saying that the species is unsupported by Kaptive.

Serotyping for E. coli and Pseudomonas: Ectyper and Pasty are used for E. coli and Pseudomonas sp. serotyping respectively. Those modules use the same species logic as Kaptive.

..................................................................................................................

Installation and requirements

Pipeline pre-requisites:

    Nextflow (v. 25.10.0) or higher, since pipeline is written in DSL2.
    Docker/Singularity as container support
    Java 17 or higher.
    Databases for Kraken2, Checkm2, Bakta and Kaptive (see below)
Kraken2 database: You must provide a database, either by downloading and extracting a pre-built database from AWS repository (https://benlangmead.github.io/aws-indexes/k2) or build it with kraken2 commands if pre-installed. When cloning the repository, you should make an empty KAPEc-AMR(repo name)/db/kraken_db directory, where the database must be downloaded/compiled. Remember that the bare minimum files are hash.k2d, opts.k2d and taxo.k2d !!!

Checkm2 database: You must provide a Checkm2 database. You can download it from Zenodo database (https://zenodo.org/records/14897628) or built it with Checkm2 commands if pre-installed. It is expected to be inside db/checkm2. The route should be KAPEc-AMR(repo name)/db/checkm2_db/CheckM2_database/uniref100.KO.1.dmnd (database file).

Bakta database: You must provide a database compatible with BAKTA v. 1.12.0. If you have bakta pre-installed in your computer, you can use Bakta commands to build it. Otherwise, you can download it from official repository in Zenodo (https://zenodo.org/records/14916843), unzip it with tar -xvf and force update the internal amrfinderplus database once.

For the latter case, an idea for usage in a HPC with singularity:

CONTAINER_IMG="path/to/bakta_container.img"
LOCAL_DB_DIR="/path/to/cloned/repository"

singularity exec \
    -B ${LOCAL_DB_DIR}:/data \
    ${CONTAINER_IMG} \
    amrfinder_update \
    --force_update \
    --database /data/amrfinderplus-db
The expected route for the bakta database is: KAPEc-AMR(repo name)/db/bakta_db/db-light. Inside this directory should be the database files for bakta and the internal amrfinderplus database directory (also for Bakta).

Kaptive Database: You must provide the .gbk files for K/O loci of both Klebsiella and Acinetobacter for Kaptive. You can find them on github (https://github.com/klebgenomics/Kaptive/tree/master/src/kaptive/data), and download them to /db/kaptive_db. The Kaptive_db module will print an error if the files with exact names as expected are not found.

....................................................................................................................

OPTIONS

-profile    You can state whether the run would be in a single computer (-profile docker)
            or on a HPC compatible with Singularity (-profile singularity), in both cases 
            local executor is used. A third option is included for SLURM schelduler 
            (-profile singularity_slurm) but have not been tested yet.


data/
├── barcode01/              <-- Carpeta ONT (lo que pongas en 'folder_path' del CSV)
│   └── sample01_ONT.fastq.gz
├── barcode02/
│   └── sample02_ONT.fastq.gz
├── sample01_R1.fastq.gz    <-- Archivos Illumina (en la raíz de data/)
├── sample01_R2.fastq.gz
├── sample02_R1.fastq.gz
└── sample02_R2.fastq.gz