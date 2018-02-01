 class: Workflow
 cwlVersion: v1.0
 doc: 'ATAC-seq 02 trimming - reads: PE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    nthreads:
      default: 1
      doc: Number of threads
      type: int
    trimmomatic_java_opts:
      doc: JVM arguments should be a quoted, space separated list
      type: string?
    input_read1_adapters_files:
      doc: Input read 1 adapters files
      type: File[]
    quality_score:
      default: -phred33
      type: string
    trimmomatic_jar_path:
      default: /usr/share/java/trimmomatic.jar
      doc: Trimmomatic Java jar file
      type: string
    input_read2_adapters_files:
      doc: Input read 2 adapters files
      type: File[]
    input_read1_fastq_files:
      doc: Input read 1 fastq files
      type: File[]
    input_read2_fastq_files:
      doc: Input read 2 fastq files
      type: File[]
 steps:
    extract_basename_read2:
      run: ../utils/extract-basename.cwl
      in:
        input_file: trimmomatic/output_read2_trimmed_paired_file
      scatter: input_file
      out:
      - output_basename
    extract_basename_read1:
      run: ../utils/extract-basename.cwl
      in:
        input_file: trimmomatic/output_read1_trimmed_file
      scatter: input_file
      out:
      - output_basename
    concat_adapters:
      run: ../utils/concat-files.cwl
      in:
        input_file1: input_read1_adapters_files
        input_file2: input_read2_adapters_files
      scatterMethod: dotproduct
      scatter:
      - input_file1
      - input_file2
      out:
      - output_file
    count_fastq_reads_read2:
      run: ../utils/count-fastq-reads.cwl
      in:
        input_basename: extract_basename_read2/output_basename
        input_fastq_file: trimmomatic/output_read2_trimmed_paired_file
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - input_basename
      out:
      - output_read_count
    count_fastq_reads_read1:
      run: ../utils/count-fastq-reads.cwl
      in:
        input_basename: extract_basename_read1/output_basename
        input_fastq_file: trimmomatic/output_read1_trimmed_file
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - input_basename
      out:
      - output_read_count
    trimmomatic:
      run: ../trimmomatic/trimmomatic.cwl
      in:
        phred:
          valueFrom: '33'
        nthreads: nthreads
        minlen:
          valueFrom: ${return 15}
        input_read2_fastq_file: input_read2_fastq_files
        leading:
          valueFrom: ${return 3}
        slidingwindow:
          valueFrom: 4:20
        illuminaclip:
          valueFrom: 2:30:15
        end_mode:
          valueFrom: PE
        java_opts: trimmomatic_java_opts
        input_adapters_file: concat_adapters/output_file
        trailing:
          valueFrom: ${return 3}
        trimmomatic_jar_path: trimmomatic_jar_path
        input_read1_fastq_file: input_read1_fastq_files
      scatterMethod: dotproduct
      scatter:
      - input_read1_fastq_file
      - input_read2_fastq_file
      - input_adapters_file
      out:
      - output_read1_trimmed_file
      - output_read2_trimmed_paired_file
 outputs:
    output_trimmed_read1_fastq_read_count:
      doc: Trimmed read counts of paired read 1 fastq files
      type: File[]
      outputSource: count_fastq_reads_read1/output_read_count
    output_data_fastq_read2_trimmed_files:
      doc: Trimmed fastq files for paired read 2
      type: File[]
      outputSource: trimmomatic/output_read2_trimmed_paired_file
    output_trimmed_read2_fastq_read_count:
      doc: Trimmed read counts of paired read 2 fastq files
      type: File[]
      outputSource: count_fastq_reads_read2/output_read_count
    output_data_fastq_read1_trimmed_files:
      doc: Trimmed fastq files for paired read 1
      type: File[]
      outputSource: trimmomatic/output_read1_trimmed_file
