# Elm Todos - [Live Demo](https://elm-todos.netlify.app/)

![A screenshot of Elm Todos](/screenshot.png)

An [Elm](https://elm-lang.org/) implementation of the [TodoMVC](https://todomvc.com/)'s to-do list web application.

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

To deploy the production version of the application to [Netlify](https://www.netlify.com/):

```bash
nix run .#deployProd
```

To simulate the deployment you can do the following:

```bash
nix run .#deployProd -- -s
```

## CI

There is a GitHub Action, [`check.yml`](./.github/workflows/check.yml), that runs `nix flake check -L` on every change you push. It uses the [Magic Nix Cache](https://determinate.systems/blog/magic-nix-cache/) to speed up the workflow.
