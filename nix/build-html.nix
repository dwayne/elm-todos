{ html-minifier, stdenv }:

{ enableOptimizations ? false
}:

stdenv.mkDerivation {
  name = "elm-todos-html";
  src = ../.;

  nativeBuildInputs = [
    html-minifier
  ];

  installPhase =
    let
      buildHtmlScript =
        if enableOptimizations then
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
            --input-dir "public"                \
            --output-dir "$out"
          ''
        else
          ''
          cp "public/index.html" "$out"
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
