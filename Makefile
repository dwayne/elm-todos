.PHONY: build preview deploy

# Build the site for production into ./result
build: elm.lock
	nix build -L

# Preview the production build locally
preview: elm.lock
	nix run

# Deploy the production build into the site branch
deploy: elm.lock
	nix run .#deploy

# Regenerate elm.lock whenever elm.json changes
elm.lock: elm.json
	elm2nix lock
