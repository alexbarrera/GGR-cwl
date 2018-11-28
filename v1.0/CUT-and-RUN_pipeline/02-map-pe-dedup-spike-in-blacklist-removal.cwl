#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0
doc: 'CUT-and-RUN 02 mapping - reads: PE - removing duplicates - blacklist removal - spike in'
requirements:
 - class: ScatterFeatureRequirement
 - class: SubworkflowFeatureRequirement
 - class: StepInputExpressionRequirement
 - class: InlineJavascriptRequirement
 - class: MultipleInputFeatureRequirement
inputs:
   input_fastq_read1_files:
     doc: Input fastq paired-end read 1 files
     type: File[]
   input_fastq_read2_files:
     doc: Input fastq paired-end read 2 files
     type: File[]
   picard_jar_path:
     default: /usr/picard/picard.jar
     doc: Picard Java jar file
     type: string
   picard_java_opts:
     doc: JVM arguments should be a quoted, space separated list (e.g. "-Xms128m -Xmx512m")
     type: string?
   ENCODE_blacklist_bedfile:
     doc: Bedfile containing ENCODE consensus blacklist regions to be excluded.
     type: File
   spike_in_genome_ref_first_index_file:
     doc: Bowtie first index file for spike-in reference genome (e.g. *.1.bt2). The rest of the files should be in the same folder.
     type: File
     secondaryFiles:
       - ^^.2.bt2
       - ^^.3.bt2
       - ^^.4.bt2
       - ^^.rev.1.bt2
       - ^^.rev.2.bt2
   genome_sizes_file:
     doc: Genome sizes tab-delimited file (used in samtools)
     type: File
   genome_ref_first_index_file:
     doc: Bowtie first index files for reference genome (e.g. *.1.bt2). The rest of the files should be in the same folder.
     type: File
     secondaryFiles:
       - ^^.2.bt2
       - ^^.3.bt2
       - ^^.4.bt2
       - ^^.rev.1.bt2
       - ^^.rev.2.bt2
   nthreads:
     default: 1
     type: int
