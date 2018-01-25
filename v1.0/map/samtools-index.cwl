 class: CommandLineTool
 cwlVersion: v1.0
 requirements:
    InlineJavascriptRequirement: {}
 hints:
    DockerRequirement:
      dockerPull: dukegcb/samtools
 inputs:
    input_file:
      type: File
      inputBinding:
        position: 1
      doc: Aligned file to be sorted with samtools
 outputs:
    index_file:
      type: File
      outputBinding:
        glob: $(inputs.input_file.path.split('/').slice(-1)[0] + '.bai')
      doc: Index aligned file
 baseCommand: [samtools, index]
 arguments:
  - valueFrom: $(inputs.input_file.path.split('/').slice(-1)[0] + '.bai')
    position: 2
