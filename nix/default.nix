{ elm2nixLib
, lib
, newScope
}:

lib.makeScope newScope (self: {
  inherit elm2nixLib;
  build = self.callPackage ./build.nix {};
})
