#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0
doc: 'CUT-and-RUN 01 QC - reads: PE'
requirements:
 - class: ScatterFeatureRequirement
 - class: StepInputExpressionRequirement
 - class: InlineJavascriptRequirement
inputs:
   input_read1_fastq_files:
     doc: Input read1 fastq files
     type: File[]
   input_read2_fastq_files:
     doc: Input read2 fastq files
     type: File[]
   nthreads:
     doc: Number of threads.
     type: int
     default: 1
steps:
   extract_basename_read1:
     run: ../utils/extract-basename.cwl
     scatter: input_file
     in:
       input_file: input_read1_fastq_files
     out:
     - output_basename
   count_raw_reads_read1:
     run: ../utils/count-fastq-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_file
     - input_basename
     in:
       input_basename: extract_basename_read1/output_basename
       input_fastq_file: input_read1_fastq_files
     out:
     - output_read_count
   fastqc_read1:
     run: ../qc/fastqc.cwl
     scatter: input_fastq_file
     in:
       threads: nthreads
       input_fastq_file: input_read1_fastq_files
     out:
     - output_qc_report_file
   extract_fastqc_data_read1:
     run: ../qc/extract_fastqc_data.cwl
     scatterMethod: dotproduct
     scatter:
     - input_qc_report_file
     - input_basename
     in:
       input_basename: extract_basename_read1/output_basename
       input_qc_report_file: fastqc_read1/output_qc_report_file
     out:
     - output_fastqc_data_file
   count_fastqc_reads_read1:
     run: ../qc/count-fastqc-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastqc_data
     - input_basename
     in:
       input_fastqc_data: extract_fastqc_data_read1/output_fastqc_data_file
       input_basename: extract_basename_read1/output_basename
     out:
     - output_fastqc_read_count
   compare_read_counts_read1:
     run: ../qc/diff.cwl
     scatterMethod: dotproduct
     scatter:
     - file1
     - file2
     in:
       file2: count_fastqc_reads_read1/output_fastqc_read_count
       file1: count_raw_reads_read1/output_read_count
     out:
     - result
   extract_basename_read2:
     run: ../utils/extract-basename.cwl
     scatter: input_file
     in:
       input_file: input_read2_fastq_files
     out:
     - output_basename
   count_raw_reads_read2:
     run: ../utils/count-fastq-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_file
     - input_basename
     in:
       input_basename: extract_basename_read2/output_basename
       input_fastq_file: input_read2_fastq_files
     out:
     - output_read_count
   fastqc_read2:
     run: ../qc/fastqc.cwl
     scatter: input_fastq_file
     in:
       threads: nthreads
       input_fastq_file: input_read2_fastq_files
     out:
     - output_qc_report_file
   extract_fastqc_data_read2:
     run: ../qc/extract_fastqc_data.cwl
     scatterMethod: dotproduct
     scatter:
     - input_qc_report_file
     - input_basename
     in:
       input_basename: extract_basename_read2/output_basename
       input_qc_report_file: fastqc_read2/output_qc_report_file
     out:
     - output_fastqc_data_file
   count_fastqc_reads_read2:
     run: ../qc/count-fastqc-reads.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastqc_data
     - input_basename
     in:
       input_fastqc_data: extract_fastqc_data_read2/output_fastqc_data_file
       input_basename: extract_basename_read2/output_basename
     out:
     - output_fastqc_read_count
   compare_read_counts_read2:
     run: ../qc/diff.cwl
     scatterMethod: dotproduct
     scatter:
     - file1
     - file2
     in:
       file2: count_fastqc_reads_read2/output_fastqc_read_count
       file1: count_raw_reads_read2/output_read_count
     out:
     - result
outputs:
   output_fastqc_data_files_read1:
     doc: FastQC data files for paired read 1
     type: File[]
     outputSource: extract_fastqc_data_read1/output_fastqc_data_file
   output_count_raw_reads_read1:
     outputSource: count_raw_reads_read1/output_read_count
     type: File[]
   output_diff_counts_read1:
     outputSource: compare_read_counts_read1/result
     type: File[]
   output_fastqc_report_files_read1:
     doc: FastQC reports in zip format for paired read 1
     type: File[]
     outputSource: fastqc_read1/output_qc_report_file
   output_fastqc_data_files_read2:
     doc: FastQC data files for paired read 1
     type: File[]
     outputSource: extract_fastqc_data_read2/output_fastqc_data_file
   output_count_raw_reads_read2:
     outputSource: count_raw_reads_read2/output_read_count
     type: File[]
   output_diff_counts_read2:
     outputSource: compare_read_counts_read2/result
     type: File[]
   output_fastqc_report_files_read2:
     doc: FastQC reports in zip format for paired read 1
     type: File[]
     outputSource: fastqc_read2/output_qc_report_file