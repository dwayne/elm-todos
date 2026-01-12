{ caddy, writeShellScript }:

{ name # The name of the script
, root # The derivation that contains the files to be served

, port ? 8000
, config ? ../Caddyfile
, adapter ? "caddyfile"
}:

writeShellScript "serve-${name}" ''
  port=${builtins.toString(port)} root=${root} ${caddy}/bin/caddy run --config ${config} --adapter ${adapter}
''
