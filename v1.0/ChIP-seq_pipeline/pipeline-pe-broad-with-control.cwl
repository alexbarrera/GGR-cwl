 class: Workflow
 cwlVersion: v1.0
 doc: 'ChIP-seq pipeline - reads: PE, region: broad, samples: treatment and control.'
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
 inputs:
    genome_sizes_file:
      doc: Genome sizes tab-delimited file (used in samtools)
      type: File
    genome_effective_size:
      default: hs
      doc: Effective genome size used by MACS2. It can be numeric or a shortcuts:'hs' for human (2.7e9), 'mm' for mouse (1.87e9), 'ce' for C. elegans (9e7) and 'dm' for fruitfly (1.2e8), Default:hs
      type: string
    input_control_fastq_read1_files:
      doc: Input control fastq paired-end read 1 files
      type: File[]
    input_control_fastq_read2_files:
      doc: Input control fastq paired-end read 2 files
      type: File[]
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
    ENCODE_blacklist_bedfile:
      doc: Bedfile containing ENCODE consensus blacklist regions to be excluded.
      type: File
    nthreads_qc:
      doc: Number of threads required for the 01-qc step
      type: int
    as_broadPeak_file:
      doc: Definition broadPeak file in AutoSql format (used in bedToBigBed)
      type: File
    picard_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    nthreads_map:
      doc: Number of threads required for the 03-map step
      type: int
    nthreads_trimm:
      doc: Number of threads required for the 02-trim step
      type: int
    input_treatment_fastq_read1_files:
      doc: Input treatment fastq paired-end read 1 files
      type: File[]
    genome_ref_first_index_file:
      doc: '"First index file of Bowtie reference genome with extension 1.ebwt. \ (Note: the rest of the index files MUST be in the same folder)" '
      type: File
    input_treatment_fastq_read2_files:
      doc: Input treatment fastq paired-end read 2 files
      type: File[]
    trimmomatic_jar_path:
      doc: Trimmomatic Java jar file
      type: string
 steps:
    map_treatment:
      in:
        genome_sizes_file: genome_sizes_file
        input_fastq_read2_files: trimm_treatment/output_data_fastq_read2_trimmed_files
        nthreads: nthreads_map
        picard_jar_path: picard_jar_path
        picard_java_opts: picard_java_opts
        ENCODE_blacklist_bedfile: ENCODE_blacklist_bedfile
        genome_ref_first_index_file: genome_ref_first_index_file
        input_fastq_read1_files: trimm_treatment/output_data_fastq_read1_trimmed_files
      run: 03-map-pe.cwl
      out:
      - output_data_sorted_dedup_bam_files
      - output_picard_mark_duplicates_files
      - output_pbc_files
      - output_bowtie_log
      - output_preseq_c_curve_files
      - output_percentage_uniq_reads
      - output_read_count_mapped
    quant:
      in:
        nthreads: nthreads_quant
        input_trt_bam_files: map_treatment/output_data_sorted_dedup_bam_files
        input_ctrl_bam_files: map_control/output_data_sorted_dedup_bam_files
        input_genome_sizes: genome_sizes_file
      run: 05-quantification-with-control.cwl
      out:
      - bigwig_raw_files
      - bigwig_rpkm_extended_files
      - bigwig_ctrl_rpkm_extended_files
      - bigwig_ctrl_subtracted_rpkm_extended_files
    peak_call:
      in:
        genome_effective_size: genome_effective_size
        nthreads: nthreads_peakcall
        input_bam_files: map_treatment/output_data_sorted_dedup_bam_files
        input_bam_format:
          valueFrom: BAMPE
        input_control_bam_files: map_control/output_data_sorted_dedup_bam_files
        as_broadPeak_file: as_broadPeak_file
        input_genome_sizes: genome_sizes_file
      run: 04-peakcall-broad-with-control.cwl
      out:
      - output_spp_x_cross_corr
      - output_spp_cross_corr_plot
      - output_broadpeak_file
      - output_broadpeak_summits_file
      - output_broadpeak_bigbed_file
      - output_peak_xls_file
      - output_filtered_read_count_file
      - output_peak_count_within_replicate
      - output_read_in_peak_count_within_replicate
    trimm_treatment:
      in:
        nthreads: nthreads_trimm
        trimmomatic_java_opts: trimmomatic_java_opts
        input_read1_adapters_files: qc_treatment/output_custom_adapters_read1
        input_read2_fastq_files: input_treatment_fastq_read2_files
        input_read2_adapters_files: qc_treatment/output_custom_adapters_read2
        input_read1_fastq_files: input_treatment_fastq_read1_files
        trimmomatic_jar_path: trimmomatic_jar_path
      run: 02-trim-pe.cwl
      out:
      - output_data_fastq_read1_trimmed_files
      - output_data_fastq_read2_trimmed_files
      - output_trimmed_read1_fastq_read_count
      - output_trimmed_read2_fastq_read_count
    qc_control:
      in:
        default_adapters_file: default_adapters_file
        input_read1_fastq_files: input_control_fastq_read1_files
        input_read2_fastq_files: input_control_fastq_read2_files
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
    qc_treatment:
      in:
        default_adapters_file: default_adapters_file
        input_read1_fastq_files: input_treatment_fastq_read1_files
        input_read2_fastq_files: input_treatment_fastq_read2_files
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
    trimm_control:
      in:
        nthreads: nthreads_trimm
        trimmomatic_java_opts: trimmomatic_java_opts
        input_read1_adapters_files: qc_control/output_custom_adapters_read1
        input_read2_fastq_files: input_control_fastq_read2_files
        input_read2_adapters_files: qc_control/output_custom_adapters_read2
        input_read1_fastq_files: input_control_fastq_read1_files
        trimmomatic_jar_path: trimmomatic_jar_path
      run: 02-trim-pe.cwl
      out:
      - output_data_fastq_read1_trimmed_files
      - output_data_fastq_read2_trimmed_files
      - output_trimmed_read1_fastq_read_count
      - output_trimmed_read2_fastq_read_count
    map_control:
      in:
        genome_sizes_file: genome_sizes_file
        input_fastq_read2_files: trimm_control/output_data_fastq_read2_trimmed_files
        nthreads: nthreads_map
        picard_jar_path: picard_jar_path
        picard_java_opts: picard_java_opts
        ENCODE_blacklist_bedfile: ENCODE_blacklist_bedfile
        genome_ref_first_index_file: genome_ref_first_index_file
        input_fastq_read1_files: trimm_control/output_data_fastq_read1_trimmed_files
      run: 03-map-pe.cwl
      out:
      - output_data_sorted_dedup_bam_files
      - output_picard_mark_duplicates_files
      - output_pbc_files
      - output_bowtie_log
      - output_preseq_c_curve_files
      - output_percentage_uniq_reads
      - output_read_count_mapped
 outputs:
    map_control_preseq_percentage_uniq_reads:
      doc: Preseq percentage of uniq reads
      type: File[]
      outputSource: map_control/output_percentage_uniq_reads
    map_treatment_preseq_percentage_uniq_reads:
      doc: Preseq percentage of uniq reads
      type: File[]
      outputSource: map_treatment/output_percentage_uniq_reads
    qc_control_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: qc_control/output_fastqc_data_files_read1
    qc_treatment_diff_counts_read2:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 2 for treatment
      type: File[]
      outputSource: qc_treatment/output_diff_counts_read2
    qc_treatment_diff_counts_read1:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 1 for treatment
      type: File[]
      outputSource: qc_treatment/output_diff_counts_read1
    qc_control_fastqc_data_files_read2:
      doc: FastQC data files for paired read 2
      type: File[]
      outputSource: qc_control/output_fastqc_data_files_read2
    map_treatment_dedup_bam_files:
      doc: Filtered BAM files (post-processing end point) for treatment
      type: File[]
      outputSource: map_treatment/output_data_sorted_dedup_bam_files
    peak_call_broadpeak_file:
      doc: Peaks in broadPeak file format
      type: File[]
      outputSource: peak_call/output_broadpeak_file
    peak_call_read_in_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: peak_call/output_read_in_peak_count_within_replicate
    quant_ctrl_bigwig_rpkm_extended_files:
      doc: Fragment extended reads bigWig (signal) control files
      type: File[]
      outputSource: quant/bigwig_ctrl_rpkm_extended_files
    peak_call_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: peak_call/output_peak_count_within_replicate
    quant_bigwig_ctrl_subtracted_rpkm_extended_files:
      doc: Fragment control subtracted extended reads bigWig (signal) files
      type: File[]
      outputSource: quant/bigwig_ctrl_subtracted_rpkm_extended_files
    map_control_pbc_files:
      doc: PCR Bottleneck Coefficient files (used to flag samples when pbc<0.5) for control
      type: File[]
      outputSource: map_control/output_pbc_files
    quant_bigwig_raw_files:
      doc: Raw reads bigWig (signal) files
      type: File[]
      outputSource: quant/bigwig_raw_files
    map_treatment_read_count_mapped:
      doc: Read counts of the mapped BAM files
      type: File[]
      outputSource: map_treatment/output_read_count_mapped
    qc_control_count_raw_reads_read2:
      doc: Raw read counts of fastq files for read 2 after QC for control
      type: File[]
      outputSource: qc_control/output_count_raw_reads_read2
    map_treatment_mark_duplicates_files:
      doc: Summary of duplicates removed with Picard tool MarkDuplicates (for multiple reads aligned to the same positions) for treatment
      type: File[]
      outputSource: map_treatment/output_picard_mark_duplicates_files
    qc_control_count_raw_reads_read1:
      doc: Raw read counts of fastq files for read 1 after QC for control
      type: File[]
      outputSource: qc_control/output_count_raw_reads_read1
    peak_call_spp_x_cross_corr:
      doc: SPP strand cross correlation summary
      type: File[]
      outputSource: peak_call/output_spp_x_cross_corr
    peak_call_peak_xls_file:
      doc: Peak calling report file
      type: File[]
      outputSource: peak_call/output_peak_xls_file
    trimm_control_fastq_files_read2:
      doc: FASTQ files after trimming step for control
      type: File[]
      outputSource: trimm_control/output_data_fastq_read2_trimmed_files
    trimm_control_fastq_files_read1:
      doc: FASTQ files after trimming step for control
      type: File[]
      outputSource: trimm_control/output_data_fastq_read1_trimmed_files
    qc_treatment_count_raw_reads_read2:
      doc: Raw read counts of fastq files for read 2 after QC for treatment
      type: File[]
      outputSource: qc_treatment/output_count_raw_reads_read2
    qc_treatment_count_raw_reads_read1:
      doc: Raw read counts of fastq files for read 1 after QC for treatment
      type: File[]
      outputSource: qc_treatment/output_count_raw_reads_read1
    peak_call_spp_x_cross_corr_plot:
      doc: SPP strand cross correlation plot
      type: File[]
      outputSource: peak_call/output_spp_cross_corr_plot
    quant_bigwig_rpkm_extended_files:
      doc: Fragment extended reads bigWig (signal) files
      type: File[]
      outputSource: quant/bigwig_rpkm_extended_files
    trimm_treatment_fastq_files_read2:
      doc: FASTQ files after trimming step for treatment
      type: File[]
      outputSource: trimm_treatment/output_data_fastq_read2_trimmed_files
    trimm_treatment_fastq_files_read1:
      doc: FASTQ files after trimming step for treatment
      type: File[]
      outputSource: trimm_treatment/output_data_fastq_read1_trimmed_files
    trimm_control_raw_counts_read1:
      doc: Raw read counts for R1 of fastq files after TRIMM for control
      type: File[]
      outputSource: trimm_control/output_trimmed_read1_fastq_read_count
    trimm_control_raw_counts_read2:
      doc: Raw read counts for R2 of fastq files after TRIMM for control
      type: File[]
      outputSource: trimm_control/output_trimmed_read2_fastq_read_count
    map_treatment_pbc_files:
      doc: PCR Bottleneck Coefficient files (used to flag samples when pbc<0.5) for treatment
      type: File[]
      outputSource: map_treatment/output_pbc_files
    map_control_read_count_mapped:
      doc: Read counts of the mapped BAM files
      type: File[]
      outputSource: map_control/output_read_count_mapped
    trimm_treatment_raw_counts_read2:
      doc: Raw read counts for R2 of fastq files after TRIMM for treatment
      type: File[]
      outputSource: trimm_treatment/output_trimmed_read2_fastq_read_count
    trimm_treatment_raw_counts_read1:
      doc: Raw read counts for R1 of fastq files after TRIMM for treatment
      type: File[]
      outputSource: trimm_treatment/output_trimmed_read1_fastq_read_count
    peak_call_filtered_read_count_file:
      doc: Filtered read count after peak calling
      type: File[]
      outputSource: peak_call/output_filtered_read_count_file
    peak_call_broadpeak_summits_file:
      doc: Peaks summits in bedfile format
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: peak_call/output_broadpeak_summits_file
    map_control_dedup_bam_files:
      doc: Filtered BAM files (post-processing end point) for control
      type: File[]
      outputSource: map_control/output_data_sorted_dedup_bam_files
    qc_treatment_fastqc_report_files_read2:
      doc: FastQC reports in zip format for paired read 2
      type: File[]
      outputSource: qc_treatment/output_fastqc_report_files_read2
    map_control_bowtie_log_files:
      doc: Bowtie log file with mapping stats for control
      type: File[]
      outputSource: map_control/output_bowtie_log
    qc_control_diff_counts_read2:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 2 for control
      type: File[]
      outputSource: qc_control/output_diff_counts_read2
    qc_control_diff_counts_read1:
      doc: Diff file between number of raw reads and number of reads counted by FASTQC, read 1 for control
      type: File[]
      outputSource: qc_control/output_diff_counts_read1
    qc_control_fastqc_report_files_read1:
      doc: FastQC reports in zip format for paired read 1
      type: File[]
      outputSource: qc_control/output_fastqc_report_files_read1
    map_control_preseq_c_curve_files:
      doc: Preseq c_curve output files for control
      type: File[]
      outputSource: map_control/output_preseq_c_curve_files
    qc_control_fastqc_report_files_read2:
      doc: FastQC reports in zip format for paired read 2
      type: File[]
      outputSource: qc_control/output_fastqc_report_files_read2
    qc_treatment_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: qc_treatment/output_fastqc_data_files_read1
    map_treatment_bowtie_log_files:
      doc: Bowtie log file with mapping stats for treatment
      type: File[]
      outputSource: map_treatment/output_bowtie_log
    qc_treatment_fastqc_data_files_read2:
      doc: FastQC data files for paired read 2
      type: File[]
      outputSource: qc_treatment/output_fastqc_data_files_read2
    map_control_mark_duplicates_files:
      doc: Summary of duplicates removed with Picard tool MarkDuplicates (for multiple reads aligned to the same positions) for control
      type: File[]
      outputSource: map_control/output_picard_mark_duplicates_files
    peak_call_broadpeak_bigbed_file:
      doc: broadPeaks in bigBed format
      type: File[]
      outputSource: peak_call/output_broadpeak_bigbed_file
    qc_treatment_fastqc_report_files_read1:
      doc: FastQC reports in zip format for paired read 1
      type: File[]
      outputSource: qc_treatment/output_fastqc_report_files_read1
    map_treatment_preseq_c_curve_files:
      doc: Preseq c_curve output files for treatment
      type: File[]
      outputSource: map_treatment/output_preseq_c_curve_files
