{ caddy, writeShellScript }:

{ name   # The name of the script
, root   # The path to the directory containing the files to be served
, config # The configuration file

, port ? 8000
, adapter ? "caddyfile"
}:

writeShellScript "serve-${name}" ''
  port=${builtins.toString(port)} root=${root} ${caddy}/bin/caddy run --config ${config} --adapter ${adapter}
''
