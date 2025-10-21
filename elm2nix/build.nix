#
# N.B. I can bring everything together into mkElmDerivation.
#

{ brotli
, elmPackages
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
, compress ? false
}:
let
  outputMin = "${lib.removeSuffix ".js" output}.min.js";
in
stdenv.mkDerivation {
  inherit name src;

  nativeBuildInputs = [
    elmPackages.elm
  ]
  ++ lib.optional minify uglify-js
  ++ lib.optional compress brotli;

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

    ${lib.optionalString compress ''
      gzip -9 -c ".build/${outputMin}" > ".build/${outputMin}.gz"
      brotli -Z -c ".build/${outputMin}" > ".build/${outputMin}.br"
    ''}
  '';

  installPhase = ''
    cp -R .build "$out"
  '';
}
