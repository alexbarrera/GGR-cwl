#!/usr/bin/env cwl-runner
 class: Workflow
 cwlVersion: v1.0
 doc: "CUT-and-RUN pipeline - reads: PE."
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
 inputs:
    input_fastq_read1_files:
      doc: Input fastq paired-end read 1 files
      type: File[]
    input_fastq_read2_files:
      doc: Input fastq paired-end read 2 files
      type: File[]
    genome_sizes_file:
      doc: Genome sizes tab-delimited file (used in samtools)
      type: File
    genome_effective_size:
      default: hs
      doc: Effective genome size used by MACS2. It can be numeric or a shortcuts:'hs' for human (2.7e9), 'mm' for mouse (1.87e9), 'ce' for C. elegans (9e7) and 'dm' for fruitfly (1.2e8), Default:hs
      type: string
    genome_ref_first_index_file:
      doc: Bowtie first index files for reference genome (e.g. *.1.bt2). The rest of the files should be in the same folder.
      type: File
      secondaryFiles:
        - ^^.2.bt2
        - ^^.3.bt2
        - ^^.4.bt2
        - ^^.rev.1.bt2
        - ^^.rev.2.bt2
    picard_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    picard_jar_path:
      doc: Picard Java jar file
      type: string
    nthreads_qc:
      doc: Number of threads required for the 01-qc step
      type: int
    nthreads_map:
      doc: Number of threads required for the 03-map step
      type: int
 outputs:
    qc_count_raw_reads_read1:
      doc: Raw read counts of fastq files for read 1 after QC for
      type: File[]
      outputSource: qc/output_count_raw_reads_read1
    qc_count_raw_reads_read2:
      doc: Raw read counts of fastq files for read 2 after QC for
      type: File[]
      outputSource: qc/output_count_raw_reads_read2
    qc_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_data_files_read1
    qc_fastqc_data_files_read2:
      doc: FastQC data files for paired read 2
      type: File[]
      outputSource: qc/output_fastqc_data_files_read2
    qc_fastqc_report_files_read1:
      doc: FastQC report files for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_report_files_read1
    qc_fastqc_report_files_read2:
      doc: FastQC report files for paired read 2
      type: File[]
      outputSource: qc/output_fastqc_report_files_read2
    qc_diff_counts_read1:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 1 for
      type: File[]
      outputSource: qc/output_diff_counts_read1
    qc_diff_counts_read2:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 2 for
      type: File[]
      outputSource: qc/output_diff_counts_read2
    map_mark_duplicates_files:
      doc: Summary of duplicates removed with Picard tool MarkDuplicates (for multiple reads aligned to the same positions) for
      type: File[]
      outputSource: map/output_picard_mark_duplicates_files
    map_dedup_bam_files:
      doc: Filtered BAM files (post-processing end point)
      type: File[]
      outputSource: map/output_data_sorted_dedup_bam_files
    map_pbc_files:
      doc: PCR Bottleneck Coefficient files (used to flag samples when pbc<0.5) for control
      type: File[]
      outputSource: map/output_pbc_files
    map_preseq_percentage_uniq_reads:
      doc: Preseq percentage of uniq reads
      type: File[]
      outputSource: map/output_percentage_uniq_reads
    map_read_count_mapped:
      doc: Read counts of the mapped BAM files
      type: File[]
      outputSource: map/output_read_count_mapped
    map_bowtie_log_files:
      doc: Bowtie log file with mapping stats for
      type: File[]
      outputSource: map/output_bowtie_log
    map_preseq_c_curve_files:
      doc: Preseq c_curve output files for
      type: File[]
      outputSource: map/output_preseq_c_curve_files
    map_output_extract_fragments_bam2bed:
      doc: Fragments in BED format
      type: File[]
      outputSource: map/output_extract_fragments_bam2bed
 steps:
    qc:
      run: 01-qc-pe.cwl
      in:
        input_read1_fastq_files: input_fastq_read1_files
        input_read2_fastq_files: input_fastq_read2_files
        nthreads: nthreads_qc
      out:
      - output_count_raw_reads_read1
      - output_diff_counts_read1
      - output_fastqc_report_files_read1
      - output_fastqc_data_files_read1
      - output_count_raw_reads_read2
      - output_diff_counts_read2
      - output_fastqc_report_files_read2
      - output_fastqc_data_files_read2
    map:
      run: 02-map-pe.cwl
      in:
        input_fastq_read1_files: input_fastq_read1_files
        input_fastq_read2_files: input_fastq_read2_files
        genome_sizes_file: genome_sizes_file
        genome_ref_first_index_file: genome_ref_first_index_file
        picard_jar_path: picard_jar_path
        picard_java_opts: picard_java_opts
        nthreads: nthreads_map
      out:
      - output_data_sorted_dedup_bam_files
      - output_picard_mark_duplicates_files
      - output_pbc_files
      - output_bowtie_log
      - output_preseq_c_curve_files
      - output_percentage_uniq_reads
      - output_read_count_mapped
      - output_extract_fragments_bam2bed