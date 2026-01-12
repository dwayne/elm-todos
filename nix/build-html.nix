{ html-minifier, stdenv }:

{ name ? "elm-todos-html"
, src ? ../.
, inputDir ? "public"
, minify ? false
}:

stdenv.mkDerivation {
  inherit name src;

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
          cp ${inputDir}/index.html "$out"
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
