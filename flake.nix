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

        elmTodosHtml = pkgs.callPackage ./nix/build-html.nix {};
        elmTodosCss = pkgs.callPackage ./nix/build-css.nix {};
        elmTodosJs = buildElmApplication {
          name = "elm-todos";
          src = ./.;
          elmLock = ./elm.lock;
          output = "app.js";
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
          inherit elmTodosHtml elmTodosCss elmTodosJs;
          default = elmTodosJs;
        };
      }
    );
}
