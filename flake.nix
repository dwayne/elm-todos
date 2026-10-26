{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-utils-src = { url = "github:dwayne/nix-utils"; flake = false; };
    flake-nix-elm-parcel = {
      url = "github:dwayne/nix-elm-parcel";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-utils-src.follows = "nix-utils-src";
      };
    };
  };

  outputs = { self, nixpkgs, nix-utils-src, flake-nix-elm-parcel }:
    let
      name = "example";
      hash = "sha256-c1evKKWUS+PTMgSowmBm6lNaVOKOYNLpkZuLQu5Ol7w=";

      lib = nixpkgs.lib;
      nixUtils = import nix-utils-src lib;
    in
    nixUtils.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ flake-nix-elm-parcel.overlays.default ];
        };

        site = pkgs.nixElmParcelPackages.build {
          inherit name hash;
          root = ./.;
          deployBranch = "netlify";
        };
      in
      {
        devShells.default = pkgs.mkShell {
          inherit name;
          inputsFrom = [ pkgs.nixElmParcelPackages.devShell ];
        };

        packages = {
          inherit site;
          default = site;
        };

        apps = {
          inherit (site) serve deploy;
          default = site.serve;
        };

        checks = { inherit site; };
      }
    );
}
