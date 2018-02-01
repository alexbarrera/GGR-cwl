 class: Workflow
 cwlVersion: v1.0
 doc: Split reads in a BAM file by strands and index forward and reverse output BAM files
 requirements:
  - class: ScatterFeatureRequirement
 inputs:
    bamtools_reverse_filter_file:
      doc: JSON filter file for reverse strand used in bamtools (see bamtools-filter command)
      type: File
    bamtools_forward_filter_file:
      doc: JSON filter file for forward strand used in bamtools (see bamtools-filter command)
      type: File
    input_bam_files:
      type: File[]
    input_basenames:
      type: string[]
 steps:
    index_plus_bam:
      run: ../map/samtools-index.cwl
      in:
        input_file: split-bam-plus/output_file
      scatter: input_file
      out:
      - indexed_file
    index_minus_bam:
      run: ../map/samtools-index.cwl
      in:
        input_file: split-bam-minus/output_file
      scatter: input_file
      out:
      - indexed_file
    split-bam-plus:
      run: ../quant/bamtools-filter.cwl
      in:
        in:
          source: index_plus_bam/indexed_file
          valueFrom: ${return [self]}
        out:
          source: input_basenames
          valueFrom: $(self + ".Aligned.plus.bam")
        script: bamtools_forward_filter_file
      scatterMethod: dotproduct
      scatter:
      - in
      - out
      out:
      - output_file
    split-bam-minus:
      run: ../quant/bamtools-filter.cwl
      in:
        script: bamtools_reverse_filter_file
        out:
          source: input_basenames
          valueFrom: $(self + ".Aligned.minus.bam")
        in:
          source: index_minus_bam/indexed_file
          valueFrom: ${return [self]}
      scatterMethod: dotproduct
      scatter:
      - in
      - out
      out:
      - output_file
 outputs:
    bam_minus_files:
      doc: BAM files containing only reads in the reverse (minus) strand.
      type: File[]
      outputSource: split-bam-minus/output_file
    index_bam_plus_files:
      doc: Index files for BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: index_plus_bam/index_file
    bam_plus_files:
      doc: BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: split-bam-plus/output_file
    index_bam_minus_files:
      doc: Index files for BAM files containing only reads in the reverse (minus) strand.
      type: File[]
      outputSource: index_minus_bam/index_file
