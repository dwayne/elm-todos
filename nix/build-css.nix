{ lightningcss, stdenv }:

{ enableOptimizations ? false
}:

stdenv.mkDerivation {
  name = "elm-todos-css";
  src = ../.;

  nativeBuildInputs = [
    lightningcss
  ];

  installPhase =
    let
      buildCSSScript =
        if enableOptimizations then
          ''
          lightningcss --minify "public/index.css" --output-file "$out/index.css"
          ''
        else
          ''
          cp "public/index.css" "$out"
          ''
          ;
    in
    ''
    runHook preInstall

    mkdir "$out"
    ${buildCSSScript}

    runHook postInstall
    '';
}
