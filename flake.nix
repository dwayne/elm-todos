{
  inputs = {
    elm2nix = {
      url = "git+ssh://git@github.com/dwayne/elm2nix?ref=prepare-for-first-release";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm2nix }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (elm2nix.lib.elm2nix pkgs) buildElmApplication;

        elmTodos = buildElmApplication {
          name = "elm-todos";
          src = ./.;
          elmLock = ./elm.lock;
          registryDat = ./registry.dat;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "dev";

          packages = [
            elm2nix.packages.${system}.default
          ];

          shellHook = ''
            export PS1="($name) $PS1"
          '';
        };

        packages = rec {
          inherit elmTodos;

          default = elmTodos;

          debugElmTodos = elmTodos.override {
            enableDebugger = true;
            output = "debug-elm.js";
          };

          checkedElmTodos = elmTodos.override {
            doElmFormat = true;
            doElmTest = true;
            output = "checked-elm.js";
          };

          optimizedElmTodos = checkedElmTodos.override {
            output = "optimized-elm.js";
            enableOptimizations = true;
            optimizeLevel = 2;
            doMinification = true;
            doCompression = true;
            doReporting = true;
          };

          hashedElmTodos = optimizedElmTodos.override {
            output = "hashed-elm.js";
            doContentHashing = true;
          };
        };
      }
    );
}
