# Elm Todos - [Live Demo](https://elm-todos.netlify.app/)

![A screenshot of Elm Todos](/screenshot.png)

An [Elm](https://elm-lang.org/) implementation of the [TodoMVC](https://todomvc.com/)'s to-do list web application.

## Usage

### Develop

An isolated, reproducible development environment is provided with [Nix](https://nixos.org/). Enter using:

```bash
nix develop
```

### Build

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

### Serve

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

### Check

To run various checks to ensure that the flake is valid and that the development and production versions of the application can be built.

```bash
nix flake check -L
```

### Deploy

To deploy the production version of the application to [Netlify](https://www.netlify.com/):

```bash
nix run .#deploy
```

To simulate the deployment you can do the following:

```bash
nix run .#deploy -- -s
```

### CI

- [`check.yml`](./.github/workflows/check.yml) runs checks on every change you push
- [`deploy.yml`](./.github/workflows/deploy.yml) deploys the production version of the application on every push to the master branch that successfully passes all checks

**N.B.** *The [Magic Nix Cache](https://determinate.systems/blog/magic-nix-cache/) is used for caching the Nix store.*
