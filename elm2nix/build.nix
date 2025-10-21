#
# N.B. I can bring everything together into mkElmDerivation.
#
# What about elm-optimize-level-2?
# What about terser instead of uglify-js?
# What about compression?
#
# What about using multiple outputs: out, doc
#
# Make use of install where appropriate
#

{ elmPackages
, lib
, stdenv
, uglify-js
}:
{ name
, src
, dotElm

, elmFiles ? ["Main.elm"]
, output ? "elm.js"
, debug ? false
, optimize ? false
, minify ? false
}:
let
  outputMin = "${lib.removeSuffix ".js" output}.min.js";
in
stdenv.mkDerivation {
  inherit name src;

  nativeBuildInputs = [
    elmPackages.elm
  ]
  ++ lib.optional minify uglify-js;

  buildPhase = ''
    ${dotElm.prepareScript}

    mkdir -p .build/share/doc

    elm make \
      ${builtins.concatStringsSep " " (builtins.map (f: "src/" + f) elmFiles)} \
      ${lib.optionalString debug "--debug"} \
      ${lib.optionalString optimize "--optimize"} \
      --output ".build/${output}" \
      --docs .build/share/doc/index.json

    if [ ! -f .build/share/doc/index.json ]; then
      rm -r .build/share
    fi

    ${lib.optionalString minify ''
      uglifyjs ".build/${output}" \
        --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
        | uglifyjs --mangle --output ".build/${outputMin}"
    ''}
  '';

  installPhase = ''
    cp -R .build "$out"
  '';
}
