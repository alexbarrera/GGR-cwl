 class: Workflow
 cwlVersion: v1.0
 doc: 'ATAC-seq 02 trimming - reads: SE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    input_adapters_files:
      doc: Input adapters files
      type: File[]
    nthreads:
      default: 1
      doc: Number of threads
      type: int
    trimmomatic_java_opts:
      doc: JVM arguments should be a quoted, space separated list
      type: string?
    quality_score:
      default: -phred33
      type: string
    input_read1_fastq_files:
      doc: Input fastq files
      type: File[]
    trimmomatic_jar_path:
      default: /usr/share/java/trimmomatic.jar
      doc: Trimmomatic Java jar file
      type: string
 steps:
    count_fastq_reads:
      run: ../utils/count-fastq-reads.cwl
      in:
        input_basename: extract_basename/output_basename
        input_fastq_file: trimmomatic/output_read1_trimmed_file
      scatterMethod: dotproduct
      scatter:
      - input_fastq_file
      - input_basename
      out:
      - output_read_count
    extract_basename:
      run: ../utils/extract-basename.cwl
      in:
        input_file: trimmomatic/output_read1_trimmed_file
      scatter: input_file
      out:
      - output_basename
    trimmomatic:
      run: ../trimmomatic/trimmomatic.cwl
      in:
        phred:
          valueFrom: '33'
        nthreads: nthreads
        minlen:
          valueFrom: ${return 15}
        java_opts: trimmomatic_java_opts
        leading:
          valueFrom: ${return 3}
        slidingwindow:
          valueFrom: 4:20
        illuminaclip:
          valueFrom: 2:30:15
        input_read1_fastq_file: input_read1_fastq_files
        input_adapters_file: input_adapters_files
        trailing:
          valueFrom: ${return 3}
        trimmomatic_jar_path: trimmomatic_jar_path
        end_mode:
          valueFrom: SE
      scatterMethod: dotproduct
      scatter:
      - input_read1_fastq_file
      - input_adapters_file
      out:
      - output_read1_trimmed_file
 outputs:
    output_data_fastq_trimmed_files:
      doc: Trimmed fastq files
      type: File[]
      outputSource: trimmomatic/output_read1_trimmed_file
    trimmed_fastq_read_count:
      doc: Trimmed read counts of fastq files
      type: File[]
      outputSource: count_fastq_reads/output_read_count
