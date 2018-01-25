 class: Workflow
 cwlVersion: v1.0
 doc: 'RNA-seq pipeline - reads: PE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
 inputs:
    genome_sizes_file:
      doc: Genome sizes tab-delimited file (used in samtools)
      type: File
    nthreads_qc:
      doc: Number of threads - qc.
      type: int
    nthreads_quant:
      doc: Number of threads - quantification.
      type: int
    default_adapters_file:
      doc: Adapters file
      type: File
    trimmomatic_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    sjdb_name:
      default: ggr.SJ.out.all.tab
      type: string
    rsem_reference_files:
      doc: RSEM genome reference files - generated with the rsem-prepare-reference command
      type: File[]
    nthreads_trimm:
      doc: Number of threads - trim.
      type: int
    genomeDirFiles:
      doc: STAR genome reference/indices files.
      type: File[]
    nthreads_map:
      doc: Number of threads - map.
      type: int
    annotation_file:
      doc: GTF annotation file
      type: File
    genome_fasta_files:
      doc: STAR genome generate - Genome FASTA file with all the genome sequences in FASTA format
      type: File[]
    input_fastq_read1_files:
      doc: Input read1 fastq files
      type: File[]
    trimmomatic_jar_path:
      doc: Trimmomatic Java jar file
      type: string
    sjdbOverhang:
      doc: Length of the genomic sequence around the annotated junction to be used in constructing the splice junctions database.
      type: string
 steps:
    trim:
      in:
        nthreads: nthreads_trimm
        input_read1_adapters_files: qc/output_custom_adapters_read1
        input_fastq_read1_files: input_fastq_read1_files
        trimmomatic_jar_path: trimmomatic_jar_path
        trimmomatic_java_opts: trimmomatic_java_opts
      run: 02-trim-se.cwl
      out:
      - output_data_fastq_read1_trimmed_files
      - output_trimmed_read1_fastq_read_count
    map:
      in:
        genome_sizes_file: genome_sizes_file
        nthreads: nthreads_map
        sjdb_name: sjdb_name
        genomeDirFiles: genomeDirFiles
        annotation_file: annotation_file
        genome_fasta_files: genome_fasta_files
        input_fastq_read1_files: trim/output_data_fastq_read1_trimmed_files
        sjdbOverhang: sjdbOverhang
      run: 03-map-se.cwl
      out:
      - star_aligned_unsorted_file
      - star_aligned_sorted_file
      - star_aligned_sorted_index_file
      - star2_stat_files
      - star2_readspergene_file
      - read_count_mapped_star2
      - transcriptome_star_aligned_file
      - transcriptome_star_stat_files
      - read_count_transcriptome_mapped_star2
      - percentage_uniq_reads_star1
      - pcr_bottleneck_coef_file
      - generated_genome_files
      - star1_stat_files
      - read_count_mapped_star1
      - star_1pass_sjdb
    qc:
      in:
        input_fastq_read1_files: input_fastq_read1_files
        default_adapters_file: default_adapters_file
        nthreads: nthreads_qc
      run: 01-qc-se.cwl
      out:
      - output_fastqc_report_files_read1
      - output_fastqc_data_files_read1
      - output_custom_adapters_read1
      - output_count_raw_reads_read1
      - output_diff_counts_read1
    quant:
      in:
        nthreads: nthreads_quant
        rsem_reference_files: rsem_reference_files
        input_bam_files: map/star_aligned_sorted_file
        annotation_file: annotation_file
        input_transcripts_bam_files: map/transcriptome_star_aligned_file
        input_genome_sizes: genome_sizes_file
      run: 04-quantification-se-revstranded.cwl
      out:
      - featurecounts_counts
      - rsem_isoforms_files
      - rsem_genes_files
      - bw_raw_files
      - bw_norm_files
 outputs:
    bw_norm_files:
      doc: Normalized by RPKM bigWig files.
      type: File[]
      outputSource: quant/bw_norm_files
    star1_stat_files:
      doc: STAR pass-1 stat files.
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: map/star1_stat_files
    read_count_mapped_star1:
      doc: Read counts of the mapped BAM files after STAR pass1
      type: File[]
      outputSource: map/read_count_mapped_star1
    pcr_bottleneck_coef_file:
      doc: PCR Bottleneck Coefficient
      type: File[]
      outputSource: map/pcr_bottleneck_coef_file
    generated_genome_files:
      doc: STAR generated genome files
      type: File[]
      outputSource: map/generated_genome_files
    star_aligned_sorted_index_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: map/star_aligned_sorted_index_file
    read_count_mapped_star2:
      doc: Read counts of the mapped BAM files after STAR pass2
      type: File[]
      outputSource: map/read_count_mapped_star2
    output_trimmed_read1_fastq_read_count:
      doc: Trimmed read counts of paired read 1 fastq files
      type: File[]
      outputSource: trim/output_trimmed_read1_fastq_read_count
    star_aligned_unsorted_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: map/star_aligned_unsorted_file
    star_1pass_sjdb:
      doc: SJDB from union of STAR 1st pass
      type: File
      outputSource: map/star_1pass_sjdb
    output_count_raw_reads_read1:
      outputSource: qc/output_count_raw_reads_read1
      type: File[]
    output_custom_adapters_read1:
      outputSource: qc/output_custom_adapters_read1
      type: File[]
    read_count_transcriptome_mapped_star2:
      doc: Read counts of the mapped to transcriptome BAM files after STAR pass1
      type: File[]
      outputSource: map/read_count_transcriptome_mapped_star2
    transcriptome_star_stat_files:
      doc: STAR pass-2 aligned to transcriptome stat files.
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: map/transcriptome_star_stat_files
    transcriptome_star_aligned_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: map/transcriptome_star_aligned_file
    star_aligned_sorted_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: map/star_aligned_sorted_file
    featurecounts_counts:
      doc: Normalized fragment extended reads bigWig (signal) files
      type: File[]
      outputSource: quant/featurecounts_counts
    percentage_uniq_reads_star1:
      doc: Percentage of uniq reads from preseq c_curve output
      type: File[]
      outputSource: map/percentage_uniq_reads_star1
    output_diff_counts_read1:
      outputSource: qc/output_diff_counts_read1
      type: File[]
    star2_stat_files:
      doc: STAR pass-2 stat files.
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: map/star2_stat_files
    output_fastqc_report_files_read1:
      doc: FastQC reports in zip format for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_report_files_read1
    bw_raw_files:
      doc: Raw bigWig files.
      type: File[]
      outputSource: quant/bw_raw_files
    star2_readspergene_file:
      doc: STAR pass-2 reads per gene counts file.
      type: File[]?
      outputSource: map/star2_readspergene_file
    rsem_genes_files:
      doc: RSEM genes files
      type: File[]
      outputSource: quant/rsem_genes_files
    output_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_data_files_read1
    rsem_isoforms_files:
      doc: RSEM isoforms files
      type: File[]
      outputSource: quant/rsem_isoforms_files
    output_data_fastq_read1_trimmed_files:
      doc: Trimmed fastq files for paired read 1
      type: File[]
      outputSource: trim/output_data_fastq_read1_trimmed_files
