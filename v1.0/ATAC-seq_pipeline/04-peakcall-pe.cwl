 class: Workflow
 cwlVersion: v1.0
 doc: 'ATAC-seq 04 quantification, samples: .'
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
    as_narrowPeak_file:
      doc: Definition narrowPeak file in AutoSql format (used in bedToBigBed)
      type: File
    input_genome_sizes:
      doc: Two column tab-delimited file with chromosome size information
      type: File
 steps:
    unpair_bedpe:
      run: ../peak_calling/bedpe-to-bed.cwl
      in:
        bedpe: bedtools_bamtobed/output_bedfile
      scatter: bedpe
      out:
      - bed
    trunk-peak-score:
      run: ../utils/trunk-peak-score.cwl
      in:
        peaks: peak-calling/output_peak_file
      scatter: peaks
      out:
      - trunked_scores_peaks
    peaks-bed-to-bigbed-unpaired:
      run: ../quant/bedToBigBed.cwl
      in:
        type:
          valueFrom: bed6+4
        as: as_narrowPeak_file
        genome_sizes: input_genome_sizes
        bed: trunk-peak-score-unpaired/trunked_scores_peaks
      scatter: bed
      out:
      - bigbed
    sort-bam-by-name:
      run: ../map/samtools-sort.cwl
      in:
        n:
          valueFrom: $(true)
        nthreads: nthreads
        input_file: input_bam_files
      scatter:
      - input_file
      out:
      - sorted_file
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
        as: as_narrowPeak_file
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
    filter-reads-in-peaks-unpaired:
      run: ../peak_calling/samtools-filter-in-bedfile.cwl
      in:
        input_bam_file: input_bam_files
        input_bedfile: peak-calling-unpaired/output_peak_file
      scatterMethod: dotproduct
      scatter:
      - input_bam_file
      - input_bedfile
      out:
      - filtered_file
    trunk-peak-score-unpaired:
      run: ../utils/trunk-peak-score.cwl
      in:
        peaks: peak-calling-unpaired/output_peak_file
      scatter: peaks
      out:
      - trunked_scores_peaks
    bedtools_bamtobed:
      run: ../map/bedtools-bamtobed.cwl
      in:
        bam: sort-bam-by-name/sorted_file
        bedpe:
          valueFrom: $(true)
      scatter: bam
      out:
      - output_bedfile
    count-peaks-unpaired:
      run: ../utils/count-with-output-suffix.cwl
      in:
        output_suffix:
          valueFrom: .peak_count.within_replicate.txt
        input_file: peak-calling-unpaired/output_peak_file
      scatter: input_file
      out:
      - output_counts
    count-reads-filtered-unpaired:
      run: ../peak_calling/count-reads-after-filtering.cwl
      in:
        peak_xls_file: peak-calling-unpaired/output_peak_xls_file
      scatter: peak_xls_file
      out:
      - read_count_file
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
    peak-calling-unpaired:
      run: ../peak_calling/macs2-callpeak.cwl
      in:
        extsize:
          valueFrom: $(200)
        bdg:
          valueFrom: $(true)
        nomodel:
          valueFrom: $(true)
        g: genome_effective_size
        format:
          valueFrom: BED
        shift:
          valueFrom: $(-100)
        q:
          valueFrom: $(0.1)
        treatment:
          source: unpair_bedpe/bed
          valueFrom: $([self])
      scatterMethod: dotproduct
      scatter:
      - treatment
      out:
      - output_peak_file
      - output_peak_summits_file
      - output_ext_frag_bdg_file
      - output_peak_xls_file
    peak-calling:
      run: ../peak_calling/macs2-callpeak.cwl
      in:
        q:
          valueFrom: $(0.1)
        bdg:
          valueFrom: $(true)
        treatment:
          source: input_bam_files
          valueFrom: $([self])
        g: genome_effective_size
        format: input_bam_format
      scatterMethod: dotproduct
      scatter:
      - treatment
      out:
      - output_peak_file
      - output_peak_summits_file
      - output_ext_frag_bdg_file
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
    output_unpaired_peak_xls_file:
      doc: Peak calling report file (*_peaks.xls file produced by MACS2) using each paired mate independently
      type: File[]
      outputSource: peak-calling-unpaired/output_peak_xls_file
    output_peak_summits_file:
      doc: File containing peak summits
      type: File[]
      outputSource: peak-calling/output_peak_summits_file
    output_peak_file:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: peak-calling/output_peak_file
    output_peak_count_within_replicate:
      doc: Peak counts within replicate
      type: File[]
      outputSource: count-peaks/output_counts
    output_unpaired_filtered_read_count_file:
      doc: Filtered read count reported by MACS2 using each paired mate independently
      type: File[]
      outputSource: count-reads-filtered-unpaired/read_count_file
    output_unpaired_peak_count_within_replicate:
      doc: Peak counts within replicate using each paired mate independently
      type: File[]
      outputSource: count-peaks-unpaired/output_counts
    output_spp_cross_corr_plot:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: spp/output_spp_cross_corr_plot
    output_spp_x_cross_corr:
      doc: peakshift/phantomPeak results file
      type: File[]
      outputSource: spp/output_spp_cross_corr
    output_extended_peak_file:
      doc: peakshift/phantomPeak extended fragment results file
      type: File[]
      outputSource: peak-calling/output_ext_frag_bdg_file
    output_unpaired_peak_summits_file:
      doc: File containing peak summits using each paired mate independently
      type: File[]
      outputSource: peak-calling-unpaired/output_peak_summits_file
    output_unpaired_peak_bigbed_file:
      doc: Peaks in bigBed format using each paired mate independently
      type: File[]
      outputSource: peaks-bed-to-bigbed-unpaired/bigbed
    output_unpaired_extended_peak_file:
      doc: peakshift/phantomPeak extended fragment results file using each paired mate independently
      type: File[]
      outputSource: peak-calling-unpaired/output_ext_frag_bdg_file
    output_peak_xls_file:
      doc: Peak calling report file (*_peaks.xls file produced by MACS2)
      type: File[]
      outputSource: peak-calling/output_peak_xls_file
    output_unpaired_peak_file:
      doc: peakshift/phantomPeak results file using each paired mate independently
      type: File[]
      outputSource: peak-calling-unpaired/output_peak_file
    output_peak_bigbed_file:
      doc: Peaks in bigBed format
      type: File[]
      outputSource: peaks-bed-to-bigbed/bigbed
    output_read_in_peak_count_within_replicate:
      doc: Reads peak counts within replicate
      type: File[]
      outputSource: extract-count-reads-in-peaks/output_read_count
