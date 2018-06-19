# Step 1

## Goal

To display "Hello, Elm!" in a browser.

## Plan

1. Set up a project directory.
2. Write a `Todo.elm`.
3. Compile `Todo.elm`.
4. Write an `index.html`.
5. Open `index.html` in a browser.

## Set up a project directory

Create a directory named `elm-todos`, change into it and then create a file called `Todo.elm`.

```sh
$ mkdir elm-todos
$ cd elm-todos
$ touch Todo.elm
```

## Write a `Todo.elm`

Open `Todo.elm` in a text editor (I'm using [Atom](https://atom.io/)) and write the following:

```elm
module Todo exposing (main)

import Html

main = Html.text "Hello, Elm!"
```

The module is named `Todo` and we expose one function called `main`. The function must be called `main` since the entry module to any Elm application must have a `main` function.

It is possible to omit the `module Todo exposing (main)` line. If it is omitted then Elm gives the module the name `Main` and all functions (currently only `main`) defined in the file would be exported.

I chose to use `...exposing (main)` rather than `...exposing (..)` in order to explicitly express my intention that `main` is the only function that I want to export from the module. As we develop the application we're going to be adding many more functions to `Todo.elm`. I don't want these functions exported because they would only need to be used directly or indirectly by `main`.

## Compile `Todo.elm`

Use `elm-make` to compile `Todo.elm` to `todo.js`.

```sh
$ elm-make Todo.elm --output todo.js
```

You would be prompted to install a few packages. Press ENTER to approve the plan and continue.

`elm-make` would download the packages, configure them and compile `Todo.elm`. If there are no errors then it would generate the output file `todo.js` in the current directory.

As part of the process, it would also create a directory named `elm-stuff` and a file named `elm-package.json` in the current directory.

`elm-stuff` holds build artifacts, i.e. the packages we installed and their exact dependencies.

`elm-package.json` is used by Elm to track metadata about our project. It is similar to [npm](https://www.npmjs.com/)'s [package.json](https://docs.npmjs.com/files/package.json) file.

## Write an `index.html`

To make use of `todo.js` we create an `index.html` file with the following contents:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <title>Elm Todos</title>
  </head>
  <body>
    <script src="todo.js"></script>
    <script>
      Elm.Todo.fullscreen();
    </script>
  </body>
</html>
```

`todo.js` exposes a global object called `Elm`. `Elm` has an attribute on it named after the entry module of our application. In our case the name would be `Todo`. If we leave off the `module Todo exposing (main)` line in `Todo.elm` then the name would be `Main`.

`Elm.Todo` is an object with two methods on it. One called `embed` and another called `fullscreen`.

We use `embed` when we want to have part of our page controlled by our Elm application. Learn more about that [here](https://pragmaticstudio.com/courses/integrating-elm).

We use `fullscreen` when we want our Elm application to control the entire page.

In our case, we want to control the entire page so we call `Elm.Todo.fullscreen()`. The application would be rendered inside the [HTML body](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body).

## Open `index.html` in a browser

Open `index.html` in your browser of choice to see "Hello, Elm!". Here's one way to do it via the command-line.

```sh
$ xdg-open index.html
```

Congratulations! You've completed step 1.

## Bonus

Add a `.gitignore`.

```
elm-stuff
todo.js
```

Edit `summary` and `repository` in `elm-package.json`.

```json
{
    "version": "1.0.0",
    "summary": "A to-do list app",
    "repository": "https://github.com/dwayne/elm-todos.git",
    "...": "..."
}
```

You may also want to add a `README` explaining the project.

Finally, commit your work.

```sh
$ git init
$ git add .
$ git commit -m "Initial commit"
```
