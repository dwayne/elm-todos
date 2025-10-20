{ lib
, runCommand

, elmDependencies
, registryDat

, elmVersion ? "0.19.1"
}:
let
  symbolicLinks =
    lib.foldlAttrs
      (acc: name: value:
        acc + ''
          mkdir -p "$root/${name}"
          ln -s "${value.drv}" "$root/${name}/${value.version}"
        ''
      )
      ""
      elmDependencies;
in
runCommand "dotElm" {} ''
  root="$out/${elmVersion}/packages"
  mkdir -p "$root"

  ln -s "${registryDat}" "$root/registry.dat"

  ${symbolicLinks}
''
