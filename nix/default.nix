{ lib
, newScope

, buildElmApplication
, deploy
}:

lib.makeScope newScope (self: {
  inherit buildElmApplication deploy;

  buildElmSpa = self.callPackage ./build-elm-spa.nix {};
  htmlnano = self.callPackage ./htmlnano.nix {};
  mkServe = self.callPackage ./mk-serve.nix {};
})
