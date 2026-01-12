{ lightningcss, stdenv }:

{ src ? ../.
, inputFile ? "public/index.css"
, minify ? false
}:

stdenv.mkDerivation {
  inherit src;

  name = "build-css";

  nativeBuildInputs = [
    lightningcss
  ];

  installPhase =
    let
      buildCssScript =
        if minify then
          ''
          lightningcss --minify "${inputFile}" --output-file "$out/index.css"
          ''
        else
          ''
          cp "${inputFile}" "$out"
          ''
          ;
    in
    ''
    runHook preInstall

    mkdir "$out"
    ${buildCssScript}

    runHook postInstall
    '';
}
