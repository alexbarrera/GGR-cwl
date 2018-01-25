 class: Workflow
 cwlVersion: v1.0
 doc: 'RNA-seq 03 mapping - reads: PE'
 requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
 inputs:
    genome_sizes_file:
      doc: Genome sizes tab-delimited file
      type: File
    input_fastq_read2_files:
      doc: Input fastq paired-end read 2 files
      type: File[]
    nthreads:
      default: 1
      type: int
    genomeDirFiles:
      doc: STAR genome reference/indices files.
      type: File[]
    annotation_file:
      doc: GTF annotation file
      type: File
    genome_fasta_files:
      doc: STAR genome generate - Genome FASTA file with all the genome sequences in FASTA format
      type: File[]
    input_fastq_read1_files:
      doc: Input fastq paired-end read 1 files
      type: File[]
    sjdbOverhang:
      doc: 'Length of the genomic sequence around the annotated junction to be used in constructing the splice junctions database. Ideally, this length should be equal to the ReadLength-1, where ReadLength is the length of the reads. '
      type: string
 steps:
    transcriptome_star_pass2:
      run: ../workflows/tools/STAR.cwl
      in:
        alignSJoverhangMin:
          valueFrom: $(8)
        genomeDir: genomeDirFiles
        outFilterType:
          valueFrom: BySJout
        alignSJDBoverhangMin:
          valueFrom: $(1)
        outFilterIntronMotifs:
          valueFrom: RemoveNoncanonical
        outSAMattributes:
          valueFrom: NH HI AS NM MD
        outSAMunmapped:
          valueFrom: Within
        outFilterMultimapNmax:
          valueFrom: $(20)
        alignIntronMax:
          valueFrom: $(1000000)
        outFilterMismatchNoverReadLmax:
          valueFrom: $(0.04)
        outFilterMismatchNmax:
          valueFrom: $(999)
        alignIntronMin:
          valueFrom: $(20)
        runThreadN: nthreads
        alignMatesGapMax:
          valueFrom: $(1000000)
        sjdbScore:
          valueFrom: $(1)
        readFilesIn: zip_fastq_files/zipped_list
        outFileNamePrefix:
          source: basename/basename
          valueFrom: $(self + ".transcriptome.star2.")
        quantMode:
          valueFrom: TranscriptomeSAM
        sjdbOverhang:
          source: sjdbOverhang
          valueFrom: $(parseInt(self))
      scatterMethod: dotproduct
      scatter:
      - readFilesIn
      - outFileNamePrefix
      out:
      - transcriptomesam
      - mappingstats
    star_pass2:
      run: ../workflows/tools/STAR.cwl
      in:
        genomeDir: genomeDirFiles
        outFilterIntronMotifs:
          valueFrom: RemoveNoncanonical
        outSAMattributes:
          valueFrom: All
        outFilterMultimapNmax:
          valueFrom: $(1)
        outFileNamePrefix:
          source: basename/basename
          valueFrom: $(self + ".star2.")
        outSAMtype:
          valueFrom: $(['BAM', 'Unsorted'])
        runThreadN: nthreads
        readFilesIn: zip_fastq_files/zipped_list
        quantMode:
          valueFrom: GeneCounts
        sjdbOverhang:
          source: sjdbOverhang
          valueFrom: $(parseInt(self))
      scatterMethod: dotproduct
      scatter:
      - readFilesIn
      - outFileNamePrefix
      out:
      - aligned
      - mappingstats
      - readspergene
    transcriptome_mapped_reads_count_star2:
      run: ../map/star-log-read-count.cwl
      in:
        star_log:
          source: transcriptome_star_pass2/mappingstats
          valueFrom: $(self[0])
      scatter: star_log
      out:
      - output
    basename:
      run: ../utils/basename.cwl
      in:
        file_path:
          source: input_fastq_read1_files
          valueFrom: $(self.path)
        sep:
          valueFrom: '[\.|_]R1'
      scatter: file_path
      out:
      - basename
    sort_star_pass2_bam:
      run: ../map/samtools-sort.cwl
      in:
        nthreads: nthreads
        input_file: star_pass2/aligned
      scatter: input_file
      out:
      - sorted_file
    index_star_pass2_bam:
      run: ../map/samtools-index.cwl
      in:
        input_file: sort_star_pass2_bam/sorted_file
      scatter:
      - input_file
      out:
      - index_file
    preseq-c-curve:
      run: ../map/preseq-c_curve.cwl
      in:
        input_sorted_file: sort_star_pass2_bam/sorted_file
        output_file_basename: basename/basename
      scatterMethod: dotproduct
      scatter:
      - input_sorted_file
      - output_file_basename
      out:
      - output_file
    mapped_reads_count_star2:
      run: ../map/star-log-read-count.cwl
      in:
        star_log:
          source: star_pass2/mappingstats
          valueFrom: $(self[0])
      scatter: star_log
      out:
      - output
    percent_uniq_reads_star2:
      run: ../map/preseq-percent-uniq-reads.cwl
      in:
        preseq_c_curve_outfile: preseq-c-curve/output_file
      scatter: preseq_c_curve_outfile
      out:
      - output
    zip_fastq_files:
      in:
        reads2: input_fastq_read2_files
        reads1: input_fastq_read1_files
      run: ../utils/zip_arrays.cwl
      out:
      - zipped_list
    execute_pcr_bottleneck_coef:
      in:
        input_bam_files: sort_star_pass2_bam/sorted_file
        genome_sizes: genome_sizes_file
        input_output_filenames: basename/basename
      run: ../map/pcr-bottleneck-coef.cwl
      out:
      - pbc_file
 outputs:
    star2_readspergene_file:
      doc: STAR pass-2 reads per gene counts file.
      type: File[]?
      outputSource: star_pass2/readspergene
    pcr_bottleneck_coef_file:
      doc: PCR Bottleneck Coefficient
      type: File[]
      outputSource: execute_pcr_bottleneck_coef/pbc_file
    star_aligned_sorted_index_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: index_star_pass2_bam/index_file
    read_count_mapped_star2:
      doc: Read counts of the mapped BAM files after STAR pass2
      type: File[]
      outputSource: mapped_reads_count_star2/output
    star2_stat_files:
      doc: STAR pass-2 stat files.
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: star_pass2/mappingstats
    star_aligned_sorted_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: sort_star_pass2_bam/sorted_file
    transcriptome_star_stat_files:
      doc: STAR pass-2 aligned to transcriptome stat files.
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: transcriptome_star_pass2/mappingstats
    star_aligned_unsorted_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: star_pass2/aligned
    percentage_uniq_reads_star2:
      doc: Percentage of uniq reads from preseq c_curve output
      type: File[]
      outputSource: percent_uniq_reads_star2/output
    transcriptome_star_aligned_file:
      doc: STAR mapped unsorted file.
      type: File[]
      outputSource: transcriptome_star_pass2/transcriptomesam
    read_count_transcriptome_mapped_star2:
      doc: Read counts of the mapped to transcriptome BAM files with STAR pass2
      type: File[]
      outputSource: transcriptome_mapped_reads_count_star2/output
