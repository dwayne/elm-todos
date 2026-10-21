{ deploy
, elm2nixLib
, lib
, newScope
, nodejs-slim_24
, pnpm_12
}:

lib.makeScope newScope (self: {
  inherit deploy elm2nixLib;

  nodejs = nodejs-slim_24;
  pnpm = pnpm_12;

  build = self.callPackage ./build.nix {};
  mkServe = self.callPackage ./mk-serve.nix {};

  devShell = self.callPackage ./dev-shell.nix {};
})
