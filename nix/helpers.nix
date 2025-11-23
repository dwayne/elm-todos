{ elmPackages, fetchElmPackage, runCommand, stdenv }:
{ elmLock
, registryDat

, elmVersion ? "0.19.1"
}:
let
  mkElmDerivation = args:
    stdenv.mkDerivation (args // {
      nativeBuildInputs = builtins.concatLists
        [ [ elmPackages.elm ]
          (args.nativeBuildInputs or [])
        ];
      preConfigure = preConfigure + (args.preConfigure or "");
    });

  preConfigure = ''
    cp -LR "${dotElmLinks}" .elm
    chmod -R +w .elm
    export ELM_HOME=.elm
  '';

  dotElmLinks =
    runCommand "dot-elm-links" {} ''
      root="$out/${elmVersion}/packages"
      mkdir -p "$root"

      ln -s "${registryDat}" "$root/registry.dat"

      ${symbolicLinksToPackages}
    '';

  symbolicLinksToPackages =
    builtins.foldl'
      (script: { author, package, version, sha256 } @ dep:
        script + ''
          mkdir -p "$root/${author}/${package}"
          ln -s "${fetchElmPackage dep}" "$root/${author}/${package}/${version}"
        ''
      )
      ""
      elmLock;
in
{ inherit mkElmDerivation preConfigure dotElmLinks symbolicLinksToPackages; }
