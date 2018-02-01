 class: Workflow
 cwlVersion: v1.0
 doc: RNA-seq 04 quantification
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: SubworkflowFeatureRequirement
 inputs:
    nthreads:
      default: 1
      type: int
    rsem_reference_files:
      doc: RSEM genome reference files - generated with the rsem-prepare-reference command
      type: File[]
    input_bam_files:
      type: File[]
    annotation_file:
      doc: GTF annotation file
      type: File
    input_transcripts_bam_files:
      type: File[]
    input_genome_sizes:
      type: File
 steps:
    featurecounts:
      run: ../quant/subread-featurecounts.cwl
      in:
        B:
          valueFrom: ${return true}
        g:
          valueFrom: gene_id
        output_filename:
          source: basename/basename
          valueFrom: $(self + ".featurecounts.counts.txt")
        p:
          valueFrom: ${return true}
        s:
          valueFrom: ${return 0}
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
    bedsort_genomecov:
      run: ../quant/bedSort.cwl
      in:
        bed_file: bedtools_genomecov/output_bedfile
      scatter: bed_file
      out:
      - bed_file_sorted
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
    bamcoverage:
      run: ../quant/deeptools-bamcoverage.cwl
      in:
        binSize:
          valueFrom: ${return 1}
        numberOfProcessors: nthreads
        bam: input_bam_files
        output_suffix:
          valueFrom: .norm.bw
        normalizeUsingRPKM:
          valueFrom: ${return true}
      scatter: bam
      out:
      - output_bam_coverage
    rsem-calc-expr:
      run: ../quant/rsem-calculate-expression.cwl
      in:
        reference_name:
          source: rsem_reference_files
          valueFrom: "${\n  var trans_file_str = self.map(function(e){return e.path}).filter(function(e){return e.match(/\\.transcripts\\.fa$/)})[0];\n  return trans_file_str.match(/.*[\\\\\\/](.*)\\.transcripts\\.fa$/)[1];\n}"
        reference_files: rsem_reference_files
        no-bam-output:
          valueFrom: ${return true}
        quiet:
          valueFrom: ${return true}
        seed:
          valueFrom: ${return 1234}
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
 outputs:
    featurecounts_counts:
      doc: Normalized fragment extended reads bigWig (signal) files
      type: File[]
      outputSource: featurecounts/output_files
    rsem_genes_files:
      doc: RSEM genes files
      type: File[]
      outputSource: rsem-calc-expr/genes
    rsem_isoforms_files:
      doc: RSEM isoforms files
      type: File[]
      outputSource: rsem-calc-expr/isoforms
    bw_raw_files:
      doc: Raw bigWig files.
      type: File[]
      outputSource: bdg2bw-raw/output_bigwig
    bw_norm_files:
      doc: Normalized by RPKM bigWig files.
      type: File[]
      outputSource: bamcoverage/output_bam_coverage
