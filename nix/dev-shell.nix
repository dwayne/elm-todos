{ deploy
, elm2nixLib
, elmPackages
, mkShell
, nodejs
, pnpm
}:

mkShell {
  name = "shell";

  packages = [
    deploy
    elm2nixLib.elm2nix
    elmPackages.elm
    elmPackages.elm-format
    nodejs
    pnpm
  ];

  shellHook = ''
    export PROJECT_ROOT="$PWD"
    export PATH="$PROJECT_ROOT/node_modules/.bin:$PATH"
    export PORT=8000

    if [ ! -d "$PROJECT_ROOT/node_modules" ]; then
      pnpm install --loglevel warn
    fi
  '';
}
