 class: Workflow
 cwlVersion: v1.0
 doc: ChIP-seq - Quantification
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    nthreads:
      default: 1
      type: int
    input_trt_bam_files:
      type: File[]
    input_ctrl_bam_files:
      type: File[]
    input_genome_sizes:
      type: File
 steps:
    bamCoverage-rpkm-trt:
      run: ../quant/deeptools-bamcoverage.cwl
      in:
        numberOfProcessors: nthreads
        outFileFormat:
          valueFrom: bigwig
        extendReads:
          valueFrom: ${return 200}
        normalizeUsingRPKM:
          valueFrom: ${return true}
        binSize:
          valueFrom: ${return 100000}
        bam: input_trt_bam_files
        output_suffix:
          valueFrom: .rpkm.bw
      scatter: bam
      out:
      - output_bam_coverage
    bamCompare-ctrl-subtracted-rpkm:
      run: ../quant/deeptools-bigwigcompare.cwl
      in:
        numberOfProcessors: nthreads
        ratio:
          valueFrom: subtract
        bigwig1: bamCoverage-rpkm-trt/output_bam_coverage
        bigwig2: bamCoverage-rpkm-ctrl/output_bam_coverage
        binSize:
          valueFrom: ${return 100000}
        outFileFormat:
          valueFrom: bigwig
        output_suffix:
          valueFrom: .ctrl_subtracted.bw
      scatterMethod: dotproduct
      scatter:
      - bigwig1
      - bigwig2
      out:
      - output
    bedsort_genomecov:
      run: ../quant/bedSort.cwl
      in:
        bed_file: bedtools_genomecov/output_bedfile
      scatter: bed_file
      out:
      - bed_file_sorted
    bamCoverage-rpkm-ctrl:
      run: ../quant/deeptools-bamcoverage.cwl
      in:
        numberOfProcessors: nthreads
        outFileFormat:
          valueFrom: bigwig
        extendReads:
          valueFrom: ${return 200}
        normalizeUsingRPKM:
          valueFrom: ${return true}
        binSize:
          valueFrom: ${return 100000}
        bam: input_ctrl_bam_files
        output_suffix:
          valueFrom: .rpkm.bw
      scatter: bam
      out:
      - output_bam_coverage
    bdg2bw-raw:
      run: ../quant/bedGraphToBigWig.cwl
      in:
        output_suffix:
          valueFrom: .raw.bw
        genome_sizes: input_genome_sizes
        bed_graph: bedsort_genomecov/bed_file_sorted
      scatter: bed_graph
      out:
      - output_bigwig
    bedtools_genomecov:
      run: ../map/bedtools-genomecov.cwl
      in:
        bg:
          valueFrom: ${return true}
        g: input_genome_sizes
        ibam: input_trt_bam_files
      scatter: ibam
      out:
      - output_bedfile
 outputs:
    bigwig_rpkm_extended_files:
      doc: Fragment extended RPKM bigWig (signal) files
      type: File[]
      outputSource: bamCoverage-rpkm-trt/output_bam_coverage
    bigwig_ctrl_subtracted_rpkm_extended_files:
      doc: Control subtracted fragment extended RPKM bigWig (signal) files
      type: File[]
      outputSource: bamCompare-ctrl-subtracted-rpkm/output
    bigwig_raw_files:
      doc: Raw reads bigWig (signal) files
      type: File[]
      outputSource: bdg2bw-raw/output_bigwig
    bigwig_ctrl_rpkm_extended_files:
      doc: Fragment extended RPKM bigWig (signal) control files
      type: File[]
      outputSource: bamCoverage-rpkm-ctrl/output_bam_coverage
