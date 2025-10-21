#
# N.B. I can bring everything together into mkElmDerivation.
#
# What about elm-optimize-level-2?
# What about minification?
#
# What about using multiple outputs: out, doc
#
# Make use of install where appropriate
#

{ elmPackages
, lib
, stdenv
}:
{ name
, src
, dotElm

, elmFiles ? ["Main.elm"]
, output ? "app.js"
, debug ? false
, optimize ? false
}:
stdenv.mkDerivation {
  inherit name src;

  nativeBuildInputs = [
    elmPackages.elm
  ];

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
  '';

  installPhase = ''
    cp -R .build "$out"
  '';
}
