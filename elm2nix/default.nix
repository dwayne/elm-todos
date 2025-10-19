{ lib, pkgs }:
let
  mkDerivation =
    { name
    , src ? ../.
    , srcs ? ./elm-srcs.nix
    , srcdir ? "./src"
    , targets ? ["Main"]
    , registryDat ? ./registry.dat
    , outputJavaScript ? true
    }:
    pkgs.stdenv.mkDerivation {
      inherit name src;

      buildInputs = [ pkgs.elmPackages.elm ]
        ++ lib.optional outputJavaScript pkgs.nodePackages.uglify-js;

      buildPhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import srcs;
        elmVersion = "0.19.1";
        inherit registryDat;
      };

      installPhase = let
        elmfile = module: "${srcdir}/${builtins.replaceStrings ["."] ["/"] module}.elm";
        extension = if outputJavaScript then "js" else "html";
      in ''
        mkdir -p $out/share/doc
        ${lib.concatStrings (map (module: ''
          echo "compiling ${elmfile module}"
          elm make ${elmfile module} --output $out/${module}.${extension} --docs $out/share/doc/${module}.json
          ${lib.optionalString outputJavaScript ''
            echo "minifying ${elmfile module}"
            uglifyjs $out/${module}.${extension} --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
                | uglifyjs --mangle --output $out/${module}.min.${extension}
          ''}
        '') targets)}
      '';
    };
in
mkDerivation {
  name = "elm-todos";
}
