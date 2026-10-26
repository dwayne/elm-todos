elm_dirs := "src"

[private]
default:
  @just --list --unsorted

# Start the development server
dev:
  pnpm dev

# Format the Elm code in place
format:
  elm-format {{elm_dirs}} --yes

# Check formatting
lint:
  elm-format {{elm_dirs}} --validate

# Run all the code checks (CI runs this too)
verify: lint

# Build the site for production (see Makefile)
build:
  make build

# Remove build output, caches, and node_modules
clean:
  rm -rf .parcel-cache dist elm-stuff node_modules result

alias d := dev
alias f := format
alias l := lint
alias v := verify
alias b := build
alias c := clean
