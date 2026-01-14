{ callPackage, stdenv

, htmlnano ? callPackage ./htmlnano {}
}:

{ name ? "elm-todos-html"
, src ? ../.
, inputDir ? "public"
, minify ? false
}:

stdenv.mkDerivation {
  inherit name src;

  nativeBuildInputs = [
    htmlnano
  ];

  installPhase =
    let
      buildHtmlScript =
        if minify then
          ''
          htmlnano ${inputDir}/index.html -o "$out/index.html"
          ''
        else
          ''
          cp ${inputDir}/index.html "$out/index.html"
          ''
          ;
    in
    ''
    runHook preInstall

    mkdir "$out"
    ${buildHtmlScript}

    runHook postInstall
    '';
}
