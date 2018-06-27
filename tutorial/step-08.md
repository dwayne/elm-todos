# Step 8

## Goal

To be able to keep the visibility filter in sync with the URL in the address bar.

## Plan

1. Explain the problem.
2. Install `elm-lang/navigation`.
3. Switch from `Html.beginnerProgram` to `Navigation.program`.
4. Set the visibility filter based on the URL in the address bar.

**Note:**

> Prior to this step we've been accessing the application by opening our `index.html` file directly in a browser. That's why you see `file:///...` in the browser's address bar. However, going forward this would not be a viable way to test our application. Instead we'd want to serve our `index.html` using a local web server. One possibility (if you have Python installed) is to use Python's [SimpleHTTPServer](https://docs.python.org/2/library/simplehttpserver.html) module to serve the page.
>
> ```elm
> $ cd path/to/elm-todos
> $ python -m SimpleHTTPServer 8000
> ```
>
> Then, open your browser and navigate to `localhost:8000` to view the application.

## Explain the problem

Open the application in a browser (as discussed in the note above), add a few entries and mark some of them as completed.

Click the visibility filter link labeled "Active" and notice the following:

1. The URL in the address bar updates such that "#/active" is appended.
2. Only the active/incomplete entries are shown.
3. The "Active" link is no longer a link so as to indicate that it's the currently selected one.

**N.B.** *The "/active" after the hash is called a [fragment identifier](https://en.wikipedia.org/wiki/Fragment_identifier).*

Now, click the visibility filter link labeled "Completed" and notice the following:

1. The URL in the address bar updates but this time "#/completed" is appended.
2. Only the completed entries are shown.
3. The "Completed" link is no longer a link so as to indicate that it's the currently selected one.

Both of the situations above do the things we want.

However, if you go to the browser's address bar and change it by renaming "#/completed" to "#/active" and then press ENTER you'd notice that the entire page refreshes and you lose all your entries. This happens because when the address bar changes the browser sends HTTP requests to load a new page. We don't want this default behaviour. Instead, we want our application to know when the URL in the address bar changes and to update itself accordingly.

Elm allows us to do this via the [elm-lang/navigation](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0) package. The library lets you capture navigation events so that you can handle it yourself.

We'd use the package to do the following:

1. When the URL has "#/active" appended we'd set the visibility filter to `Active`.

2. When the URL has "#/completed" appended we'd set the visibility filter to `Completed`.

3. And, for any other fragment identifier we'd set the visibility filter to `All`.

Once we do this our application would work in the way we want.

**N.B.** *Make sure you understand what we're trying to accomplish before moving ahead.*

Let's begin.

## Install `elm-lang/navigation`

```sh
$ elm-package install elm-lang/navigation
```

Press ENTER at the prompt. Doing so would install the package and add it as a  dependency to your `elm-package.json` file.

You'd now have access to the [Navigation](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0/Navigation) module.

## Switch from `Html.beginnerProgram` to `Navigation.program`

Make the following changes:

```elm
import Navigation

.
.

-- 1. Switch from Html.beginnerProgram.
main =
  Navigation.program NewLocation
    { init = init
    , update = (\msg model -> update msg model ! [])
    , view = view
    , subscriptions = always Sub.none
    }

-- 2. Remove model.
--
-- model : Model
-- model =
--   { uid = 0
--   , description = ""
--   , visible = All
--   , entries = []
--   }

-- 3. Add an init function.
init : Navigation.Location -> (Model, Cmd Msg)
init location =
  Debug.log (toString location) <|
    { uid = 0
    , description = ""
    -- TODO: Set visible based on location.
    , visible = All
    , entries = []
    } ! []

-- 4. Add the NewLocation data constructor to our message type.
type Msg
  = NewLocation Navigation.Location
  | -- ...

-- 5. Handle NewLocation in our update function.
update msg model =
  case msg of
    NewLocation location ->
      -- TODO: Set visible based on location.
      Debug.log (toString location) model

    -- ...
```

[Navigation.program](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0/Navigation#program) is similar to [Html.program](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program) (which is similar to [Html.beginnerProgram](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#beginnerProgram)) but our `update` function also gets messages (`NewLocation` in our case) whenever the URL in the browser's address bar changes.

`init` is a new function we have to write. It takes [Navigation.Location](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0/Navigation#Location) as an argument so that we can use the URL right from the first time our application loads.

The `update` function that `Navigation.program` takes is expected to have the return type `(Model, Cmd Msg)` but our update function currently has the return type `Model`. To fix that we use an anonymous function `(\msg model -> update msg model ! [])` and make it return the correct type.

**N.B.** *`update msg model ! []` is equivalent to `(update msg model, Cmd.none)`, see the function [(!)](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#!)*.

Finally, since we're not using [subscriptions](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub) we pass along `always Sub.none` to the `subscriptions` field.

**N.B.** *Learn about `always` [here](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Basics#always).*

Compile and try it out in your browser.

Use the `Debug.log` statements to understand what happens the first time your application loads and when you change the URL.

## Set the visibility filter based on the URL in the address bar

Make the following changes:

```elm
init location =
  { uid = 0
  , description = ""
  -- 1. Set visible based on the URL when the application first loads.
  , visible = toVisibility location
  , entries = []
  } ! []

-- 2. Remove the SetVisible message.
type Msg
   = NewLocation Navigation.Location
   | SetDescription String
   -- | SetVisible Visibility
   | AddEntry
   | -- ...

update msg model =
  case msg of
    NewLocation location ->
      -- 3. Set visible whenever the URL changes.
      { model | visible = toVisibility location }

    -- ...

    -- 4. Remove the SetVisible case.
    -- SetVisible visible ->
    --   { model | visible = visible }

    -- ...

viewVisibilityFilter name url current selected =
  if current == selected then
    span [] [ text name ]
  else
    -- 5. No need to send the SetVisible message anymore since
    -- when the link is clicked it changes the URL and causes the
    -- NewLocation message to be sent to the update function.
    a [ href url ] [ text name ]

toVisibility : Navigation.Location -> Visibility
toVisibility { hash } =
  case String.dropLeft 2 hash of
    "active" ->
      Active

    "completed" ->
      Completed

    _ ->
      All
```

**N.B.** *The domain of `toVisibility` could be restricted further by using either `toVisibility : { a | hash : String } -> Visibility` or `toVisibility : String -> Visibility` for its type signature. In the first way we'd be making use of Elm's support for [extensible records](http://elm-lang.org/docs/records#record-types) and we'd be able to call `toVisibility` in the same way since a value of type `Location` always has a `hash` field. In the second way we'd have to call the function like `toVisibility location.hash`.*

Compile and try it out in your browser.

Add a few entries, mark some of them as completed and click the visibility filter links to see that they still work.

Then, go to the address bar, change the URL to "#/active" or "#/completed" and notice that it works just the way we wanted.

Congratulations! You've completed step 8.
