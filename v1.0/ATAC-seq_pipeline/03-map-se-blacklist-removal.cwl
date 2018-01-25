 class: Workflow
 cwlVersion: v1.0
 doc: 'ATAC-seq 03 mapping - reads: SE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    genome_sizes_file:
      doc: Genome sizes tab-delimited file (used in samtools)
      type: File
    nthreads:
      default: 1
      type: int
    picard_jar_path:
      default: /usr/picard/picard.jar
      doc: Picard Java jar file
      type: string
    picard_java_opts:
      doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
      type: string?
    input_fastq_files:
      doc: Input fastq files
      type: File[]
    ENCODE_blacklist_bedfile:
      doc: Bedfile containing ENCODE consensus blacklist regions to be excluded.
      type: File
    genome_ref_first_index_file:
      doc: Bowtie first index files for reference genome (e.g. *1.ebwt). The rest of the files should be in the same folder.
      type: File
 steps:
    filtered2sorted:
      run: ../map/samtools-sort.cwl
      in:
        nthreads: nthreads
        input_file: filter-unmapped/filtered_file
      scatter:
      - input_file
      out:
      - sorted_file
    remove_duplicates:
      run: ../map/picard-MarkDuplicates.cwl
      in:
        java_opts: picard_java_opts
        picard_jar_path: picard_jar_path
        output_filename: extract_basename_2/output_path
        input_file: filtered2sorted/sorted_file
      scatterMethod: dotproduct
      scatter:
      - input_file
      - output_filename
      out:
      - output_metrics_file
      - output_dedup_bam_file
    remove_encode_blacklist:
      run: ../map/bedtools-intersect.cwl
      in:
        a: remove_duplicates/output_dedup_bam_file
        b: ENCODE_blacklist_bedfile
        output_basename_file: mapped_file_basename/output_basename
        v:
          default: true
      scatterMethod: dotproduct
      scatter:
      - a
      - output_basename_file
      out:
      - file_wo_blacklist_regions
    preseq-c-curve:
      run: ../map/preseq-c_curve.cwl
      in:
        input_sorted_file: filtered2sorted/sorted_file
        output_file_basename: extract_basename_2/output_path
      scatterMethod: dotproduct
      scatter:
      - input_sorted_file
      - output_file_basename
      out:
      - output_file
    percent_uniq_reads:
      run: ../map/preseq-percent-uniq-reads.cwl
      in:
        preseq_c_curve_outfile: preseq-c-curve/output_file
      scatter: preseq_c_curve_outfile
      out:
      - output
    index_dedup_bams:
      run: ../map/samtools-index.cwl
      in:
        input_file: sort_dedup_bams/sorted_file
      scatter:
      - input_file
      out:
      - index_file
    mapped_filtered_reads_count:
      run: ../peak_calling/samtools-extract-number-mapped-reads.cwl
      in:
        output_suffix:
          valueFrom: .mapped_and_filtered.read_count.txt
        input_bam_file: sort_dedup_bams/sorted_file
      scatter: input_bam_file
      out:
      - output_read_count
    sort_bams:
      run: ../map/samtools-sort.cwl
      in:
        nthreads: nthreads
        input_file: sam2bam/bam_file
      scatter:
      - input_file
      out:
      - sorted_file
    mapped_file_basename:
      run: ../utils/extract-basename.cwl
      in:
        input_file: remove_duplicates/output_dedup_bam_file
      scatter: input_file
      out:
      - output_basename
    sam2bam:
      run: ../map/samtools2bam.cwl
      in:
        nthreads: nthreads
        input_file: bowtie-se/output_aligned_file
      scatter:
      - input_file
      out:
      - bam_file
    extract_basename_2:
      run: ../utils/remove-extension.cwl
      in:
        file_path: extract_basename_1/output_basename
      scatter: file_path
      out:
      - output_path
    extract_basename_1:
      run: ../utils/extract-basename.cwl
      in:
        input_file: input_fastq_files
      scatter: input_file
      out:
      - output_basename
    execute_pcr_bottleneck_coef:
      in:
        input_bam_files: filtered2sorted/sorted_file
        genome_sizes: genome_sizes_file
        input_output_filenames: extract_basename_2/output_path
      run: ../map/pcr-bottleneck-coef.cwl
      out:
      - pbc_file
    sort_dedup_bams:
      run: ../map/samtools-sort.cwl
      in:
        nthreads: nthreads
        input_file: remove_encode_blacklist/file_wo_blacklist_regions
      scatter:
      - input_file
      out:
      - sorted_file
    filter-unmapped:
      run: ../map/samtools-filter-unmapped.cwl
      in:
        output_filename: extract_basename_2/output_path
        input_file: sort_bams/sorted_file
      scatterMethod: dotproduct
      scatter:
      - input_file
      - output_filename
      out:
      - filtered_file
    mapped_reads_count:
      run: ../map/bowtie-log-read-count.cwl
      in:
        bowtie_log: bowtie-se/output_bowtie_log
      scatter: bowtie_log
      out:
      - output
    bowtie-se:
      run: ../map/bowtie-se.cwl
      in:
        nthreads: nthreads
        output_filename: extract_basename_2/output_path
        v:
          valueFrom: $(2)
        X:
          valueFrom: $(2000)
        genome_ref_first_index_file: genome_ref_first_index_file
        input_fastq_file: input_fastq_files
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - output_filename
      out:
      - output_aligned_file
      - output_bowtie_log
 outputs:
    output_pbc_files:
      doc: PCR Bottleneck Coeficient files.
      type: File[]
      outputSource: execute_pcr_bottleneck_coef/pbc_file
    output_read_count_mapped:
      doc: Read counts of the mapped BAM files
      type: File[]
      outputSource: mapped_reads_count/output
    output_index_dedup_bam_files:
      doc: Index for BAM files without duplicate reads.
      type: File[]
      outputSource: index_dedup_bams/index_file
    output_data_sorted_dedup_bam_files:
      doc: BAM files without duplicate reads.
      type: File[]
      outputSource: sort_dedup_bams/sorted_file
    output_picard_mark_duplicates_files:
      doc: Picard MarkDuplicates metrics files.
      type: File[]
      outputSource: remove_duplicates/output_metrics_file
    output_read_count_mapped_filtered:
      doc: Read counts of the mapped and filtered BAM files
      type: File[]
      outputSource: mapped_filtered_reads_count/output_read_count
    output_percentage_uniq_reads:
      doc: Percentage of uniq reads from preseq c_curve output
      type: File[]
      outputSource: percent_uniq_reads/output
    output_bowtie_log:
      doc: Bowtie log file.
      type: File[]
      outputSource: bowtie-se/output_bowtie_log
    output_preseq_c_curve_files:
      doc: Preseq c_curve output files.
      type: File[]
      outputSource: preseq-c-curve/output_file
