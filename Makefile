# CONFIGURATION

.DEFAULT_GOAL := serve-dev
.DELETE_ON_ERROR:


# CONSTANTS

SOURCES := src


# COMMANDS

.PHONY: dev prod serve-dev serve-prod deploy format check clean


dev: elm.lock
	nix build .#dev

prod: elm.lock
	nix build .#prod

serve-dev: elm.lock
	nix run .#dev

serve-prod: elm.lock
	nix run .#prod

deploy: elm.lock
	nix run .#deploy

format:
	elm-format $(SOURCES) --yes

lint:
	elm-format $(SOURCES) --validate
	actionlint

flake-check:
	nix flake check -L

clean:
	rm -rf elm-stuff result


# FILES

elm.lock: elm.json
	elm2nix lock elm.json
