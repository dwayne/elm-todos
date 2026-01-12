{ html-minifier, stdenv }:

{ src ? ../.
, inputDir ? "public"
, minify ? false
}:

stdenv.mkDerivation {
  inherit src;

  name = "build-html";

  nativeBuildInputs = [
    html-minifier
  ];

  installPhase =
    let
      buildHtmlScript =
        if minify then
          ''
          html-minifier                         \
            --collapse-boolean-attributes       \
            --collapse-inline-tag-whitespace    \
            --collapse-whitespace               \
            --decode-entities                   \
            --minify-js                         \
            --remove-comments                   \
            --remove-empty-attributes           \
            --remove-redundant-attributes       \
            --remove-script-type-attributes     \
            --remove-style-link-type-attributes \
            --remove-tag-whitespace             \
            --file-ext html                     \
            --input-dir ${inputDir}             \
            --output-dir "$out"
          ''
        else
          ''
          cp "${inputDir}"/*.html "$out"
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
