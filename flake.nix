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

            doMinification = true;
            useTerser = true;
            outputMin = "app.js";
          };
        };

        appDev = pkgs.writeShellScript "app-dev" ''
          port=8000 root=${dev} ${pkgs.caddy}/bin/caddy run --config ${./Caddyfile} --adapter caddyfile
        '';

        appProd = pkgs.writeShellScript "app-dev" ''
          port=8000 root=${prod} ${pkgs.caddy}/bin/caddy run --config ${./Caddyfile} --adapter caddyfile
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-todos";

          packages = [
            elm2nix.packages.${system}.default
            pkgs.caddy # Added so that I could format the Caddyfile, i.e. caddy fmt --overwrite Caddyfile
          ];

          shellHook = ''
            export PS1="($name)\n$PS1"
          '';
        };

        packages = {
          inherit dev prod;
          default = dev;
        };

        apps = {
          default = self.apps.${system}.appDev;

          appDev = {
            type = "app";
            program = "${appDev}";
          };

          appProd = {
            type = "app";
            program = "${appProd}";
          };
        };
      }
    );
}
