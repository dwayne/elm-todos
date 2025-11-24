{ brotli
, elmPackages
, fetchzip
, lib
, runCommand
, stdenv
, uglify-js

, elmVersion ? "0.19.1"
}:
let
  mkElmDerivation =
    { elmLock # Path to elm.lock
    , registryDat # Path to registry.dat
    , entry ? "src/Main.elm" # :: String | [String]
    , output ? "elm.js" # :: String
    , enableDebugger ? false
    , enableOptimizations ? false
    , enableMinification ? false
    , minifier ? uglify-js
    , createMinificationScript ? createUglifyScript # :: { output, outputMin } -> String
    , enableCompression ? false
    , ...
    } @ args:

    assert !(enableDebugger && enableOptimizations)
      || throw "You cannot enable both the debugger and optimizations at the same time.";

    assert !(enableDebugger && enableMinification)
      || throw "You cannot enable both the debugger and minification at the same time.";

    assert !(enableDebugger && enableCompression)
      || throw "You cannot enable both the debugger and compression at the same time.";

    let
      outputMin = "${lib.removeSuffix ".js" output}.min.js";
      toCompress = if enableMinification then outputMin else output;
    in
    stdenv.mkDerivation (args // {
      nativeBuildInputs = builtins.concatLists
        [ ([ elmPackages.elm ]
          ++ lib.optional enableMinification minifier
          ++ lib.optional enableCompression brotli)
          (args.nativeBuildInputs or [])
        ];

      preConfigure = preConfigure { inherit elmLock registryDat; } + (args.preConfigure or "");

      buildPhase = ''
        runHook preBuild

        elm make \
          ${builtins.concatStringsSep " " (if builtins.isList entry then entry else [ entry ])} \
          ${lib.optionalString enableDebugger "--debug"} \
          ${lib.optionalString enableOptimizations "--optimize"} \
          --output "$out/${output}"

        ${lib.optionalString enableMinification (createMinificationScript { inherit output outputMin; })}

        ${lib.optionalString enableCompression ''
          gzip -9 -c "$out/${toCompress}" > "$out/${toCompress}.gz"
          brotli -Z -c "$out/${toCompress}" > "$out/${toCompress}.br"
        ''}

        runHook postBuild
      '';
    });

  createUglifyScript = { output, outputMin }: ''
    uglifyjs "$out/${output}" \
        --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
        | uglifyjs --mangle --output "$out/${outputMin}"
  '';

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
