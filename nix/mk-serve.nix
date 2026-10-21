{ caddy, writeShellApplication }:

{ name # The name of the script
, root # The derivation that contains the files to be served

, port ? 8000
, config ? ./Caddyfile
, adapter ? "caddyfile"
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [ caddy ];
  runtimeEnv = {
    inherit root port;
  };
  text = ''
    exec caddy run --config "${config}" --adapter "${adapter}"
  '';
}