steps:
   extract_basename_1:
     run: ../utils/extract-basename.cwl
     in:
       input_file: input_fastq_read1_files
     scatter: input_file
     out:
     - output_basename
   extract_basename_2:
     run: ../utils/remove-extension.cwl
     in:
       file_path: extract_basename_1/output_basename
     scatter: file_path
     out:
     - output_path
   bowtie2:
     run: ../map/bowtie2.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_read1_file
     - input_fastq_read2_file
     - output_filename
     in:
       input_fastq_read1_file: input_fastq_read1_files
       input_fastq_read2_file: input_fastq_read2_files
       output_filename: extract_basename_2/output_path
       local:
         valueFrom: ${return true}
       very-sensitive-local:
         valueFrom: ${return true}
       no-unal:
         valueFrom: ${return true}
       no-mixed:
         valueFrom: ${return true}
       no-discordant:
         valueFrom: ${return true}
       phred33:
         valueFrom: ${return true}
       I:
         valueFrom: ${return 10}
       X:
         valueFrom: ${return 700}
       genome_ref_first_index_file: genome_ref_first_index_file
       nthreads: nthreads
     out:
     - outfile
     - output_bowtie_log
   sam2bam:
     run: ../map/samtools2bam.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: bowtie2/outfile
     out:
     - bam_file
   sort_bams:
     run: ../map/samtools-sort.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: sam2bam/bam_file
     out:
     - sorted_file
   index_sorted_bams:
     run: ../map/samtools-index.cwl
     scatter:
     - input_file
     in:
       input_file: sort_bams/sorted_file
     out:
     - indexed_file
   preseq-c-curve:
     run: ../map/preseq-c_curve.cwl
     scatterMethod: dotproduct
     scatter:
     - input_sorted_file
     - output_file_basename
     in:
       input_sorted_file: sort_bams/sorted_file
       output_file_basename: extract_basename_2/output_path
       pe:
         valueFrom: ${return true}
     out:
     - output_file
   execute_pcr_bottleneck_coef:
     in:
       input_bam_files: sort_bams/sorted_file
       genome_sizes: genome_sizes_file
       input_output_filenames: extract_basename_2/output_path
     run: ../map/pcr-bottleneck-coef.cwl
     out:
     - pbc_file
   mark_duplicates:
     run: ../map/picard-MarkDuplicates.cwl
     scatterMethod: dotproduct
     scatter:
     - input_file
     - output_filename
     in:
       java_opts: picard_java_opts
       picard_jar_path: picard_jar_path
       output_filename: extract_basename_2/output_path
       input_file: index_sorted_bams/indexed_file
       output_suffix:
         valueFrom: bam
     out:
     - output_metrics_file
     - output_dedup_bam_file
   sort_dups_marked_bams:
     run: ../map/samtools-sort.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: mark_duplicates/output_dedup_bam_file
       suffix:
         valueFrom: .dups_marked.bam
     out:
     - sorted_file
   index_dups_marked_bams:
     run: ../map/samtools-index.cwl
     scatter:
     - input_file
     in:
       input_file: sort_dups_marked_bams/sorted_file
     out:
     - indexed_file
   remove_duplicates:
     run: ../map/samtools-view.cwl
     scatter:
     - input_file
     in:
       input_file: index_dups_marked_bams/indexed_file
       F:
         valueFrom: ${return 1024}
       suffix:
         valueFrom: .dedup.bam
       b:
         valueFrom: ${return true}
       outfile_name:
         valueFrom: ${return inputs.input_file.basename.replace('dups_marked', 'dedup')}
     out:
     - outfile
   sort_dedup_bams:
     run: ../map/samtools-sort.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: remove_duplicates/outfile
     out:
     - sorted_file
   index_dedup_bams:
     run: ../map/samtools-index.cwl
     scatter:
     - input_file
     in:
       input_file: sort_dedup_bams/sorted_file
     out:
     - indexed_file
   bowtie2_spike_in:
     run: ../map/bowtie2.cwl
     scatterMethod: dotproduct
     scatter:
     - input_fastq_read1_file
     - input_fastq_read2_file
     - output_filename
     in:
       input_fastq_read1_file: input_fastq_read1_files
       input_fastq_read2_file: input_fastq_read2_files
       output_filename:
         source: extract_basename_2/output_path
         valueFrom: ${return  self + '.spike_in'}
       local:
         valueFrom: ${return true}
       very-sensitive-local:
         valueFrom: ${return true}
       no-unal:
         valueFrom: ${return true}
       no-mixed:
         valueFrom: ${return true}
       no-discordant:
         valueFrom: ${return true}
       phred33:
         valueFrom: ${return true}
       I:
         valueFrom: ${return 10}
       X:
         valueFrom: ${return 700}
       no-overlap:
         valueFrom: ${return true}
       no-dovetail:
         valueFrom: ${return true}
       genome_ref_first_index_file: spike_in_genome_ref_first_index_file
       nthreads: nthreads
     out:
     - outfile
     - output_bowtie_log
   sam2bam_spike_in:
     run: ../map/samtools2bam.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: bowtie2_spike_in/outfile
     out:
     - bam_file
   sort_bams_spike_in:
     run: ../map/samtools-sort.cwl
     scatter:
     - input_file
     in:
       nthreads: nthreads
       input_file: sam2bam_spike_in/bam_file
     out:
     - sorted_file
   index_sorted_bams_spike_in:
     run: ../map/samtools-index.cwl
     scatter:
     - input_file
     in:
       input_file: sort_bams_spike_in/sorted_file
     out:
     - indexed_file
   spike_in_extract_fragments_bam2bed:
     run: ../map/bedtools-bamtobed.cwl
     scatter: bam
     in:
       bam: index_sorted_bams_spike_in/indexed_file
     out:
       - output_bedfile
   extract_fragments_bam2bed:
     run: ../map/bedtools-bamtobed.cwl
     scatter: bam
     in:
       bam: index_dedup_bams/indexed_file
     out:
       - output_bedfile
   mapped_reads_count:
     run: ../map/bowtie2-log-read-counts.cwl
     scatterMethod: dotproduct
     scatter:
      - bowtie2_log
      - output_filename
     in:
       bowtie2_log: bowtie2/output_bowtie_log
       output_filename:
        source: bowtie2/output_bowtie_log
        valueFrom: ${return self.basename.replace(/^.*[\\\/]/, '') + '.read_count.mapped'}
     out:
     - percent_map
   percent_uniq_reads:
     run: ../map/preseq-percent-uniq-reads.cwl
     scatter: preseq_c_curve_outfile
     in:
       preseq_c_curve_outfile: preseq-c-curve/output_file
     out:
     - output
   mapped_filtered_reads_count:
     run: ../peak_calling/samtools-extract-number-mapped-reads.cwl
     scatter: input_bam_file
     in:
       output_suffix:
         valueFrom: .mapped_and_filtered.read_count.txt
       input_bam_file: index_dedup_bams/indexed_file
     out:
     - output_read_count
outputs:
   output_pbc_files:
     doc: PCR Bottleneck Coeficient files.
     type: File[]
     outputSource: execute_pcr_bottleneck_coef/pbc_file
   output_read_count_mapped:
     doc: Read counts of the mapped BAM files
     type: File[]
     outputSource: mapped_reads_count/percent_map
   output_data_sorted_dedup_bam_files:
     doc: BAM files without duplicate reads, sorted and indexed.
     type: File[]
     outputSource: index_dedup_bams/indexed_file
   output_picard_mark_duplicates_files:
     doc: Picard MarkDuplicates metrics files.
     type: File[]
     outputSource: mark_duplicates/output_metrics_file
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
     outputSource: bowtie2/output_bowtie_log
   output_preseq_c_curve_files:
     doc: Preseq c_curve output files.
     type: File[]
     outputSource: preseq-c-curve/output_file
   output_extract_fragments_bam2bed:
     doc: Fragments in BED format
     type: File[]
     outputSource: extract_fragments_bam2bed/output_bedfile
   output_bams_spike_in:
     doc: BAM files for the spike-in, sorted and indexed.
     type: File[]
     outputSource: index_sorted_bams_spike_in/indexed_file
   output_spike_in_bowtie_log:
     doc: Bowtie2 log for spike-in
     type: File[]
     outputSource: bowtie2_spike_in/output_bowtie_log
   output_extract_fragments_bam2bed_spike_in:
     doc: Spike-in fragments in BED format
     type: File[]
     outputSource: spike_in_extract_fragments_bam2bed/output_bedfile