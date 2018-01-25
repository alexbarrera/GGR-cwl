 class: Workflow
 cwlVersion: v1.0
 doc: 'RNA-seq 01 QC - reads: PE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    input_fastq_read1_files:
      doc: Input read1 fastq files
      type: File[]
    default_adapters_file:
      doc: Adapters file
      type: File
    nthreads:
      doc: Number of threads.
      type: int
 steps:
    extract_basename_read1:
      run: ../utils/extract-basename.cwl
      in:
        input_file: input_fastq_read1_files
      scatter: input_file
      out:
      - output_basename
    overrepresented_sequence_extract_read1:
      run: ../qc/overrepresented_sequence_extract.cwl
      in:
        input_fastqc_data: extract_fastqc_data_read1/output_fastqc_data_file
        input_basename: extract_basename_read1/output_basename
        default_adapters_file: default_adapters_file
      scatterMethod: dotproduct
      scatter:
      - input_fastqc_data
      - input_basename
      out:
      - output_custom_adapters
    compare_read_counts_read1:
      run: ../qc/diff.cwl
      in:
        file2: count_fastqc_reads_read1/output_fastqc_read_count
        file1: count_raw_reads_read1/output_read_count
      scatterMethod: dotproduct
      scatter:
      - file1
      - file2
      out:
      - result
    fastqc_read1:
      run: ../qc/fastqc.cwl
      in:
        threads: nthreads
        input_fastq_file: input_fastq_read1_files
      scatter: input_fastq_file
      out:
      - output_qc_report_file
    count_fastqc_reads_read1:
      run: ../qc/count-fastqc-reads.cwl
      in:
        input_fastqc_data: extract_fastqc_data_read1/output_fastqc_data_file
        input_basename: extract_basename_read1/output_basename
      scatterMethod: dotproduct
      scatter:
      - input_fastqc_data
      - input_basename
      out:
      - output_fastqc_read_count
    count_raw_reads_read1:
      run: ../utils/count-fastq-reads.cwl
      in:
        input_basename: extract_basename_read1/output_basename
        input_fastq_file: input_fastq_read1_files
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - input_basename
      out:
      - output_read_count
    extract_fastqc_data_read1:
      run: ../qc/extract_fastqc_data.cwl
      in:
        input_basename: extract_basename_read1/output_basename
        input_qc_report_file: fastqc_read1/output_qc_report_file
      scatterMethod: dotproduct
      scatter:
      - input_qc_report_file
      - input_basename
      out:
      - output_fastqc_data_file
 outputs:
    output_fastqc_data_files_read1:
      doc: FastQC data files for paired read 1
      type: File[]
      outputSource: extract_fastqc_data_read1/output_fastqc_data_file
    output_diff_counts_read1:
      outputSource: compare_read_counts_read1/result
      type: File[]
    output_count_raw_reads_read1:
      outputSource: count_raw_reads_read1/output_read_count
      type: File[]
    output_fastqc_report_files_read1:
      doc: FastQC reports in zip format for paired read 1
      type: File[]
      outputSource: fastqc_read1/output_qc_report_file
    output_custom_adapters_read1:
      outputSource: overrepresented_sequence_extract_read1/output_custom_adapters
      type: File[]
