{ callPackage, runCommand

, htmlnano ? callPackage ./htmlnano {}
}:

{ name ? "elm-todos-html"
, src ? ../.
, inputDir ? "public"
, minify ? false
}:

let
  inputFile = "${src}/${inputDir}/index.html";
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
