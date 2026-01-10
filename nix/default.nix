{ callPackage, runCommand

, buildElmApplication
, htmlOptions ? {}
, cssOptions ? {}
, elmOptions ? { enableDebugger = true; }
}:

let
  html = callPackage ./build-html.nix htmlOptions;
  css = callPackage ./build-css.nix cssOptions;
  js = buildElmApplication ({
    name = "elm-todos-js";
    src = ../.;
    elmLock = ../elm.lock;
    output = "app.js";
  } // elmOptions);
in
runCommand "elm-todos" {} ''
  mkdir "$out"
  cp ${html}/index.html "$out"
  cp ${css}/index.css "$out"
  cp ${js}/app.js "$out"
''
