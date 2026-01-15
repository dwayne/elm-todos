{
  inputs = {
    deploy = {
      url = "github:dwayne/deploy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, deploy, elm2nix }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (elm2nix.lib.elm2nix pkgs) buildElmApplication;

        build = pkgs.callPackage ./nix/build.nix { inherit buildElmApplication; };

        dev = build {};

        prod = build {
          enableCompression = true;
          includeRedirects = true;
          htmlOptions = { minify = true; };
          cssOptions = { minify = true; };
          elmOptions = {
            doElmFormat = true;

            enableOptimizations = true;
            optimizeLevel = 2;

            doMinification = true;
            useTerser = true;
            outputMin = "app.js";
          };
        };

        serve = pkgs.callPackage ./nix/serve.nix {};

        appDev = serve {
          name = "app-dev";
          root = dev;
        };

        appProd = serve {
          name = "app-prod";
          root = prod;
        };

        #
        # You will need to create a branch named "netlify" in your repository.
        #
        # Read https://dev.to/dwayne/how-i-host-elm-web-applications-with-github-pages-57a0#deploy-from-a-separate-branch
        # for more details on how to go about it.
        #
        deployProd = pkgs.writeShellScript "deploy-prod" ''
          ${deploy.packages.${system}.default}/bin/deploy "$@" ${prod} netlify
        '';

        mkApp = drv: {
          type = "app";
          program = "${drv}";
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "app";

          packages = [
            deploy.packages.${system}.default
            elm2nix.packages.${system}.default
            pkgs.actionlint
            pkgs.caddy
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-json
          ];

          shellHook = ''
            export PROJECT_ROOT="$PWD"
            export PS1="($name)\n$PS1"

            format () {
              elm-format "$PROJECT_ROOT/src" --yes
            }
            export -f format
            alias f='format'
          '';
        };

        packages = {
          inherit dev prod;
          default = dev;
        };

        apps = {
          default = self.apps.${system}.dev;

          dev = mkApp appDev;
          prod = mkApp appProd;

          deployProd = mkApp deployProd;
        };

        checks = {
          inherit dev prod;
        };
      }
    )) // {
      templates = {
        default = {
          description = "A basic template for getting started on an Elm web application.";
          path = ./.;
        };
      };
    };
}
