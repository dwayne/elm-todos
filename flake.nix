{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      #
      # 5. It would be nice to explore how I can expose a NixOS configuration to host my Elm web application.
      #

      elm-todos = pkgs.callPackage ./elm2nix { settings.name = "elm-todos"; };

      fetchElmPackage = pkgs.callPackage ./elm2nix/fetchElmPackage.nix {};

      registryDat = ./elm2nix/registry.dat;

      bashScript = pkgs.elmPackages.fetchElmDeps {
        inherit registryDat;
        elmPackages = import ./elm2nix/elm-srcs.nix;
        elmVersion = "0.19.1";
      };

      elmPackages = import ./elm2nix/elm-lock.nix;
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
          elmPackages;

      dotElm = pkgs.callPackage ./elm2nix/dotElm.nix { inherit elmDependencies registryDat; };

      build = pkgs.callPackage ./elm2nix/build.nix {};
    in
    {
      packages.${system} = {
        default = elm-todos;

        elm-json = fetchElmPackage {
          name = "elm/json";
          version = "1.1.3";
          hash = "sha256-n0UqN8c5XPBw2Sd+pMPjXCGL6Nd5GZjnXWIHjr1BqcM=";
        };

        elm-virtual-dom = fetchElmPackage {
          name = "elm/virtual-dom";
          version = "1.0.3";
          hash = "sha256-yfQ16zr7ji63nurnvUpn1iAcM69R/R7JfRsDejT3Xq4=";
        };

        inherit dotElm;

        build = build {
          name = "elm-todos";
          src = ./.;
          inherit dotElm;
          minify = true;
          compress = true;
        };
      };

      inherit bashScript elmDependencies;
    };
}
