{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      #
      # 2. I want to be able to name the JavaScript file that's output.
      #

      #
      # 3. What if I want to use a different Elm compiler?
      #
      # For example: elm-optimize-level-2
      #

      #
      # 4. What if I want to use a different minifier?
      #
      # For example: terser
      #

      #
      # 5. It would be nice to explore how I can expose a NixOS configuration to host my Elm web application.
      #

      elm-todos = pkgs.callPackage ./elm2nix { settings.name = "elm-todos"; };

      fetchElmPackage = pkgs.callPackage ./elm2nix/fetchElmPackage.nix {};

      bashScript = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import ./elm2nix/elm-srcs.nix;
        elmVersion = "0.19.1";
        registryDat = ./elm2nix/registry.dat;
      };
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
      };

      inherit bashScript;
    };
}
