 class: Workflow
 cwlVersion: v1.0
 doc: RNA-seq 04 quantification
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: SubworkflowFeatureRequirement
 inputs:
    input_genome_sizes:
      type: File
    bamtools_reverse_filter_file:
      doc: JSON filter file for reverse strand used in bamtools (see bamtools-filter command)
      type: File
    rsem_reference_files:
      doc: RSEM genome reference files - generated with the rsem-prepare-reference command
      type: File[]
    input_bam_files:
      type: File[]
    annotation_file:
      doc: GTF annotation file
      type: File
    bamtools_forward_filter_file:
      doc: JSON filter file for forward strand used in bamtools (see bamtools-filter command)
      type: File
    input_transcripts_bam_files:
      type: File[]
    nthreads:
      default: 1
      type: int
 steps:
    bw2bdg-minus:
      run: ../quant/bigWigToBedGraph.cwl
      in:
        bigwig_file: bamcoverage-minus/output_bam_coverage
      scatter: bigwig_file
      out:
      - output_bedgraph
    split_bams:
      in:
        bamtools_reverse_filter_file: bamtools_reverse_filter_file
        bamtools_forward_filter_file: bamtools_forward_filter_file
        input_bam_files: input_bam_files
        input_basenames: basename/basename
      run: ../quant/split-bams-by-strand-and-index.cwl
      out:
      - bam_plus_files
      - bam_minus_files
      - index_bam_plus_files
      - index_bam_minus_files
    featurecounts:
      run: ../quant/subread-featurecounts.cwl
      in:
        B:
          valueFrom: $(true)
        g:
          valueFrom: gene_id
        output_filename:
          source: basename/basename
          valueFrom: $(self + ".featurecounts.counts.txt")
        p:
          valueFrom: $(true)
        s:
          valueFrom: $(2)
        t:
          valueFrom: exon
        annotation_file: annotation_file
        T: nthreads
        input_files:
          source: input_bam_files
          valueFrom: ${if (Array.isArray(self)) return self; return [self]; }
      scatterMethod: dotproduct
      scatter:
      - input_files
      - output_filename
      out:
      - output_files
    bdg2bw-raw-plus:
      run: ../quant/bedGraphToBigWig.cwl
      in:
        output_suffix:
          valueFrom: .raw.bw
        genome_sizes: input_genome_sizes
        bed_graph: bedsort_genomecov_plus/bed_file_sorted
      scatter: bed_graph
      out:
      - output_bigwig
    bedsort_genomecov_plus:
      run: ../quant/bedSort.cwl
      in:
        bed_file: bedtools_genomecov_plus/output_bedfile
      scatter: bed_file
      out:
      - bed_file_sorted
    negate_minus_bdg:
      run: ../quant/negate-minus-strand-bedgraph.cwl
      in:
        bedgraph_file: bedsort_genomecov_minus/bed_file_sorted
        output_filename:
          source: basename/basename
          valueFrom: $(self + ".Aligned.minus.raw.bdg")
      scatterMethod: dotproduct
      scatter:
      - bedgraph_file
      - output_filename
      out:
      - negated_minus_bdg
    basename:
      run: ../utils/basename.cwl
      in:
        file_path:
          source: input_bam_files
          valueFrom: $(self.path)
        sep:
          valueFrom: \.Aligned\.out\.sorted
      scatter: file_path
      out:
      - basename
    bamcoverage-minus:
      run: ../quant/deeptools-bamcoverage.cwl
      in:
        binSize:
          valueFrom: $(1)
        numberOfProcessors: nthreads
        bam: split_bams/bam_minus_files
        output_suffix:
          valueFrom: .norm-minus-pre-negated-bw
        normalizeUsingRPKM:
          valueFrom: $(true)
      scatter: bam
      out:
      - output_bam_coverage
    negate_minus_bdg_norm:
      run: ../quant/negate-minus-strand-bedgraph.cwl
      in:
        bedgraph_file: bw2bdg-minus/output_bedgraph
        output_filename:
          source: basename/basename
          valueFrom: $(self + ".norm-minus-bdg")
      scatterMethod: dotproduct
      scatter:
      - bedgraph_file
      - output_filename
      out:
      - negated_minus_bdg
    bedsort_genomecov_minus:
      run: ../quant/bedSort.cwl
      in:
        bed_file: bedtools_genomecov_minus/output_bedfile
      scatter: bed_file
      out:
      - bed_file_sorted
    bdg2bw-raw-minus:
      run: ../quant/bedGraphToBigWig.cwl
      in:
        output_suffix:
          valueFrom: .bw
        genome_sizes: input_genome_sizes
        bed_graph: negate_minus_bdg/negated_minus_bdg
      scatter: bed_graph
      out:
      - output_bigwig
    bedtools_genomecov_plus:
      run: ../map/bedtools-genomecov.cwl
      in:
        bg:
          valueFrom: $(true)
        g: input_genome_sizes
        ibam: split_bams/bam_plus_files
      scatter: ibam
      out:
      - output_bedfile
    bamcoverage-plus:
      run: ../quant/deeptools-bamcoverage.cwl
      in:
        binSize:
          valueFrom: $(1)
        numberOfProcessors: nthreads
        bam: split_bams/bam_plus_files
        output_suffix:
          valueFrom: .norm.bw
        normalizeUsingRPKM:
          valueFrom: $(true)
      scatter: bam
      out:
      - output_bam_coverage
    rsem-calc-expr:
      run: ../quant/rsem-calculate-expression.cwl
      in:
        paired-end:
          valueFrom: $(true)
        reference_name:
          source: rsem_reference_files
          valueFrom: "${\n  var trans_file_str = self.map(function(e){return e.path}).filter(function(e){return e.match(/\\.transcripts\\.fa$/)})[0];\n  return trans_file_str.match(/.*[\\\\\\/](.*)\\.transcripts\\.fa$/)[1];\n}"
        reference_files: rsem_reference_files
        no-bam-output:
          valueFrom: $(true)
        quiet:
          valueFrom: $(true)
        seed:
          valueFrom: $(1234)
        sample_name:
          source: basename/basename
          valueFrom: $(self + ".rsem")
        bam: input_transcripts_bam_files
        num-threads: nthreads
      scatterMethod: dotproduct
      scatter:
      - bam
      - sample_name
      out:
      - isoforms
      - genes
      - rsem_stat
    bdg2bw-norm-minus:
      run: ../quant/bedGraphToBigWig.cwl
      in:
        output_suffix:
          valueFrom: .Aligned.minus.norm.bw
        genome_sizes: input_genome_sizes
        bed_graph: negate_minus_bdg_norm/negated_minus_bdg
      scatter: bed_graph
      out:
      - output_bigwig
    bedtools_genomecov_minus:
      run: ../map/bedtools-genomecov.cwl
      in:
        bg:
          valueFrom: $(true)
        g: input_genome_sizes
        ibam: split_bams/bam_minus_files
      scatter: ibam
      out:
      - output_bedfile
 outputs:
    bw_raw_plus_files:
      doc: Raw bigWig files from BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: bdg2bw-raw-plus/output_bigwig
    rsem_genes_files:
      doc: RSEM genes files
      type: File[]
      outputSource: rsem-calc-expr/genes
    bw_norm_minus_files:
      doc: Normalized by RPKM bigWig files from BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: bdg2bw-norm-minus/output_bigwig
    bam_minus_files:
      doc: BAM files containing only reads in the reverse (minus) strand.
      type: File[]
      outputSource: split_bams/bam_minus_files
    rsem_isoforms_files:
      doc: RSEM isoforms files
      type: File[]
      outputSource: rsem-calc-expr/isoforms
    featurecounts_counts:
      doc: Normalized fragment extended reads bigWig (signal) files
      type: File[]
      outputSource: featurecounts/output_files
    bw_norm_plus_files:
      doc: Normalized by RPKM bigWig files from BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: bamcoverage-plus/output_bam_coverage
    index_bam_plus_files:
      doc: Index files for BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: split_bams/index_bam_plus_files
    bam_plus_files:
      doc: BAM files containing only reads in the forward (plus) strand.
      type: File[]
      outputSource: split_bams/bam_plus_files
    bw_raw_minus_files:
      doc: Raw bigWig files from BAM files containing only reads in the reverse (minus) strand.
      type: File[]
      outputSource: bdg2bw-raw-minus/output_bigwig
    index_bam_minus_files:
      doc: Index files for BAM files containing only reads in the reverse (minus) strand.
      type: File[]
      outputSource: split_bams/index_bam_minus_files
