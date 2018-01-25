 class: CommandLineTool
 cwlVersion: v1.0
 requirements:
    InlineJavascriptRequirement: {}
 hints:
    DockerRequirement:
      dockerPull: dukegcb/samtools
 inputs:
    h:
      type: boolean
      default: true
      inputBinding:
        position: 1
        prefix: -h
      doc: Include header in output
    S:
      type: boolean
      default: true
      inputBinding:
        position: 1
        prefix: -S
      doc: Input format autodetected
    nthreads:
      type: int
      default: 1
      inputBinding:
        position: 1
        prefix: -@
      doc: Number of threads used
    input_file:
      type: File
      inputBinding:
        position: 2
      doc: File to be converted to BAM with samtools
 outputs:
    sam_file:
      type: File
      outputBinding:
        glob: $(inputs.input_file.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, '') + '.sam')
      doc: Aligned file in BAM format
 baseCommand: [samtools, view]
 stdout: $(inputs.input_file.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, '') + '.sam')
