{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-elm2nix = {
      url = "github:dwayne/elm2nix/use-elm-0.19.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-deploy = {
      url = "github:dwayne/deploy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-elm2nix, flake-deploy }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      eachSupportedSystem = f: lib.foldAttrs lib.mergeAttrs {} (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) supportedSystems);
    in
    eachSupportedSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ flake-elm2nix.overlays.default ];
        };

        elm2nixLib = flake-elm2nix.lib.mkLib pkgs;
        deploy = flake-deploy.lib.mkDeploy pkgs;

        inherit (elm2nixLib) elm2nix;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-todos";

          packages = [
            deploy
            elm2nix
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
          ];
        };

        packages = {
        };

        apps = {
        };

        checks = {
        };
      }
    );
}
