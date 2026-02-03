{ callPackage, runCommand

, htmlnano ? callPackage ./htmlnano.nix {}
}:

{ name
, minify ? false
}:

let
  inputFile = ../public/index.html;
  outputFile = "$out/index.html";
  buildHtmlScript =
    if minify then
      "htmlnano ${inputFile} -o ${outputFile}"
    else
      "cp ${inputFile} ${outputFile}";
in
runCommand "${name}-html" { nativeBuildInputs = [ htmlnano ]; } ''
  mkdir "$out"
  ${buildHtmlScript}
''
