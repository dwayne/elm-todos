{ brotli, callPackage, lib, runCommand, zopfli

, buildElmApplication
}:

let
  root = ../.;
  redirects = ../public/_redirects;

  fs = lib.fileset;
  startFileset = fs.unions [ redirects ../src ../elm.json ../elm.lock ];
in
{ src ? fs.toSource { inherit root; fileset = startFileset; }
, enableCompression ? false
, includeRedirects ? false
, htmlOptions ? {}
, cssOptions ? {}
, elmOptions ? { enableDebugger = true; }
}:

let
  html = callPackage ./build-html.nix {} htmlOptions;
  css = callPackage ./build-css.nix {} cssOptions;

  js = buildElmApplication ({
    name = "elm-todos-js";
    src = fs.toSource {
      inherit root;
      fileset = fs.difference startFileset redirects;
    };
    elmLock = ../elm.lock;
    output = "app.js";
  } // elmOptions);
in
runCommand "elm-todos" { nativeBuildInputs = [ brotli zopfli ]; } ''
  mkdir "$out"

  cp ${html}/index.html "$out"
  cp ${css}/index.css "$out"
  cp ${js}/app.js "$out"

  ${lib.optionalString enableCompression ''
    cd "$out" && find . \( -name '*.html' -o -name '*.css' -o -name '*.js' \) -exec brotli "{}" \; -exec zopfli "{}" \;
  ''}

  ${lib.optionalString includeRedirects ''
    cp ${src}/public/_redirects "$out"
  ''}
''
