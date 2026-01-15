# App - [Live Demo](https://app-xyz123.netlify.app/)

An example Elm web application that is built using [`dwayne/elm2nix`](https://github.com/dwayne/elm2nix). It acts as a [template](https://zero-to-nix.com/concepts/flakes/#templates) for creating similar types of Elm web applications.

## Getting Started

```bash
mkdir app
cd app
nix flake init --template github:dwayne/elm-todos/flake-template
```

## Develop

An isolated, reproducible development environment is provided with [Nix](https://nixos.org/).

You can enter its development environment as follows:

```bash
nix develop
```

## Build

To build the development version of the application:

```bash
nix build
# or
nix build .#dev
```

To build the production version of the application:

```bash
nix build .#prod
```

## Serve

To serve the development version of the application:

```bash
nix run
# or
nix run .#dev
```

To serve the production version of the application:

```bash
nix run .#prod
```

## Check

Run various checks to ensure that the flake is valid and that the development and production versions of the application can be built.

```bash
nix flake check
```

There is also a GitHub Action workflow, [check.yml](.github/workflows/check.yml), that does the same thing on every push.

## Deploy

The production version of the application can be deployed to [Netlify](https://www.netlify.com/).

### First time

To set it up the first time you need to create an orphan branch called `netlify` and tell Netlify you want to deploy from that branch.

Read [Deploy from a separate branch](https://dev.to/dwayne/how-i-host-elm-web-applications-with-github-pages-57a0#deploy-from-a-separate-branch) to learn how to set up the orphan branch.

### Subsequent times

Make your changes and when you're ready to deploy you can do the following:

```bash
nix run .#deployProd
```

To simulate a deployment you can do the following:

```bash
nix run .#deployProd -- -s
```

## CI

There is a GitHub Action, [`check.yml`](./.github/workflows/check.yml), that runs `nix flake check -L` on every change you push. It uses the [Magic Nix Cache](https://determinate.systems/blog/magic-nix-cache/) to speed up the workflow.
