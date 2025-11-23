{
  inputs = {
    elm2nix = {
      url = "git+ssh://git@github.com/dwayne/elm2nix?rev=2216e3efe9145142acb837078257ee74c576c20d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, elm2nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      elmLock = lib.importJSON ./elm2nix/elm.lock;
      registryDat = ./elm2nix/registry.dat;

      fetchElmPackage = pkgs.callPackage ./nix/fetchElmPackage.nix {};

      helpers = pkgs.callPackage ./nix/helpers.nix { inherit fetchElmPackage; };
      h = helpers { inherit elmLock registryDat; };

      elmTodos = h.mkElmDerivation {
        name = "elm-todos";
        src = ./.;
        buildPhase = ''
          elm make src/Main.elm --output "$out/app.js"
        '';
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "dev";

        packages = [
          elm2nix.packages.${system}.default
        ];

        shellHook = ''
          export PS1="($name) $PS1"
        '';
      };

      packages.${system} = {
        inherit elmTodos;
        default = elmTodos;
      };

      inherit elmLock registryDat;

      lib = {
        inherit fetchElmPackage;
        inherit (h) preConfigure dotElmLinks symbolicLinksToPackages;
      };
    };
}
