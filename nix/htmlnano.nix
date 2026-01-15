{ buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  name = "htmlnano";
  src = fetchFromGitHub {
    owner = "dwayne";
    repo = "htmlnano";
    rev = "3ec6263756a077d1268e323acac878c43456d8a5";
    hash = "sha256-amhVZQaJq1gTDvnQvyhRVqnr/5gEjyzsrJyfB3gwtKQ=";
  };

  npmDepsHash = "sha256-imFb9NZuv5/ZkJ/IJpceLLQJTMF8nQOetQp/utG/h2A=";
}
