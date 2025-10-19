{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      #
      # 1. It would be nice to be able to just pass pkgs into elm2nix/default.nix.
      #
      # Remember, elm2nix/default.nix is just a generated starting point. You can change that file in whatever ways you wish.
      #

      #
      # 2. I want to be able to name the JavaScript file that's output.
      #

      #
      # 3. What if I want to use a different Elm compiler?
      #
      # For example: elm-optimize-level-2
      #

      #
      # 4. What if I want to use a different minifier?
      #
      # For example: terser
      #

      #
      # 5. It would be nice to explore how I can expose a NixOS configuration to host my Elm web application.
      #

      elm-todos = import ./elm2nix {
        inherit nixpkgs;
        config = { inherit system; };
      };
    in
    {
      packages.${system}.default = elm-todos;
    };
}
