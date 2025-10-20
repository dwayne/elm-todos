{ fetchzip, lib }:
{ name, version, hash }:
fetchzip {
  name = lib.replaceStrings [ "/" ] [ "-" ] name + "-${version}";
  url = "https://github.com/${name}/archive/${version}.tar.gz";
  meta.homepage = "https://github.com/${name}";
  inherit hash;
}
