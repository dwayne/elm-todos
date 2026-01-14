{ callPackage, runCommand

, htmlnano ? callPackage ./htmlnano {}
}:

{ name ? "elm-todos-html"
, inputFile ? ../public/index.html
, minify ? false
}:

let
  outputFile = "$out/index.html";
  buildHtmlScript =
    if minify then
      ''
      htmlnano ${inputFile} -o ${outputFile}
      ''
    else
      ''
      cp ${inputFile} ${outputFile}
      ''
      ;
in
runCommand name { nativeBuildInputs = [ htmlnano ]; } ''
  mkdir "$out"
  ${buildHtmlScript}
''
