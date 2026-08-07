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


..........................

## Acknowledgments

This pipeline is built with [Nextflow](https://www.nextflow.io/) (DSL2) and relies on the following open-source tools. If you use ONT_KAPEc-AMR in your work, please cite this repository together with the underlying tools listed below.

| Step | Tool | Repository |
|---|---|---|
| Workflow engine | Nextflow | https://github.com/nextflow-io/nextflow |
| ONT read QC | NanoPlot / NanoComp (NanoPack) | https://github.com/wdecoster/NanoPlot / https://github.com/wdecoster/nanocomp |
| ONT read filtering | Filtlong | https://github.com/rrwick/Filtlong |
| ONT adapter trimming | Porechop | https://github.com/rrwick/Porechop |
| Illumina read QC (`--mode hybrid`) | FastQC | https://github.com/s-andrews/FastQC |
| Illumina read trimming (`--mode hybrid`) | fastp | https://github.com/OpenGene/fastp |
| Read/FASTA/FASTQ utilities | SeqKit | https://github.com/shenwei356/seqkit |
| Report aggregation | MultiQC | https://github.com/MultiQC/MultiQC |
| De novo assembly, ONT-only (`--mode assembly`) | Flye | https://github.com/mikolmogorov/Flye |
| Assembly polishing | Racon, Medaka | https://github.com/isovic/racon / https://github.com/nanoporetech/medaka |
| Hybrid assembly (`--mode hybrid`) | Unicycler | https://github.com/rrwick/Unicycler |
| Genome reorientation | dnaapler | https://github.com/gbouras13/dnaapler |
| Assembly quality metrics | QUAST | https://github.com/ablab/quast |
| Completeness/contamination | CheckM2 | https://github.com/chklovski/CheckM2 |
| MLST | mlst | https://github.com/tseemann/mlst |
| Gene annotation | Bakta | https://github.com/oschwengers/bakta |
| AMR gene prediction | AMRFinderPlus | https://github.com/ncbi/amr |
| Virulence factor prediction | ABRicate + VFDB | https://github.com/tseemann/abricate |
| Plasmid reconstruction/typing | MOB-suite (MOB-recon) | https://github.com/phac-nml/mob-suite |
| Capsule/O-antigen typing | Kaptive | https://github.com/klebgenomics/Kaptive |
| *E. coli* serotyping | ECTyper | https://github.com/phac-nml/ecoli_serotyping |
| *Pseudomonas* serotyping | pasty | https://github.com/rpetit3/pasty |

### References

1. Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35(4), 316–319. https://doi.org/10.1038/nbt.3820

2. De Coster, W., D'Hert, S., Schultz, D. T., Cruts, M., & Van Broeckhoven, C. (2018). NanoPack: visualizing and processing long-read sequencing data. *Bioinformatics*, 34(15), 2666–2669. https://doi.org/10.1093/bioinformatics/bty149 (covers both NanoPlot and NanoComp; see also De Coster, W., & Rademakers, R. (2023). NanoPack2: population-scale evaluation of long-read sequencing data. *Bioinformatics*, 39(5), btad311. https://doi.org/10.1093/bioinformatics/btad311)

3. Wick, R. R. *Filtlong: quality filtering tool for long reads* [Software]. https://github.com/rrwick/Filtlong (no associated publication; cite the repository)

4. Wick, R. R. *Porechop: adapter trimmer for Oxford Nanopore reads* [Software]. https://github.com/rrwick/Porechop (no associated publication; cite the repository, RRID:SCR_016967)

5. Andrews, S. (2010). *FastQC: A Quality Control Tool for High Throughput Sequence Data* [Software]. Babraham Bioinformatics. http://www.bioinformatics.babraham.ac.uk/projects/fastqc/

6. Chen, S., Zhou, Y., Chen, Y., & Gu, J. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics*, 34(17), i884–i890. https://doi.org/10.1093/bioinformatics/bty560

7. Shen, W., Le, S., Li, Y., & Hu, F. (2016). SeqKit: a cross-platform and ultrafast toolkit for FASTA/Q file manipulation. *PLOS ONE*, 11(10), e0163962. https://doi.org/10.1371/journal.pone.0163962

8. Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, 32(19), 3047–3048. https://doi.org/10.1093/bioinformatics/btw354

9. Kolmogorov, M., Yuan, J., Lin, Y., & Pevzner, P. A. (2019). Assembly of long, error-prone reads using repeat graphs. *Nature Biotechnology*, 37(5), 540–546. https://doi.org/10.1038/s41587-019-0072-8

10. Vaser, R., Sović, I., Nagarajan, N., & Šikić, M. (2017). Fast and accurate de novo genome assembly from long uncorrected reads. *Genome Research*, 27(5), 737–746. https://doi.org/10.1101/gr.214270.116

11. Oxford Nanopore Technologies. *Medaka: Sequence correction provided by ONT Research* [Software]. https://github.com/nanoporetech/medaka (no associated publication; cite the repository)

12. Wick, R. R., Judd, L. M., Gorrie, C. L., & Holt, K. E. (2017). Unicycler: resolving bacterial genome assemblies from short and long sequencing reads. *PLOS Computational Biology*, 13(6), e1005595. https://doi.org/10.1371/journal.pcbi.1005595

13. Bouras, G., Grigson, S. R., Papudeshi, B., Mallawaarachchi, V., & Roach, M. J. (2024). Dnaapler: a tool to reorient circular microbial genomes. *Journal of Open Source Software*, 9(93), 5968. https://doi.org/10.21105/joss.05968

14. Gurevich, A., Saveliev, V., Vyahhi, N., & Tesler, G. (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, 29(8), 1072–1075. https://doi.org/10.1093/bioinformatics/btt086

15. Chklovski, A., Parks, D. H., Woodcroft, B. J., & Tyson, G. W. (2023). CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality using machine learning. *Nature Methods*, 20(8), 1203–1212. https://doi.org/10.1038/s41592-023-01940-w

16. Seemann, T. *mlst: Scan contig files against PubMLST typing schemes* [Software]. https://github.com/tseemann/mlst (uses the PubMLST database: Jolley, K. A., Bray, J. E., & Maiden, M. C. J. (2018). Open-access bacterial population genomics: BIGSdb software, the PubMLST.org website and their applications. *Wellcome Open Research*, 3, 124.)

17. Schwengers, O., Jelonek, L., Dieckmann, M. A., Beyvers, S., Blom, J., & Goesmann, A. (2021). Bakta: rapid and standardized annotation of bacterial genomes via alignment-free sequence identification. *Microbial Genomics*, 7(11), 000685. https://doi.org/10.1099/mgen.0.000685

18. Feldgarden, M., Brover, V., Gonzalez-Escalona, N., Frye, J. G., Haendiges, J., Haft, D. H., Hoffmann, M., Pettengill, J. B., Prasad, A. B., Tillman, G. E., Tyson, G. H., & Klimke, W. (2021). AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. *Scientific Reports*, 11, 12728. https://doi.org/10.1038/s41598-021-91456-0

19. Seemann, T. *ABRicate: Mass screening of contigs for antimicrobial and virulence genes* [Software]. https://github.com/tseemann/abricate — virulence database: Chen, L. et al. (2016). VFDB 2016: hierarchical and refined dataset for big data analysis—10 years on. *Nucleic Acids Research*, 44(D1), D694–D697. https://doi.org/10.1093/nar/gkv1239

20. Robertson, J., & Nash, J. H. E. (2018). MOB-suite: software tools for clustering, reconstruction and typing of plasmids from draft assemblies. *Microbial Genomics*, 4(8), e000206. https://doi.org/10.1099/mgen.0.000206

21. Lam, M. M. C., Wick, R. R., Judd, L. M., Holt, K. E., & Wyres, K. L. (2022). Kaptive 2.0: updated capsule and lipopolysaccharide locus typing for the *Klebsiella pneumoniae* species complex. *Microbial Genomics*, 8(3), 000800. https://doi.org/10.1099/mgen.0.000800

22. Bessonov, K., Laing, C., Robertson, J., Yong, I., Ziebell, K., Gannon, V. P. J., Nash, J. H. E., Christianson, S., Bekal, S., Reimer, A., Taboada, E., Domselaar, G. V., & Graham, M. (2021). ECTyper: in silico *Escherichia coli* serotype and species prediction from raw and assembled whole-genome sequence data. *Microbial Genomics*, 7(12), 000728. https://doi.org/10.1099/mgen.0.000728

23. Petit III, R. A. *pasty: In silico serogrouping of Pseudomonas aeruginosa isolates* [Software]. https://github.com/rpetit3/pasty (based on the original PAst method: Thrane, S. W. et al. (2016). *Pseudomonas aeruginosa* Typer (PAst): a web tool for rapid and accurate in silico serotyping of *Pseudomonas aeruginosa* isolates. *Journal of Clinical Microbiology*, 54(6), 1782–1788.)

*Container execution is provided via [Docker](https://www.docker.com/) or [Singularity/Apptainer](https://apptainer.org/), depending on the `-profile` selected.*
