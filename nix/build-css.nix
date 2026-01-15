{ lightningcss, runCommand }:

{ minify ? false }:

let
  name = "app-css";
  inputFile = ../public/index.css;
  outputFile = "$out/index.css";
  buildCssScript =
    if minify then
      "lightningcss --minify ${inputFile} --output-file ${outputFile}"
    else
      "cp ${inputFile} ${outputFile}";
in
runCommand name { nativeBuildInputs = [ lightningcss ]; } ''
  mkdir "$out"
  ${buildCssScript}
''
