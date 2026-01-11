{
  inputs = {
    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (elm2nix.lib.elm2nix pkgs) buildElmApplication;

        dev = pkgs.callPackage ./nix { inherit buildElmApplication; };

        prod = dev.override {
          enableCompression = true;
          htmlOptions = { enableOptimizations = true; };
          cssOptions = { enableOptimizations = true; };
          elmOptions = {
            doElmFormat = true;
            enableOptimizations = true;
            optimizeLevel = 2;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-todos";

          packages = [
            elm2nix.packages.${system}.default
          ];

          shellHook = ''
            export PS1="($name)\n$PS1"
          '';
        };

        packages = {
          inherit dev prod;
          default = dev;
        };
      }
    );
}
