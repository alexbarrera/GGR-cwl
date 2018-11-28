 class: ExpressionTool
 cwlVersion: v1.0
 requirements:
    InlineJavascriptRequirement: {}
 inputs:
    bowtie2_log:
      type: File
      doc: Bowtie2 log file
      inputBinding:
        loadContents: true
    output_filename:
      type: string?
      doc: Save the number of  mapped and total reads in a file of the given name
 expression: |
    ${
      var regExpPaired = new RegExp("(\\d+) \(.*\) were paired; of these:");
      var total = inputs.bowtie2_log.contents.match(regExpPaired)[1];

      var regExpExact1 = new RegExp("(\\d+) \(.*\) aligned concordantly exactly 1 time");
      var exact1 = inputs.bowtie2_log.contents.match(regExpExact1)[1];

      var regExpMore1 = new RegExp("(\\d+) \(.*\) aligned concordantly >1 times");
      var more1 = inputs.bowtie2_log.contents.match(regExpMore1)[1];


      var output = total + "\t" + (parseInt(exact1) + parseInt(more1)) + "\n";

      if (inputs.output_filename){
        return {
          percent_map : {
            "class": "File",
            "basename" : inputs.output_filename,
            "contents" : output,
          }
        }
      }
      return output;
    }
 outputs:
    percent_map:
      type:
      - File
      - string
