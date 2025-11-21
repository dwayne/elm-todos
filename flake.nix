{
  inputs = {
    elm2nix = {
      url = "git+ssh://git@github.com/dwayne/elm2nix?rev=4fa3a3c882eebbe649c6edfbde7b11ba017a6cc1";
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

      inherit elmLock registryDat;
    };
}
