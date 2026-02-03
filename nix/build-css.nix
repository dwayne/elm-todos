{ lightningcss, runCommand }:

{ name
, minify ? false
}:

let
  inputFile = ../public/index.css;
  outputFile = "$out/index.css";
  buildCssScript =
    if minify then
      "lightningcss --minify ${inputFile} --output-file ${outputFile}"
    else
      "cp ${inputFile} ${outputFile}";
in
runCommand "${name}-css" { nativeBuildInputs = [ lightningcss ]; } ''
  mkdir "$out"
  ${buildCssScript}
''
