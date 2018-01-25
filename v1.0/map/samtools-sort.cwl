 class: CommandLineTool
 cwlVersion: v1.0
 requirements:
    InlineJavascriptRequirement: {}
 hints:
    DockerRequirement:
      dockerPull: dukegcb/samtools
 inputs:
    n:
      type: boolean
      default: false
      inputBinding:
        position: 1
        prefix: -n
      doc: Sort by read name
    nthreads:
      type: int
      default: 1
      inputBinding:
        position: 1
        prefix: -@
      doc: Number of threads used in sorting
    input_file:
      type: File
      inputBinding:
        position: 1000
      doc: Aligned file to be sorted with samtools
 outputs:
    sorted_file:
      type: File
      outputBinding:
        glob: $(inputs.input_file.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, '') + '.sorted.bam')
      doc: Sorted aligned file
 baseCommand: [samtools, sort]
 stdout: $(inputs.input_file.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, '') + '.sorted.bam')
