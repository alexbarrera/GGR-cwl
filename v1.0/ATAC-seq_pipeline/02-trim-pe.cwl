#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0
doc: 'ATAC-seq 02 trimming - reads: PE'
requirements:
 - class: ScatterFeatureRequirement
 - class: StepInputExpressionRequirement
 - class: InlineJavascriptRequirement
inputs:
   input_read1_fastq_files:
     doc: Input fastq files for paired_read1
     type: File[]
   input_read1_adapters_files:
     doc: Input adapters files for paired_read1
     type: File[]
   input_read2_fastq_files:
     doc: Input fastq files for paired_read2
     type: File[]
   input_read2_adapters_files:
     doc: Input adapters files for paired_read2
     type: File[]
   quality_score:
     default: -phred33
     type: string
   trimmomatic_jar_path:
     default: /usr/share/java/trimmomatic.jar
     doc: Trimmomatic Java jar file
     type: string
   trimmomatic_java_opts:
     doc: JVM arguments should be a quoted, space separated list
     type: string?
   nthreads:
     default: 1
     doc: Number of threads
     type: int
steps:
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
   extract_basename_read1:
     run: ../utils/basename.cwl
     scatter: file_path
     in:
       file_path:
         source: trimmomatic/output_read1_trimmed_file
         valueFrom: $(self.basename)
       sep:
         valueFrom: '(\.fastq.gz|\.fastq)'
       do_not_escape_sep:
         valueFrom: ${return true}
     out:
     - basename
   extract_basename_read2:
     run: ../utils/basename.cwl
     scatter: file_path
     in:
       file_path:
         source: trimmomatic/output_read2_trimmed_paired_file
         valueFrom: $(self.basename)
       sep:
         valueFrom: '(\.fastq.gz|\.fastq)'
       do_not_escape_sep:
         valueFrom: ${return true}
     out:
     - basename
   trimmomatic:
     run: ../trimmomatic/trimmomatic.cwl
     scatterMethod: dotproduct
     scatter:
     - input_read1_fastq_file
     - input_read2_fastq_file
     - input_adapters_file
     in:
       input_read1_fastq_file: input_read1_fastq_files
       input_read2_fastq_file: input_read2_fastq_files
       input_adapters_file: concat_adapters/output_file
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
       trailing:
         valueFrom: ${return 3}
       trimmomatic_jar_path: trimmomatic_jar_path
       end_mode:
         valueFrom: PE
     out:
     - output_read1_trimmed_file
     - output_read2_trimmed_paired_file
   count_fastq_reads_read1:
     run: ../utils/count-fastq-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_file
     - input_basename
     in:
       input_basename: extract_basename_read1/basename
       input_fastq_file: trimmomatic/output_read1_trimmed_file
     out:
     - output_read_count
   count_fastq_reads_read2:
     run: ../utils/count-fastq-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_file
     - input_basename
     in:
       input_basename: extract_basename_read2/basename
       input_fastq_file: trimmomatic/output_read2_trimmed_paired_file
     out:
     - output_read_count
outputs:
   output_data_fastq_read1_trimmed_files:
     doc: Trimmed fastq files for paired_read1
     type: File[]
     outputSource: trimmomatic/output_read1_trimmed_file
   output_trimmed_read1_fastq_read_count:
     doc: Trimmed read counts of fastq files for paired_read1
     type: File[]
     outputSource: count_fastq_reads_read1/output_read_count
   output_data_fastq_read2_trimmed_files:
     doc: Trimmed fastq files for paired_read2
     type: File[]
     outputSource: trimmomatic/output_read2_trimmed_paired_file
   output_trimmed_read2_fastq_read_count:
     doc: Trimmed read counts of fastq files for paired_read2
     type: File[]
     outputSource: count_fastq_reads_read2/output_read_count