{ callPackage, runCommand

, htmlnano ? callPackage ./htmlnano.nix {}
}:

{ minify ? false }:

let
  name = "app-html";
  inputFile = ../public/index.html;
  outputFile = "$out/index.html";
  buildHtmlScript =
    if minify then
      "htmlnano ${inputFile} -o ${outputFile}"
    else
      "cp ${inputFile} ${outputFile}";
in
runCommand name { nativeBuildInputs = [ htmlnano ]; } ''
  mkdir "$out"
  ${buildHtmlScript}
''
