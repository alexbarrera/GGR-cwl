 class: Workflow
 cwlVersion: v1.0
 doc: 'ChIP-seq pipeline - reads: PE, region: narrow, samples: treatment.'
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
 inputs:
    genome_sizes_file:
      doc: Genome sizes tab-delimited file (used in samtools)
      type: File
    input_fastq_read2_files:
      doc: Input fastq paired-end read 2 files
      type: File[]
    nthreads_qc:
      doc: Number of threads required for the 01-qc step
      type: int
    default_adapters_file:
      doc: Adapters file
      type: File
    nthreads_quant:
      doc: Number of threads required for the 05-quantification step
      type: int
    nthreads_peakcall:
      doc: Number of threads required for the 04-peakcall step
      type: int
    picard_jar_path:
      doc: Picard Java jar file
      type: string
    trimmomatic_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    genome_effective_size:
      default: hs
      doc: Effective genome size used by MACS2. It can be numeric or a shortcuts:'hs' for human (2.7e9), 'mm' for mouse (1.87e9), 'ce' for C. elegans (9e7) and 'dm' for fruitfly (1.2e8), Default:hs
      type: string
    ENCODE_blacklist_bedfile:
      doc: Bedfile containing ENCODE consensus blacklist regions to be excluded.
      type: File
    trimmomatic_jar_path:
      doc: Trimmomatic Java jar file
      type: string
    nthreads_map:
      doc: Number of threads required for the 03-map step
      type: int
    nthreads_trimm:
      doc: Number of threads required for the 02-trim step
      type: int
    picard_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    genome_ref_first_index_file:
      doc: '"First index file of Bowtie reference genome with extension 1.ebwt. \ (Note: the rest of the index files MUST be in the same folder)" '
      type: File
    input_fastq_read1_files:
      doc: Input fastq paired-end read 1 files
      type: File[]
    as_narrowPeak_file:
      doc: Definition narrowPeak file in AutoSql format (used in bedToBigBed)
      type: File
 steps:
    map:
      in:
        genome_sizes_file: genome_sizes_file
        input_fastq_read2_files: trimm/output_data_fastq_read2_trimmed_files
        nthreads: nthreads_map
        picard_jar_path: picard_jar_path
        picard_java_opts: picard_java_opts
        ENCODE_blacklist_bedfile: ENCODE_blacklist_bedfile
        genome_ref_first_index_file: genome_ref_first_index_file
        input_fastq_read1_files: trimm/output_data_fastq_read1_trimmed_files
      run: 03-map-pe.cwl
      out:
      - output_data_sorted_dedup_bam_files
      - output_index_dedup_bam_files
      - output_picard_mark_duplicates_files
      - output_pbc_files
      - output_bowtie_log
      - output_preseq_c_curve_files
      - output_percentage_uniq_reads
      - output_read_count_mapped
    qc:
      in:
        default_adapters_file: default_adapters_file
        input_read1_fastq_files: input_fastq_read1_files
        input_read2_fastq_files: input_fastq_read2_files
        nthreads: nthreads_qc
      run: 01-qc-pe.cwl
      out:
      - output_count_raw_reads_read1
      - output_count_raw_reads_read2
      - output_diff_counts_read1
      - output_diff_counts_read2
      - output_fastqc_report_files_read1
      - output_fastqc_report_files_read2
      - output_fastqc_data_files_read1
      - output_fastqc_data_files_read2
      - output_custom_adapters_read1
      - output_custom_adapters_read2
    quant:
      in:
        input_bam_files: map/output_data_sorted_dedup_bam_files
        input_genome_sizes: genome_sizes_file
        nthreads: nthreads_quant
      run: 05-quantification.cwl
      out:
      - bigwig_raw_files
      - bigwig_rpkm_extended_files
    trimm:
      in:
        nthreads: nthreads_trimm
        trimmomatic_java_opts: trimmomatic_java_opts
        input_read1_adapters_files: qc/output_custom_adapters_read1
        input_read2_fastq_files: input_fastq_read2_files
        input_read2_adapters_files: qc/output_custom_adapters_read2
        input_read1_fastq_files: input_fastq_read1_files
        trimmomatic_jar_path: trimmomatic_jar_path
      run: 02-trim-pe.cwl
      out:
      - output_data_fastq_read1_trimmed_files
      - output_data_fastq_read2_trimmed_files
      - output_trimmed_read1_fastq_read_count
      - output_trimmed_read2_fastq_read_count
    peak_call:
      in:
        genome_effective_size: genome_effective_size
        nthreads: nthreads_peakcall
        input_bam_files: map/output_data_sorted_dedup_bam_files
        input_bam_format:
          valueFrom: BAMPE
        as_narrowPeak_file: as_narrowPeak_file
        input_genome_sizes: genome_sizes_file
      run: 04-peakcall-narrow.cwl
      out:
      - output_spp_x_cross_corr
      - output_spp_cross_corr_plot
      - output_narrowpeak_file
      - output_narrowpeak_summits_file
      - output_narrowpeak_bigbed_file
      - output_peak_xls_file
      - output_filtered_read_count_file
      - output_peak_count_within_replicate
      - output_read_in_peak_count_within_replicate
 outputs:
    trimm_fastq_files_read1:
      doc: FASTQ files after trimming step
      type: File[]
      outputSource: trimm/output_data_fastq_read1_trimmed_files
    trimm_fastq_files_read2:
      doc: FASTQ files after trimming step
      type: File[]
      outputSource: trimm/output_data_fastq_read2_trimmed_files
    peak_call_narrowpeak_file:
      doc: Peaks in narrowPeak file format
      type: File[]
      outputSource: peak_call/output_narrowpeak_file
    map_bowtie_log_files:
      doc: Bowtie log file with mapping stats
      type: File[]
      outputSource: map/output_bowtie_log
    qc_fastqc_report_files_read2:
      doc: FastQC reports in zip format for paired read 2
      type: File[]
      outputSource: qc/output_fastqc_report_files_read2
    qc_fastqc_report_files_read1:
      doc: FastQC reports in zip format for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_report_files_read1
    quant_bigwig_raw_files:
      doc: Raw reads bigWig (signal) files
      type: File[]
      outputSource: quant/bigwig_raw_files
    peak_call_spp_x_cross_corr:
      doc: SPP strand cross correlation summary
      type: File[]
      outputSource: peak_call/output_spp_x_cross_corr
    peak_call_peak_xls_file:
      doc: Peak calling report file
      type: File[]
      outputSource: peak_call/output_peak_xls_file
    qc_count_raw_reads_read1:
      doc: Raw read counts of fastq files for read 1 after QC
      type: File[]
      outputSource: qc/output_count_raw_reads_read1
    qc_count_raw_reads_read2:
      doc: Raw read counts of fastq files for read 2 after QC
      type: File[]
      outputSource: qc/output_count_raw_reads_read2
    map_preseq_percentage_uniq_reads:
      doc: Preseq percentage of uniq reads
      type: File[]
      outputSource: map/output_percentage_uniq_reads
    map_pbc_files:
      doc: PCR Bottleneck Coefficient files (used to flag samples when pbc<0.5)
      type: File[]
      outputSource: map/output_pbc_files
    peak_call_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: peak_call/output_peak_count_within_replicate
    peak_call_spp_x_cross_corr_plot:
      doc: SPP strand cross correlation plot
      type: File[]
      outputSource: peak_call/output_spp_cross_corr_plot
    map_read_count_mapped:
      doc: Read counts of the mapped BAM files
      type: File[]
      outputSource: map/output_read_count_mapped
    quant_bigwig_rpkm_extended_files:
      doc: Fragment extended reads bigWig (signal) files
      type: File[]
      outputSource: quant/bigwig_rpkm_extended_files
    trimm_raw_counts_read2:
      doc: Raw read counts for R2 of fastq files after TRIMM
      type: File[]
      outputSource: trimm/output_trimmed_read2_fastq_read_count
    trimm_raw_counts_read1:
      doc: Raw read counts for R1 of fastq files after TRIMM
      type: File[]
      outputSource: trimm/output_trimmed_read1_fastq_read_count
    peak_call_filtered_read_count_file:
      doc: Filtered read count after peak calling
      type: File[]
      outputSource: peak_call/output_filtered_read_count_file
    map_dedup_bam_files:
      doc: Filtered BAM files (post-processing end point)
      type: File[]
      outputSource: map/output_data_sorted_dedup_bam_files
    map_mark_duplicates_files:
      doc: Summary of duplicates removed with Picard tool MarkDuplicates (for multiple reads aligned to the same positions
      type: File[]
      outputSource: map/output_picard_mark_duplicates_files
    map_preseq_c_curve_files:
      doc: Preseq c_curve output files
      type: File[]
      outputSource: map/output_preseq_c_curve_files
    qc_diff_counts_read1:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 1
      type: File[]
      outputSource: qc/output_diff_counts_read1
    qc_diff_counts_read2:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 2
      type: File[]
      outputSource: qc/output_diff_counts_read2
    map_dedup_bam_index_files:
      doc: Filtered BAM index files
      type: File[]
      outputSource: map/output_index_dedup_bam_files
    peak_call_read_in_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: peak_call/output_read_in_peak_count_within_replicate
    peak_call_narrowpeak_bigbed_file:
      doc: narrowPeaks in bigBed format
      type: File[]
      outputSource: peak_call/output_narrowpeak_bigbed_file
    peak_call_narrowpeak_summits_file:
      doc: Peaks summits in bedfile format
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: peak_call/output_narrowpeak_summits_file
    qc_fastqc_data_files_read2:
      doc: FastQC data files for paired read 2
      type: File[]
      outputSource: qc/output_fastqc_data_files_read2
    qc_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: qc/output_fastqc_data_files_read1
