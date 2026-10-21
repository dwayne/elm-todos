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

        project = pkgs.callPackage ./nix {
          inherit elm2nixLib deploy;
        };

        site = project.build {
          name = "elm-todos";
          root = ./.;
          hash = "sha256-cXsDLkKnVZbkq7to5ePX0VgCAlmxNlAUfYf6lkg8+mE=";
          deployBranch = "netlify";
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-todos";
          inputsFrom = [ project.devShell ];
        };

        packages = {
          inherit site;
          default = site;
        };

        apps = {
          default = site.serveApp;
          serve = site.serveApp;
          deploy = site.deployApp;
        };

        checks = { inherit site; };
      }
    );
}
