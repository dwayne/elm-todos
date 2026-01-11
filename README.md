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

## Deploy

To deploy the production version of the application to [Netlify](https://www.netlify.com/):

```bash
nix run .#deployProd
```

To simulate the deployment you can do the following:

```bash
nix run .#deployProd -- -s
```
