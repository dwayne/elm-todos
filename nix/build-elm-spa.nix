{ brotli
, lib
, lightningcss
, stdenvNoCC
, writeShellApplication
, zopfli

, buildElmApplication
, deploy
, htmlnano
, mkServe
}:

let
  # Arguments that configure the site. Every other argument is passed on to buildElmApplication.
  siteArgNames = [
    "name"
    "root"
    "paths"
    "elmPaths"
    "minifyHtml"
    "minifyCss"
    "enableCompression"
    "includeRedirects"
    "port"
    "deployBranch"
  ];

  # buildElmApplication arguments that buildElmSpa sets itself.
  reservedElmArgNames = [
    "src"
    "output"
    "outputMin"
    "doCompression"
    "doContentHashing"
  ];

  # Everything buildElmApplication declares, e.g. enableOptimizations, doMinification,
  # elmPackagePatches, doElmTest, entry.
  knownElmArgNames = lib.attrNames (lib.functionArgs buildElmApplication);
in
lib.makeOverridable (
  { name ? "elm-spa"
  , root
  , paths ? [ (root + "/public") ]
  , elmPaths ? [ (root + "/src") (root + "/elm.json") ]
  , elmLock ? root + "/elm.lock"
  , minifyHtml ? false
  , minifyCss ? false
  , enableCompression ? false
  , includeRedirects ? false
  , port ? 8000
  , deployBranch ? "gh-pages"
  , ...
  } @ args:

  let
    elmArgs = removeAttrs args siteArgNames;
    elmArgNames = lib.attrNames elmArgs;
    reserved = lib.intersectLists reservedElmArgNames elmArgNames;
    unknown = lib.subtractLists knownElmArgNames elmArgNames;
  in

  assert reserved == []
    || throw "buildElmSpa sets these itself: ${lib.concatStringsSep ", " reserved}";

  assert unknown == []
    || throw "buildElmSpa: unknown argument(s): ${lib.concatStringsSep ", " unknown}";

  assert !(enableCompression && (elmArgs.enableDebugger or false))
    || throw "buildElmSpa: you cannot enable both debugging and compression.";

  let
    buildDir = ".build";

    indexHtml = "public/index.html";
    outputHtml = "${buildDir}/index.html";
    buildHtmlScript =
      if minifyHtml then
        ''
        htmlnano "${indexHtml}" -o "${outputHtml}"
        ''
      else
        ''
        cp "${indexHtml}" "${outputHtml}"
        '';

    indexCss = "public/index.css";
    outputCss = "${buildDir}/index.css";
    buildCssScript =
      if minifyCss then
        ''
        lightningcss --minify "${indexCss}" --output-file "${outputCss}"
        ''
      else
        ''
        cp "${indexCss}" "${outputCss}"
        '';

    fs = lib.fileset;
    elmApp = buildElmApplication (elmArgs // {
      inherit elmLock;

      name = "${name}-js";
      src = fs.toSource {
        inherit root;
        fileset = fs.unions elmPaths;
      };

      output = "app.js";
      outputMin = "app.min.js";
      doCompression = false; # the site compresses all of its assets in one place
      doContentHashing = false; # hashing would have to rewrite index.html
    });

    jsFile = if elmArgs.doMinification or false then "app.min.js" else "app.js";
  in
  stdenvNoCC.mkDerivation (finalAttrs: {
    inherit name;

    src = fs.toSource {
      inherit root;
      fileset = fs.unions paths;
    };

    nativeBuildInputs =
      lib.optional minifyHtml htmlnano
      ++ lib.optional minifyCss lightningcss
      ++ lib.optionals enableCompression [ brotli zopfli ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      mkdir -p "${buildDir}"

      ${buildHtmlScript}

      ${buildCssScript}

      install -m644 "${elmApp}/${jsFile}" "${buildDir}/app.js"

      ${lib.optionalString includeRedirects ''
        cp "public/_redirects" "${buildDir}"
      ''}

      ${lib.optionalString enableCompression ''
        find "${buildDir}" -type f \( -name '*.html' -o -name '*.css' -o -name '*.js' \) \
          -exec brotli {} + \
          -exec zopfli {} +
      ''}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r "${buildDir}" "$out"

      runHook postInstall
    '';

    passthru =
      let
        serve = mkServe {
          inherit port;
          name = "serve-${finalAttrs.name}";
          root = finalAttrs.finalPackage;
        };

        serveApp = {
          type = "app";
          program = lib.getExe serve;
          meta.description = "Serve ${finalAttrs.name}";
        };

        deploySite = writeShellApplication {
          name = "deploy-${finalAttrs.name}";
          runtimeInputs = [ deploy ];
          text = ''
            exec deploy "$@" "${finalAttrs.finalPackage}" "${deployBranch}"
          '';
        };

        deploySiteApp = {
          type = "app";
          program = lib.getExe deploySite;
          meta.description = "Deploy ${finalAttrs.name}";
        };
      in
      {
        inherit
          buildHtmlScript buildCssScript
          elmApp
          serve serveApp;

        deploy = deploySite;
        deployApp = deploySiteApp;
      };
  })
)
