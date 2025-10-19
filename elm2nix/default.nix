{ elmPackages
, lib
, nodePackages
, stdenv

, settings ? {}
}:
let
  defaults = {
    name = "elm-app-0.1.0";
    src = ../.;
    srcs = ./elm-srcs.nix;
    srcdir = "./src";
    targets = ["Main"];
    registryDat = ./registry.dat;
    outputJavaScript = true;
  };
  cfg = defaults // settings;
in
stdenv.mkDerivation {
  inherit (cfg) name src;

  buildInputs = [ elmPackages.elm ]
    ++ lib.optional cfg.outputJavaScript nodePackages.uglify-js;

  buildPhase = elmPackages.fetchElmDeps {
    elmPackages = import cfg.srcs;
    elmVersion = "0.19.1";
    inherit (cfg) registryDat;
  };

  installPhase = let
    elmfile = module: "${cfg.srcdir}/${builtins.replaceStrings ["."] ["/"] module}.elm";
    extension = if cfg.outputJavaScript then "js" else "html";
  in ''
    mkdir -p $out/share/doc
    ${lib.concatStrings (map (module: ''
      echo "compiling ${elmfile module}"
      elm make ${elmfile module} --output $out/${module}.${extension} --docs $out/share/doc/${module}.json
      ${lib.optionalString cfg.outputJavaScript ''
        echo "minifying ${elmfile module}"
        uglifyjs $out/${module}.${extension} --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
            | uglifyjs --mangle --output $out/${module}.min.${extension}
      ''}
    '') cfg.targets)}
  '';
}
