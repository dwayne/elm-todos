{ elmPackages
, fetchzip
, lib
, runCommand
, stdenv

, elmVersion ? "0.19.1"
}:
let
  mkElmDerivation = { elmLock, registryDat, ... } @ args:
    stdenv.mkDerivation (args // {
      nativeBuildInputs = builtins.concatLists
        [ [ elmPackages.elm ]
          (args.nativeBuildInputs or [])
        ];
      preConfigure = preConfigure { inherit elmLock registryDat; } + (args.preConfigure or "");
    });

  preConfigure = args: ''
    cp -LR "${dotElmLinks args}" .elm
    chmod -R +w .elm
    export ELM_HOME=.elm
  '';

  dotElmLinks = { elmLock, registryDat }:
    runCommand "dot-elm-links" {} ''
      root="$out/${elmVersion}/packages"
      mkdir -p "$root"

      ln -s "${registryDat}" "$root/registry.dat"

      ${symbolicLinksToPackages elmLock}
    '';

  symbolicLinksToPackages = elmLock:
    builtins.foldl'
      (script: { author, package, version, sha256 } @ dep:
        script + ''
          mkdir -p "$root/${author}/${package}"
          ln -s "${fetchElmPackage dep}" "$root/${author}/${package}/${version}"
        ''
      )
      ""
      (lib.importJSON elmLock);

  fetchElmPackage = { author, package, version, sha256 }:
    fetchzip {
      name = "${author}-${package}-${version}";
      url = "https://github.com/${author}/${package}/archive/${version}.tar.gz";
      meta.homepage = "https://github.com/${author}/${package}";
      hash = builtins.convertHash {
        hash = sha256;
        hashAlgo = "sha256";
        toHashFormat = "sri";
      };
    };
in
{ inherit mkElmDerivation preConfigure dotElmLinks symbolicLinksToPackages fetchElmPackage; }
