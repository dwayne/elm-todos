{ callPackage, runCommand

, htmlnano ? callPackage ./htmlnano {}
}:

{ minify ? false }:

let
  name = "elm-todos-html";
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
