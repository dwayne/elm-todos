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

      e2n = pkgs.callPackage ./elm2nix.nix {};

      elmTodos = e2n.mkElmDerivation {
        name = "elm-todos";
        src = ./.;
        elmLock = ./elm.lock;
        registryDat = ./registry.dat;
        output = "app.js";
        enableOptimizations = true;
        enableMinification = true;
        enableCompression = true;
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

      lib = {
        inherit (e2n) preConfigure dotElmLinks symbolicLinksToPackages fetchElmPackage;
      };
    };
}
