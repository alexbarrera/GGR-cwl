 class: Workflow
 cwlVersion: v1.0
 doc: ChIP-seq - Quantification
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    input_bam_files:
      type: File[]
    input_genome_sizes:
      type: File
    nthreads:
      default: 1
      type: int
 steps:
    bedsort_genomecov:
      run: ../quant/bedSort.cwl
      in:
        bed_file: bedtools_genomecov/output_bedfile
      scatter: bed_file
      out:
      - bed_file_sorted
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
        ibam: input_bam_files
      scatter: ibam
      out:
      - output_bedfile
    bamCoverage-rpkm:
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
          valueFrom: ${return 1}
        bam: input_bam_files
        output_suffix:
          valueFrom: .rpkm.bw
      scatter: bam
      out:
      - output_bam_coverage
 outputs:
    bigwig_rpkm_extended_files:
      doc: Fragment extended RPKM bigWig (signal) files
      type: File[]
      outputSource: bamCoverage-rpkm/output_bam_coverage
    bigwig_raw_files:
      doc: Raw reads bigWig (signal) files
      type: File[]
      outputSource: bdg2bw-raw/output_bigwig
