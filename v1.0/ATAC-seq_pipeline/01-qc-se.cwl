 class: Workflow
 cwlVersion: v1.0
 doc: 'ATAC-seq 01 QC - reads: SE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    nthreads:
      doc: Number of threads.
      type: int
    default_adapters_file:
      doc: Adapters file
      type: File
    input_fastq_files:
      doc: Input fastq files
      type: File[]
 steps:
    count_fastqc_reads:
      run: ../qc/count-fastqc-reads.cwl
      in:
        input_fastqc_data: extract_fastqc_data/output_fastqc_data_file
        input_basename: extract_basename/output_basename
      scatterMethod: dotproduct
      scatter:
      - input_fastqc_data
      - input_basename
      out:
      - output_fastqc_read_count
    fastqc:
      run: ../qc/fastqc.cwl
      in:
        threads: nthreads
        input_fastq_file: input_fastq_files
      scatter: input_fastq_file
      out:
      - output_qc_report_file
    extract_basename:
      run: ../utils/extract-basename.cwl
      in:
        input_file: input_fastq_files
      scatter: input_file
      out:
      - output_basename
    compare_read_counts:
      run: ../qc/diff.cwl
      in:
        file2: count_fastqc_reads/output_fastqc_read_count
        file1: count_raw_reads/output_read_count
      scatterMethod: dotproduct
      scatter:
      - file1
      - file2
      out:
      - result
    count_raw_reads:
      run: ../utils/count-fastq-reads.cwl
      in:
        input_basename: extract_basename/output_basename
        input_fastq_file: input_fastq_files
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - input_basename
      out:
      - output_read_count
    overrepresented_sequence_extract:
      run: ../qc/overrepresented_sequence_extract.cwl
      in:
        input_fastqc_data: extract_fastqc_data/output_fastqc_data_file
        input_basename: extract_basename/output_basename
        default_adapters_file: default_adapters_file
      scatterMethod: dotproduct
      scatter:
      - input_fastqc_data
      - input_basename
      out:
      - output_custom_adapters
    extract_fastqc_data:
      run: ../qc/extract_fastqc_data.cwl
      in:
        input_basename: extract_basename/output_basename
        input_qc_report_file: fastqc/output_qc_report_file
      scatterMethod: dotproduct
      scatter:
      - input_qc_report_file
      - input_basename
      out:
      - output_fastqc_data_file
 outputs:
    output_raw_read_counts:
      doc: Raw read counts of fastq files
      type: File[]
      outputSource: count_raw_reads/output_read_count
    output_fastqc_data_files:
      outputSource: extract_fastqc_data/output_fastqc_data_file
      type: File[]
    output_custom_adapters:
      outputSource: overrepresented_sequence_extract/output_custom_adapters
      type: File[]
    output_fastqc_read_counts:
      doc: Read counts of fastq files from FastQC
      type: File[]
      outputSource: count_fastqc_reads/output_fastqc_read_count
    output_fastqc_report_files:
      doc: FastQC reports in zip format
      type: File[]
      outputSource: fastqc/output_qc_report_file
