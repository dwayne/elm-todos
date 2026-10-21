{ deploy
, elm2nixLib
, lib
, newScope
}:

lib.makeScope newScope (self: {
  inherit deploy elm2nixLib;
  build = self.callPackage ./build.nix {};
  mkServe = self.callPackage ./mk-serve.nix {};
})
