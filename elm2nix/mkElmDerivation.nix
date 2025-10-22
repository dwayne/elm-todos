{ lib, pkgs }:
{ name
, src
, elmLock
, registryDat

, elmFiles ? ["Main.elm"]
, output ? "elm.js"
, docs ? false
, debug ? false
, optimize ? false
, minify ? false
, compress ? false

, build ? pkgs.callPackage ./build.nix {}
, dotElm ? pkgs.callPackage ./dotElm.nix {}
, fetchElmPackage ? pkgs.callPackage ./fetchElmPackage.nix {}
}:
let
  elmDependencies =
    lib.mapAttrs
      (name: value:
        { drv = fetchElmPackage {
            inherit name;
            version = value.version;
            hash = builtins.convertHash {
              hash = value.sha256;
              hashAlgo = "sha256";
              toHashFormat = "sri";
            };
          };
        } // value
      )
      elmLock;

  cache = dotElm { inherit elmDependencies registryDat; };
in
build {
  inherit
    name
    src
    cache
    elmFiles
    output
    docs
    debug
    optimize
    minify
    compress;
}
