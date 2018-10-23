class: CommandLineTool
cwlVersion: v1.0
doc: Add a column to BED file for the length.
requirements:
   InlineJavascriptRequirement: {}
   ShellCommandRequirement: {}
hints:
   DockerRequirement:
     dockerPull: reddylab/workflow-utils:ggr
inputs:
   bed: {type: File, inputBinding: {}}
outputs:
   output:
     type: File
     outputBinding:
       glob: $(inputs.bed.path.replace(/^.*[\\\/]/, '') + '.with_length.bed')
baseCommand: awk -v OFS='\t' '{len = $3 - $2; print $0, len }'
stdout: $(inputs.bed.path.replace(/^.*[\\\/]/, '') + '.with_length.bed')
