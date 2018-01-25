 class: Workflow
 cwlVersion: v1.0
 doc: 'ChIP-seq 04 quantification - region: broad, samples: treatment.'
 requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
 inputs:
    genome_effective_size:
      default: hs
      doc: Effective genome size used by MACS2. It can be numeric or a shortcuts:'hs' for human (2.7e9), 'mm' for mouse (1.87e9), 'ce' for C. elegans (9e7) and 'dm' for fruitfly (1.2e8), Default:hs
      type: string
    nthreads:
      default: 1
      type: int
    input_bam_files:
      type: File[]
    input_bam_format:
      default: BAMPE
      doc: 'BAM or BAMPE for single-end and paired-end reads respectively (default: BAM)'
      type: string
    as_broadPeak_file:
      doc: Definition broadPeak file in AutoSql format (used in bedToBigBed)
      type: File
    input_genome_sizes:
      doc: Two column tab-delimited file with chromosome size information
      type: File
 steps:
    trunk-peak-score:
      run: ../utils/trunk-peak-score.cwl
      in:
        peaks: peak-calling/output_peak_file
      scatter: peaks
      out:
      - trunked_scores_peaks
    count-reads-filtered:
      run: ../peak_calling/count-reads-after-filtering.cwl
      in:
        peak_xls_file: peak-calling/output_peak_xls_file
      scatter: peak_xls_file
      out:
      - read_count_file
    spp:
      run: ../spp/spp.cwl
      in:
        input_bam: input_bam_files
        nthreads: nthreads
        savp:
          valueFrom: $(true)
      scatterMethod: dotproduct
      scatter:
      - input_bam
      out:
      - output_spp_cross_corr
      - output_spp_cross_corr_plot
    peaks-bed-to-bigbed:
      run: ../quant/bedToBigBed.cwl
      in:
        type:
          valueFrom: bed6+4
        as: as_broadPeak_file
        genome_sizes: input_genome_sizes
        bed: trunk-peak-score/trunked_scores_peaks
      scatter: bed
      out:
      - bigbed
    extract-peak-frag-length:
      run: ../spp/extract-best-frag-length.cwl
      in:
        input_spp_txt_file: spp/output_spp_cross_corr
      scatter: input_spp_txt_file
      out:
      - output_best_frag_length
    extract-count-reads-in-peaks:
      run: ../peak_calling/samtools-extract-number-mapped-reads.cwl
      in:
        output_suffix:
          valueFrom: .read_count.within_replicate.txt
        input_bam_file: filter-reads-in-peaks/filtered_file
      scatter: input_bam_file
      out:
      - output_read_count
    filter-reads-in-peaks:
      run: ../peak_calling/samtools-filter-in-bedfile.cwl
      in:
        input_bam_file: input_bam_files
        input_bedfile: peak-calling/output_peak_file
      scatterMethod: dotproduct
      scatter:
      - input_bam_file
      - input_bedfile
      out:
      - filtered_file
    peak-calling:
      run: ../peak_calling/macs2-callpeak.cwl
      in:
        extsize: extract-peak-frag-length/output_best_frag_length
        nomodel:
          valueFrom: $(true)
        g: genome_effective_size
        format: input_bam_format
        broad:
          valueFrom: $(true)
        q:
          valueFrom: $(0.1)
        treatment:
          source: input_bam_files
          valueFrom: $([self])
      scatterMethod: dotproduct
      scatter:
      - treatment
      - extsize
      out:
      - output_peak_file
      - output_peak_summits_file
      - output_peak_xls_file
    count-peaks:
      run: ../utils/count-with-output-suffix.cwl
      in:
        output_suffix:
          valueFrom: .peak_count.within_replicate.txt
        input_file: peak-calling/output_peak_file
      scatter: input_file
      out:
      - output_counts
 outputs:
    output_filtered_read_count_file:
      doc: Filtered read count reported by MACS2
      type: File[]
      outputSource: count-reads-filtered/read_count_file
    output_broadpeak_file:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: peak-calling/output_peak_file
    output_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: count-peaks/output_counts
    output_broadpeak_summits_file:
      doc: File containing peak summits
      type:
        items:
        - 'null'
        - items: File
          type: array
        type: array
      outputSource: peak-calling/output_peak_summits_file
    output_spp_cross_corr_plot:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: spp/output_spp_cross_corr_plot
    output_spp_x_cross_corr:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: spp/output_spp_cross_corr
    output_broadpeak_bigbed_file:
      doc: Peaks in bigBed format
      type: File[]
      outputSource: peaks-bed-to-bigbed/bigbed
    output_peak_xls_file:
      doc: Peak calling report file (*_peaks.xls file produced by MACS2)
      type: File[]
      outputSource: peak-calling/output_peak_xls_file
    output_read_in_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: extract-count-reads-in-peaks/output_read_count
