{
  inputs = {
    elm2nix = {
      url = "git+ssh://git@github.com/dwayne/elm2nix?rev=2216e3efe9145142acb837078257ee74c576c20d";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm2nix }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        e2n = pkgs.callPackage ./elm2nix.nix { elm2nix = elm2nix.packages.${system}.default; };

        elmTodos = e2n.mkElmDerivation {
          name = "elm-todos";
          src = ./.;
          output = "app.js";
          enableOptimizations = true;
          enableMinification = true;
          useTerser = true;
          enableCompression = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "dev";

          shellHook = ''
            export PS1="($name) $PS1"
          '';
        };

        packages = {
          inherit elmTodos;
          default = elmTodos;
        };

        lib = {
          inherit (e2n) preConfigure dotElmLinks symbolicLinksToPackages fetchElmPackage;
        };
      }
    );
}
