This repository is for antimicrobial resistance analysis of ONT sequenced isolates, focused on KAPEc bacteria (Klebsiella, Acinetobacter, Pseudomonas and Escherichia) and built on nextflow. Compatible with docker (usage in standalone computers) or Singularity (High Performance Cluster), see -profile for these options. In construction


data/
├── barcode01/              <-- Carpeta ONT (lo que pongas en 'folder_path' del CSV)
│   └── sample01_ONT.fastq.gz
├── barcode02/
│   └── sample02_ONT.fastq.gz
├── sample01_R1.fastq.gz    <-- Archivos Illumina (en la raíz de data/)
├── sample01_R2.fastq.gz
├── sample02_R1.fastq.gz
└── sample02_R2.fastq.gz